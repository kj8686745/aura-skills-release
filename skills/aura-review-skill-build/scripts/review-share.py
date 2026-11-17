"""Validate review 2.1 evidence and export the same four Markdown reports for offline reading."""

import argparse
from collections import Counter
from hashlib import sha256
from html import escape
from io import BytesIO
import json
from pathlib import Path, PurePosixPath
import re
import runpy
import stat
import subprocess
from urllib.parse import unquote, urlsplit
from zipfile import BadZipFile, ZIP_DEFLATED, ZIP_STORED, ZipFile


REPORTS = (
    "01-规范审查结果.md", "02-代码缺陷审查报告.md",
    "03-公共能力提炼建议.md", "04-优秀实践评估.md",
)
DIRECTIONS = ("正确性", "安全", "性能与资源", "可维护性", "架构设计", "数据与隐私")
CARD = re.compile(r"^#{3,6}\s+(D-\d{3,})[：: ]+(.+)$")
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})([^\n]*)$")
FIELD = re.compile(r"^-\s+\*\*(.+?)\*\*[：:]\s*(.*)$")
SOURCE_FIELD = re.compile(r"^(源码定位|源码原文)(?: ([2-9]|[1-9]\d+))?$")
LOCAL = re.compile(r"(?i)(?:\bfile:/|(?<![\w/])[A-Z]:[\\/]|\\\\[\w.-]+\\|(?<![\w/:])/(?:Users|home|tmp|private|mnt|Volumes)/)")
SECRET = re.compile(r"(?i)(?:-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[A-Z0-9]{16}|https?://[^\s/@]+:[^\s/@]+@)")
CREDENTIAL_KEY = r"(?:[a-z0-9]+[_.-])*(?:password|passwd|secret|access[_-]?token|refresh[_-]?token|api[_-]?key|client[_-]?secret)"
CREDENTIAL_ASSIGNMENT = re.compile(
    r"""(?im)\b["']?""" + CREDENTIAL_KEY + r"""["']?\s*[:=]\s*(?:"([^"\r\n]+)"|'([^'\r\n]+)'|([a-z0-9._/+@!-]{8,})(?=\s*(?:[,;}#]|$)))"""
)
PLACEHOLDER = re.compile(r"(?i)(?:\$\{[^}]+\}|\*+|<[^>]+>|\[?REDACTED(?:_SECRET)?\]?|已脱敏|已隐藏)")
BEARER = re.compile(r"(?i)\bBearer\s+[a-z0-9._~+/=-]{16,}")
MAX_FILE = 2 * 1024 * 1024
MAX_BUNDLE = 16 * 1024 * 1024
HTML_NAME = "审查报告.html"
MANIFEST_NAME = "分享清单.json"
ATTACHMENT_EXTENSIONS = (".json", ".txt", ".md", ".csv")


def cards(text):
    current = None
    field = None
    fence = None
    excerpt = None
    excerpt_field = None
    for line in text.split("\n"):
        marker = FENCE.fullmatch(line)
        if fence:
            if marker and marker[1].startswith(fence) and not marker[2].strip():
                if excerpt is not None:
                    current["原文片段"][excerpt_field] = "\n".join(excerpt)
                fence = excerpt = None
            elif excerpt is not None:
                excerpt.append(line)
            continue
        if marker:
            fence = marker[1]
            if current is not None and field and SOURCE_FIELD.fullmatch(field) and field.startswith("源码原文"):
                excerpt = []
                excerpt_field = field
                field = None
            continue
        if line.startswith("#"):
            if current is not None:
                yield current
            found = CARD.fullmatch(line)
            current = {"id": found[1], "原文片段": {}} if found else None
            field = None
        elif current is not None:
            matched = FIELD.match(line)
            if matched:
                field, value = matched.groups()
                if field in current:
                    raise ValueError(f"{current['id']} 字段重复：{field}")
                current[field] = value.strip()
    if fence:
        raise ValueError("报告02含未闭合的代码围栏")
    if current is not None:
        yield current


