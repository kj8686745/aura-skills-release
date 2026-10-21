#!/usr/bin/env python3
"""Collect bounded project context without copying source, secrets, or chat history."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlsplit


def inspect(project, entry="AGENTS.md", state=None, baseline=None):
    root = Path(project).resolve()
    issues, files = [], []

    def issue(level, code, path, message):
        issues.append(dict(level=level, code=code, path=str(path), message=message))

    def selected(relative):
        target = (root / relative).resolve()
        if not target.is_relative_to(root):
            raise ValueError("指定文件超出项目范围")
        return target

    def git(*args):
        proc = subprocess.run(["git", "-C", str(root), *args], capture_output=True, encoding="utf-8", errors="replace", timeout=15)
        return proc.returncode, proc.stdout.rstrip("\r\n")

    git_info = dict(available=False)
    try:
        if not root.is_dir():
            raise ValueError("项目根目录不存在或不是目录")
        for role, relative in [("entry", entry), ("state", state)]:
            if relative is None:
                continue
            target = selected(relative)
            exists = target.is_file()
            item = dict(role=role, path=str(target), exists=exists)
            if exists:
                raw = target.read_bytes()
                item.update(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
                if role == "entry":
                    text = raw.decode("utf-8-sig")
                    fence = False
                    links = []
                    for number, line in enumerate(text.splitlines(), 1):
                        if re.match(r"^\s*(?:`{3,}|~{3,})", line):
                            fence = not fence
                            continue
                        if fence:
                            continue
                        targets = re.findall(r"\]\((<[^>]+>|[^)\s]+)(?:\s+\"[^\"]*\")?\)", line)
                        targets += re.findall(r"`([^`\r\n]+\.md)`", line)
                        for link in dict.fromkeys(targets):
                            link = link.strip("<>")
                            if re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", link) or link.startswith(("//", "#")):
                                continue
                            local = unquote(urlsplit(link).path)
                            dest = (target.parent / local).resolve()
                            links.append(dict(line=number, target=link))
                            if not dest.is_relative_to(root):
                                issue("incomplete", "external_reference", link, "引用超出项目范围，未读取目标")
                            elif not dest.exists():
                                issue("incomplete", "missing_reference", link, f"入口第 {number} 行的本地引用不存在")
                    item["localReferences"] = links
            elif role == "state" or entry != "AGENTS.md":
                issue("incomplete", "missing_selected_file", relative, "指定文件不存在；核实路径或使用现有资料")
            files.append(item)
        try:
            code, top = git("rev-parse", "--show-toplevel")
            if code == 0:
                git_info["available"] = True
                git_info["root"] = top
                _, git_info["head"] = git("rev-parse", "--verify", "HEAD")
                _, git_info["branch"] = git("branch", "--show-current")
                status_code, status = git("status", "--porcelain=v1", "-z", "--", ".")
                if status_code:
                    issue("incomplete", "git_status_failed", root, "Git 状态采集失败")
                else:
                    git_info["statusPaths"] = status.split("\x00") if status else []
                if baseline:
                    code, resolved = git("rev-parse", "--verify", baseline + "^{commit}")
                    git_info["baseline"] = resolved if code == 0 else None
                    if code:
                        issue("incomplete", "unknown_baseline", root, "给定基线无法解析")
                    elif resolved != git_info["head"]:
                        issue("incomplete", "baseline_changed", root, "当前 HEAD 不同于给定基线；核对相关变化，不直接采用旧结论")
        except (FileNotFoundError, subprocess.TimeoutExpired):
            issue("incomplete", "git_unavailable", root, "Git 不可用或超时；可继续文件范围内的核对")
        if baseline and not git_info["available"]:
            issue("incomplete", "baseline_unverified", root, "当前不是可核对的 Git 工作区，给定基线未验证")
    except (OSError, UnicodeError, ValueError) as exc:
        issue("error", "invalid_input", root, str(exc))
    errors = sum(i["level"] == "error" for i in issues)
    incomplete = sum(i["level"] == "incomplete" for i in issues)
    return (1 if errors else 2 if incomplete else 0), dict(
        schemaVersion=1, project=str(root), files=files, git=git_info, issues=issues,
        summary=dict(errors=errors, incomplete=incomplete),
        limitations=["文件摘要和 Git 状态不证明历史结论、任务完成度或上下文质量。", "不读取引用目标内容；不验证远端链接、锚点或执行任何项目命令。"],
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--entry", default="AGENTS.md")
    parser.add_argument("--state")
    parser.add_argument("--baseline")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    code, result = inspect(args.project, args.entry, args.state, args.baseline)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"files={len(result['files'])}; git={result['git']['available']}; errors={result['summary']['errors']}; incomplete={result['summary']['incomplete']}")
        for item in result["issues"]:
            print(f"[{item['level']}] {item['code']}: {item['message']}")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
