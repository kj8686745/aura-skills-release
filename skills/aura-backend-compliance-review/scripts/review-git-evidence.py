"""Read-only Git evidence for a time window or a source line. Python 3.9+."""

import argparse
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess


OBJECT_ID = re.compile(r"(?:[0-9a-f]{40}|[0-9a-f]{64})")


class Repository:
    def __init__(self, path, expected_origin=None):
        self.path = path.resolve(strict=True)
        self.env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
        self.env.update(GIT_ALLOW_PROTOCOL="", GIT_NO_REPLACE_OBJECTS="1", GIT_OPTIONAL_LOCKS="0")
        root = Path(self.read("rev-parse", "--show-toplevel").decode("utf-8").strip()).resolve()
        if root != self.path:
            raise ValueError("请指定审查仓库根目录")
        if expected_origin is not None:
            origin = self.read("config", "--local", "--get", "remote.origin.url")
            if origin.decode("utf-8").rstrip("\r\n") != expected_origin:
                raise ValueError("仓库来源与预期不一致")

    def read(self, *args):
        result = subprocess.run(
            ["git", "-C", str(self.path), "--literal-pathspecs", *args],
            capture_output=True, env=self.env,
        )
        if result.returncode:
            # Git stderr may contain private URLs, paths or credentials.
            raise ValueError(f"Git {args[0]} 失败，退出码 {result.returncode}")
        return result.stdout

    def commit(self, ref):
        if not (OBJECT_ID.fullmatch(ref) or ref.startswith("refs/")):
            raise ValueError("目标必须使用完整 Git ref 或完整提交 SHA")
        if ref.startswith("refs/"):
            self.read("show-ref", "--verify", "--", ref)
        return self.read("rev-parse", "--verify", "--end-of-options", f"{ref}^{{commit}}").decode().strip()


def window_time(value):
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        raise ValueError("时间窗口必须带时区")
    return parsed.timestamp()


def collect_window(repo, refs, start, end, date_field, author_emails):
    lower, upper = window_time(start), window_time(end)
    if lower >= upper:
        raise ValueError("窗口开始必须早于结束")
    if repo.read("rev-parse", "--is-shallow-repository").strip() != b"false":
        raise ValueError("浅克隆无法证明给定目标的历史完整")
    targets = {ref: repo.commit(ref) for ref in refs}
    # Traverse the selected histories before filtering, including merges and old branch tips.
    log = repo.read("log", "--no-color", "--no-show-signature", "--no-notes", "--no-decorate",
                    "--format=%H%x09%at%x09%ct%x09%ae",
                    *sorted(set(targets.values())), "--")
    authors = {email.casefold() for email in author_emails}
    commits = []
    for row in log.decode().splitlines():
        sha, author, committer, email = row.split("\t", 3)
        author, committer = int(author), int(committer)
        selected = author if date_field == "author" else committer
        if lower <= selected < upper and (not authors or email.casefold() in authors):
            commits.append({"commit": sha, "authorTimestamp": author, "committerTimestamp": committer})
    return {"repository": str(repo.path), "start": start, "endExclusive": end, "dateField": date_field,
            "refs": targets, "authorFilterCount": len(authors), "count": len(commits), "commits": commits}


def repo_path(value):
    path = PurePosixPath(value)
    if path.is_absolute() or value != path.as_posix() or any(
        part in (".", "..", ".git") for part in path.parts
    ) or not path.parts or any(char in value for char in ("\\", ":", "\0")):
        raise ValueError("源码路径必须是仓库内的正斜杠相对路径")
    return path


def digest(data):
    return hashlib.sha256(data).hexdigest()


def check_anchor(repo, args):
    if not OBJECT_ID.fullmatch(args.commit):
        raise ValueError("源码锚点必须绑定完整提交 SHA")
    commit = repo.commit(args.commit)
    relative = repo_path(args.path)
    entry = repo.read("ls-tree", "-z", commit, "--", relative.as_posix())
    if not entry.startswith((b"100644 blob ", b"100755 blob ")):
        raise ValueError("提交中没有该普通文件")
    content = repo.read("cat-file", "blob", f"{commit}:{relative.as_posix()}")
    normalized = content.replace(b"\r\n", b"\n")
    if b"\0" in content:
        raise ValueError("二进制文件不支持行锚点")
    count = normalized.count(b"\n") + int(bool(normalized) and not normalized.endswith(b"\n"))
    if not 1 <= args.line <= count:
        raise ValueError("行号超出该提交的文件范围")
    result = {"repository": str(repo.path), "commit": commit, "path": relative.as_posix(),
              "line": args.line, "lineCount": count, "gitSha256": digest(content)}
    if args.snapshot_root:
        root = args.snapshot_root.resolve(strict=True)
        snapshot = root.joinpath(*relative.parts).resolve(strict=True)
        if not snapshot.is_relative_to(root) or not snapshot.is_file():
            raise ValueError("快照文件超出快照目录或不是普通文件")
        actual = snapshot.read_bytes()
        result["snapshotSha256"] = digest(actual)
        if actual == content:
            result["snapshotMatch"] = "exact"
        elif actual.replace(b"\r\n", b"\n") == normalized:
            result["snapshotMatch"] = "crlf-lf-only"
        else:
            raise ValueError("快照内容与绑定提交不同")
    if args.attribute:
        if repo.read("rev-parse", "--is-shallow-repository").strip() != b"false":
            raise ValueError("浅克隆无法核对完整行归属")
        blame = repo.read("blame", "--line-porcelain", f"-L{args.line},{args.line}",
                          commit, "--", relative.as_posix())
        header = blame.splitlines()[0].decode().split()
        if len(header) < 3 or not OBJECT_ID.fullmatch(header[0]) or int(header[2]) != args.line:
            raise ValueError("Git blame 未返回可核对的行归属")
        author = re.search(rb"(?m)^author ([^\r\n]*)", blame)
        result["lineAttribution"] = {
            "commit": header[0], "originalLine": int(header[1]),
            "author": author[1].decode("utf-8", errors="replace") if author else None,
            "basis": "git blame; compare parent diffs before claiming root-cause introduction",
        }
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--expected-origin", help="可选，核对本地 origin 精确值，结果不输出 URL")
    commands = parser.add_subparsers(dest="command", required=True)
    scope = commands.add_parser("window", help="按显式本地 refs/SHA 核对提交时间窗口")
    scope.add_argument("--ref", action="append", required=True)
    scope.add_argument("--start", required=True)
    scope.add_argument("--end", required=True)
    scope.add_argument("--date-field", choices=["author", "committer"], required=True)
    scope.add_argument("--author-email", action="append", default=[],
                       help="可重复指定已确认的作者邮箱或别名，结果不回显邮箱")
    anchor = commands.add_parser("anchor", help="核对固定提交的文件、行号和可选快照/行归属")
    anchor.add_argument("--commit", required=True)
    anchor.add_argument("--path", required=True)
    anchor.add_argument("--line", type=int, required=True)
    anchor.add_argument("--snapshot-root", type=Path)
    anchor.add_argument("--attribute", action="store_true")
    args = parser.parse_args()
    try:
        repo = Repository(args.repo, args.expected_origin)
        if args.command == "window":
            result = collect_window(repo, args.ref, args.start, args.end, args.date_field, args.author_email)
        else:
            result = check_anchor(repo, args)
        print(json.dumps({"status": "checked", **result}, ensure_ascii=False))
        return 0
    except (ValueError, OSError, IndexError) as exc:
        print(json.dumps({"status": "failed", "reason": str(exc)}, ensure_ascii=False))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