def anchor(value):
    parts = [field.strip().strip("`") for field in value.split("|")]
    if len(parts) != 6 or not all(parts):
        raise ValueError("源码定位应含仓库、分支、完整 SHA、相对路径、符号与起止行")
    repo, branch, commit, path, symbol, line_range = parts
    if not re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", commit):
        raise ValueError("源码定位需要完整 SHA")
    relative = PurePosixPath(path)
    if (relative.is_absolute() or not relative.parts or relative.as_posix() != path
            or ".." in relative.parts or ".git" in relative.parts or re.search(r"[:\\\x00]", path)):
        raise ValueError("源码定位需要仓库相对路径")
    match = re.fullmatch(r"([1-9]\d*)(?:-([1-9]\d*))?", line_range)
    if not match:
        raise ValueError("源码定位行号应为单行或起行-止行")
    first, last = int(match[1]), int(match[2] or match[1])
    if last < first:
        raise ValueError("源码止行早于起行")
    return repo, branch, commit, path, symbol, first, last


def without_examples(text):
    """Keep offsets for slicing original excerpts, while excluding Markdown examples."""
    lines = []
    fence = None
    for line in text.split("\n"):
        marker = FENCE.fullmatch(line)
        masked = fence is not None or marker is not None
        if marker:
            if fence is None:
                fence = marker[1]
            elif marker[1].startswith(fence) and not marker[2].strip():
                fence = None
        lines.append(" " * len(line) if masked else line)
    return re.sub(r"(?s)<!--.*?(?:-->|\Z)", lambda m: re.sub(r"[^\n]", " ", m[0]), "\n".join(lines))


def source_excerpts(item):
    numbers = set()
    for field in item:
        match = SOURCE_FIELD.fullmatch(field)
        if match:
            numbers.add(int(match[2] or 1))
        elif field.startswith(("源码定位", "源码原文")):
            raise ValueError(f"{item['id']} 的源码编号应从主片段、2、3 依次填写")
    indexes = sorted(numbers)
    if not indexes or indexes[0] != 1 or indexes[-1] != len(indexes):
        raise ValueError(f"{item['id']} 的源码定位和原文必须从主片段起连续编号")
    seen = set()
    for index in indexes:
        suffix = "" if index == 1 else f" {index}"
        locator = item.get("源码定位" + suffix)
        excerpt = item["原文片段"].get("源码原文" + suffix)
        if not locator or not excerpt or not excerpt.strip():
            raise ValueError(f"{item['id']} 第 {index} 段须提供成对的源码定位与原文")
        location = anchor(locator)
        if excerpt.count("\n") + 1 != location[-1] - location[-2] + 1:
            raise ValueError(f"{item['id']} 第 {index} 段原文行数与定位范围不符")
        repo, _, commit, path, _, first, last = location
        identity = (repo, commit, path, first, last)
        if identity in seen:
            raise ValueError(f"{item['id']} 重复列出同一源码行段")
        seen.add(identity)
        yield item["id"], location, excerpt


def validate(texts):
    text = texts[REPORTS[1]]
    visible = without_examples(text)
    business = re.search(r"(?m)^## 三、业务链结论与覆盖索引[ \t]*$", visible)
    verification = re.search(r"(?m)^## 四、验证状态与审查边界[ \t]*$", visible)
    analysis = re.search(r"(?m)^## 二、分项分析[ \t]*$", visible)
    if not (analysis and business and verification and analysis.start() < business.start() < verification.start()):
        raise ValueError("报告02须先列缺陷卡，再列业务链覆盖和验证状态")
    coverage = visible[business.end():verification.start()]
    rows = re.findall(r"(?m)^\|\s*([^|\n]+?)\s*\|\s*([^|\n]+?)\s*\|", coverage)
    if Counter(k for k, v in rows if k in DIRECTIONS and v.strip() and v.strip() != "路径、结论、证据") != Counter(DIRECTIONS):
        raise ValueError("报告02覆盖表须逐项记录六方向的结论或排除依据")
    validation = visible[verification.end():].strip()
    if not validation:
        raise ValueError("验证状态与审查边界为空")
    evidence, roots = [], set()
    fields = ("根因", "时间归属", "判断依据", "触发与影响", "证据", "修改位置", "推荐方案", "关闭条件")
    selected = list(cards(text[analysis.end():business.start()]))
    if [item["id"] for item in cards(text)] != [item["id"] for item in selected]:
        raise ValueError("D 卡片须全部位于报告02分项分析章节")
    for item in selected:
        status = item.get("状态")
        if status == "待补证":
            if not all(item.get(key) for key in ("缺失事实", "判断影响", "现有材料限制", "最小补证")):
                raise ValueError(f"{item['id']} 缺待补证的事实、影响、限制或动作")
        if status != "已确认缺陷":
            continue
        missing = [key for key in fields if not item.get(key)]
        if missing:
            raise ValueError(f"{item['id']} 缺整改字段：{'、'.join(missing)}")
        if item["时间归属"] not in ("本窗口引入", "存量新确认", "历史复核", "引入待核"):
            raise ValueError(f"{item['id']} 时间归属无效")
        if item["根因"] in roots:
            raise ValueError(f"{item['id']} 确认缺陷重复统计同根因")
        roots.add(item["根因"])
        evidence.extend(source_excerpts(item))
    return evidence


def verify_blobs(evidence, source_map):
    mapping = json.loads(source_map.read_text(encoding="utf-8-sig"))
    if not isinstance(mapping, dict):
        raise ValueError("仓库映射须为 JSON 对象")
    tools = runpy.run_path(str(Path(__file__).with_name("review-git-evidence.py")))
    repos = {}
    for finding, (name, _, commit, file, _, first, last), excerpt in evidence:
        if name not in mapping:
            raise ValueError(f"{finding} 缺仓库 {name} 的本地核验映射")
        if name not in repos:
            entry = mapping[name]
            if not isinstance(entry, dict) or not all(isinstance(entry.get(k), str) and entry[k] for k in ("origin", "path")):
                raise ValueError(f"仓库 {name} 的映射须含 path 和预期 origin")
            repos[name] = tools["Repository"](Path(entry["path"]), entry["origin"])
        repo = repos[name]
        exact = repo.commit(commit)
        entry = repo.read("ls-tree", "-z", exact, "--", file)
        if not entry.startswith((b"100644 blob ", b"100755 blob ")):
            raise ValueError(f"{finding} Git 中没有该普通源码文件")
        raw = repo.read("cat-file", "blob", f"{exact}:{file}").replace(b"\r\n", b"\n")
        lines = raw.decode("utf-8").removesuffix("\n").split("\n")
        if last > len(lines) or "\n".join(lines[first - 1:last]) != excerpt:
            raise ValueError(f"{finding} 源码摘录与固定 Git blob 行段不一致")


def read_file(root, name):
    relative = PurePosixPath(name)
    if relative.is_absolute() or not relative.parts or ".." in relative.parts or ".git" in relative.parts or "\\" in name:
        raise ValueError("报告或附件必须在包内")
    path = root
    for part in relative.parts:
        path = path / part
        if path.is_symlink() or getattr(path.lstat(), "st_file_attributes", 0) & 0x400:
            raise ValueError("报告附件不能使用符号链接或重解析路径")
    if not path.is_file() or path.stat().st_size > MAX_FILE:
        raise ValueError("报告附件缺失、不是普通文件或超出单文件大小限制")
    return path.read_bytes()


def slug(text):
    return re.sub(r"[\s-]+", "-", re.sub(r"[^\w\s-]", "", text.casefold())).strip("-")


def excerpt_manifest(evidence):
    return [{
        "finding": finding, "repo": repo, "branch": branch, "commit": commit, "path": path,
        "symbol": symbol, "firstLine": first, "lastLine": last,
        "excerptSha256Lf": sha256(excerpt.encode("utf-8")).hexdigest(),
    } for finding, (repo, branch, commit, path, symbol, first, last), excerpt in evidence]


def report_texts(raw):
    return {name: raw[name].decode("utf-8-sig").replace("\r\n", "\n") for name in REPORTS}


def archive_digest(stream):
    digest = sha256()
    for chunk in iter(lambda: stream.read(1024 * 1024), b""):
        digest.update(chunk)
    return digest.hexdigest()


def verify_archive(path, expected, sources):
    if path.stat().st_size > 4 * MAX_BUNDLE:
        raise ValueError("分享 ZIP 超出大小限制")
    with path.open("rb") as stream:
        sample = stream.read(4 * MAX_BUNDLE + 1)
    if len(sample) > 4 * MAX_BUNDLE:
        raise ValueError("分享 ZIP 超出大小限制")
    actual = sha256(sample).hexdigest()
    if expected and actual != expected.lower():
        raise ValueError("分享 ZIP 与提供的 SHA-256 不一致")
    with ZipFile(BytesIO(sample)) as archive:
        entries = archive.infolist()
        names = [entry.filename for entry in entries]
        if len({name.casefold() for name in names}) != len(names):
            raise ValueError("分享 ZIP 有重复或大小写等价的文件名")
        for entry in entries:
            name = entry.filename
            rel = PurePosixPath(name)
            if entry.flag_bits & 1 or entry.compress_type not in (ZIP_STORED, ZIP_DEFLATED):
                raise ValueError("分享 ZIP 有加密或不受支持的压缩条目")
            if (entry.is_dir() or stat.S_ISLNK(entry.external_attr >> 16)
                    or rel.as_posix() != name or re.search(r"[:\\\x00-\x1f]", name)
                    or ".." in rel.parts):
                raise ValueError("分享 ZIP 有不安全的文件条目")
            if name in (*REPORTS, HTML_NAME, MANIFEST_NAME):
                continue
            if not name.startswith("证据/") or rel.suffix.lower() not in ATTACHMENT_EXTENSIONS:
                raise ValueError("分享 ZIP 仅能包含报告及受支持的文本附件")
        if sum(entry.file_size for entry in entries) > 4 * MAX_BUNDLE or any(
            entry.file_size > MAX_FILE for entry in entries if entry.filename != HTML_NAME
        ):
            raise ValueError("分享 ZIP 内容超出大小限制")
        if not set((*REPORTS, HTML_NAME, MANIFEST_NAME)) <= set(names):
            raise ValueError("分享 ZIP 缺少报告、HTML 或清单")
        manifest = json.loads(archive.read(MANIFEST_NAME))
        if not isinstance(manifest, dict) or manifest.get("format") != "2.1.0":
            raise ValueError("分享清单的报告格式无效")
        files = manifest.get("files")
        if not isinstance(files, dict) or set(files) != set(names) - {HTML_NAME, MANIFEST_NAME}:
            raise ValueError("分享清单与 ZIP 文件集合不一致")
        raw = {name: archive.read(name) for name in files}
        if any(sha256(data).hexdigest() != files[name] for name, data in raw.items()):
            raise ValueError("分享 ZIP 内报告或附件摘要不一致")
        if sha256(archive.read(HTML_NAME)).hexdigest() != manifest.get("htmlSha256"):
            raise ValueError("分享 ZIP 内 HTML 摘要不一致")
    evidence = validate(report_texts(raw))
    if len(evidence) != manifest.get("verifiedSourceExcerpts"):
        raise ValueError("报告与清单中的源码摘录数量不符")
    if "sourceExcerpts" in manifest and excerpt_manifest(evidence) != manifest["sourceExcerpts"]:
        raise ValueError("报告与清单的源码定位或摘录摘要不一致")
    if sources:
        verify_blobs(evidence, sources)
    return {"status": "checked", "archiveSha256": actual, "matchedExpectedSha256": bool(expected),
            "files": len(names), "declaredSourceExcerpts": len(evidence),
            "verifiedSourceExcerpts": len(evidence) if sources else 0}


def sensitive(text):
    if SECRET.search(text) or BEARER.search(text):
        return True
    return any(not PLACEHOLDER.fullmatch(next(value for value in item.groups() if value is not None))
               for item in CREDENTIAL_ASSIGNMENT.finditer(text))


def html_bundle(root, raw):
    from markdown_it import MarkdownIt

    parser = MarkdownIt("commonmark", {"html": False}).enable("table")
    documents, headings, attachments = {}, {}, {}
    pending = list(REPORTS)
    total = sum(len(value) for value in raw.values())
    while pending:
        name = pending.pop(0)
        data = raw[name]
        text = data.decode("utf-8-sig")
        if LOCAL.search(text) or sensitive(text):
            raise ValueError(f"{name} 含运行机路径或凭据特征，请先脱敏")
        if not name.endswith(".md"):
            attachments[name] = text
            continue
        tokens = parser.parse(text)
        documents[name] = tokens
        headings[name] = {}
        for i, token in enumerate(tokens):
            if token.type == "heading_open":
                key = slug(tokens[i + 1].content)
                base = key
                index = 1
                while key in headings[name]:
                    key = f"{base}-{index}"
                    index += 1
                heading_id = f"{name}-{key}"
                token.attrSet("id", heading_id)
                headings[name][key] = heading_id
        for token in tokens:
            for child in token.children or ():
                if child.type == "image":
                    raise ValueError(f"{name} 的内联图像需改为包内文字证据链接")
                if child.type != "link_open":
                    continue
                link = urlsplit(child.attrGet("href"))
                if link.username is not None or link.password is not None:
                    raise ValueError(f"{name} 的链接包含认证信息")
                if link.scheme in ("http", "https") and link.netloc:
                    child.attrSet("rel", "noreferrer")
                    continue
                if link.scheme or link.netloc or link.query:
                    raise ValueError(f"{name} 包含不支持的链接")
                decoded = unquote(link.path)
                if ":" in decoded or decoded.startswith("/") or "\\" in decoded:
                    raise ValueError(f"{name} 包含绝对链接")
                target = str(PurePosixPath(name).parent / decoded) if decoded else name
                # Permit a relative link from an evidence note back to a report, within root.
                parts = []
                for part in PurePosixPath(target).parts:
                    if part == "..":
                        if not parts:
                            raise ValueError(f"{name} 有越界附件")
                        parts.pop()
                    else:
                        parts.append(part)
                target = "/".join(parts)
                if target not in raw:
                    if not target.startswith("证据/") or PurePosixPath(target).suffix.lower() not in ATTACHMENT_EXTENSIONS:
                        raise ValueError(f"{name} 的附件须为证据目录内的文本文件")
                    raw[target] = read_file(root, target)
                    total += len(raw[target])
                    if total > MAX_BUNDLE:
                        raise ValueError("分享材料超出总大小限制")
                    pending.append(target)
                child.meta["offline"] = (target, unquote(link.fragment))
    for tokens in documents.values():
        for token in tokens:
            for child in token.children or ():
                if "offline" not in child.meta:
                    continue
                target, fragment = child.meta["offline"]
                if fragment:
                    heading = headings.get(target, {}).get(fragment)
                    if not heading:
                        raise ValueError(f"链接锚点不存在：{target}#{fragment}")
                else:
                    heading = target
                child.attrSet("href", "#" + heading)
    order = (REPORTS[1], REPORTS[0], *REPORTS[2:])
    nav = "".join(f'<a href="#{escape(name)}">{escape(name[3:-3])}</a>' for name in order)
    body = "".join(f'<article id="{escape(name)}">' + parser.renderer.render(documents[name], parser.options, {}) + "</article>"
                   for name in (*order, *(key for key in documents if key not in REPORTS)))
    body += "".join(f'<section id="{escape(name)}"><h2>{escape(name)}</h2><pre>{escape(content)}</pre></section>'
                    for name, content in attachments.items())
    return """<!doctype html><html lang="zh"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'">
<title>代码审查报告</title><style>
body{margin:0 auto;max-width:72rem;padding:clamp(1rem,4vw,3rem);font:16px/1.65 system-ui,sans-serif;color:#1e293b}
nav{display:flex;gap:.75rem 1.5rem;flex-wrap:wrap;padding:1rem 0}a{color:#174a8b;overflow-wrap:anywhere}
article{margin:1.5rem 0 3rem}h1,h2,h3,td,li,p{overflow-wrap:anywhere}table{display:block;overflow:auto;border-collapse:collapse}
td,th{padding:.4rem .65rem;border:1px solid #cbd5e1;text-align:left}th,pre{background:#f1f5f9}
pre{padding:1rem;overflow:auto;white-space:pre-wrap;overflow-wrap:anywhere}
blockquote{border-left:3px solid #64748b;margin-left:0;padding-left:1rem}
</style><body><nav aria-label="审查报告目录">""" + nav + "</nav><main>" + body + "</main></body></html>"


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    input_group = cli.add_mutually_exclusive_group(required=True)
    input_group.add_argument("--report-dir", type=Path)
    input_group.add_argument("--verify-archive", type=Path, help="只读校验已转发的分享 ZIP")
    cli.add_argument("--sources", type=Path, help="本地仓库映射 JSON，键为仓库标识，值为 {path, origin}")
    cli.add_argument("--output", type=Path, help="新建 ZIP，包含同源 Markdown、HTML 与引用附件")
    cli.add_argument("--mode", choices=("Change", "Project"), default="Change", help="导出前的报告结构检查范围")
    cli.add_argument("--expected-sha256", help="通过可信渠道取得的分享 ZIP SHA-256")
    args = cli.parse_args()
    try:
        if args.verify_archive:
            if args.output:
                raise ValueError("校验 ZIP 时不能同时指定导出")
            print(json.dumps(verify_archive(args.verify_archive, args.expected_sha256, args.sources), ensure_ascii=False))
            return 0
        if args.expected_sha256:
            raise ValueError("--expected-sha256 仅用于校验 ZIP")
        root = args.report_dir.resolve(strict=True)
        raw = {name: read_file(root, name) for name in REPORTS}
        evidence = validate(report_texts(raw))
        if args.sources:
            verify_blobs(evidence, args.sources)
        if args.output:
            if evidence and not args.sources:
                raise ValueError("含确认缺陷的分享包需要 --sources 核对源码摘录")
            rendered = html_bundle(root, raw).encode("utf-8")
            check = subprocess.run(
                ["pwsh", "-NoProfile", "-File", str(Path(__file__).with_name("check-review-result.ps1")),
                 "-ResultPath", str(root), "-Mode", args.mode, "-Json"],
                capture_output=True, encoding="utf-8", timeout=60,
            )
            if check.returncode:
                raise ValueError(f"报告结构自检退出 {check.returncode}，请核对报告检查结果")
            checked = json.loads(check.stdout)
            if checked.get("status") != "passed" or checked.get("formatVersion") != "2.1.0":
                raise ValueError("分享导出需要已通过结构检查的 2.1.0 报告")
            if any(read_file(root, name) != data for name, data in raw.items()):
                raise ValueError("分享材料在检查期间有变更，请重新导出")
            dest = args.output.absolute()
            if dest.suffix.lower() != ".zip" or dest.exists():
                raise ValueError("分享输出必须是尚不存在的 ZIP")
            output = dest.open("xb")
            try:
                with output, ZipFile(output, "w", ZIP_DEFLATED) as bundle:
                    for name, data in raw.items():
                        bundle.writestr(name, data)
                    bundle.writestr(HTML_NAME, rendered)
                    bundle.writestr(MANIFEST_NAME, json.dumps({
                        "format": "2.1.0", "verifiedSourceExcerpts": len(evidence),
                        "sourceExcerpts": excerpt_manifest(evidence),
                        "files": {name: sha256(data).hexdigest() for name, data in raw.items()},
                        "htmlSha256": sha256(rendered).hexdigest(),
                    }, ensure_ascii=False, indent=2))
            except Exception:
                dest.unlink(missing_ok=True)
                raise
        result = {"status": "checked", "defects": len({item[0] for item in evidence}),
                  "verifiedSourceExcerpts": len(evidence) if args.sources else 0}
        if args.output:
            with dest.open("rb") as stream:
                result["archiveSha256"] = archive_digest(stream)
        print(json.dumps(result, ensure_ascii=False))
        return 0
    except (ValueError, OSError, KeyError, ImportError, BadZipFile, subprocess.TimeoutExpired) as exc:
        print(json.dumps({"status": "failed", "reason": str(exc)}, ensure_ascii=False))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
