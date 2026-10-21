#!/usr/bin/env python3
"""Read-only preflight and mechanical checks for an AURA capability delivery."""
import argparse
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlsplit

GOV = Path("AURA天玑规范体系/AURA天玑规范建设管理/治理维护体系/03-能力包治理")
PUBLIC = Path("AURA天玑规范体系/AURA天玑公司级框架规范/05-能力包")


def check(root, package, phase="content", mode="candidate", record=None):
    root = Path(root).resolve()
    issues, files, rules = [], [], {}
    repository = {}

    def issue(level, code, path, message):
        issues.append(dict(level=level, code=code, path=str(path), message=message))

    def resolve(relative):
        if Path(relative).is_absolute():
            raise ValueError("文档路径应相对规范仓库")
        path = (root / relative).resolve()
        if not path.is_relative_to(root):
            raise ValueError("文档路径超出规范仓库")
        return path

    def git(*args):
        proc = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=15)
        return proc.returncode, proc.stdout.strip()

    try:
        if not root.is_dir():
            raise ValueError("规范仓库根不存在")
        code, top = git("rev-parse", "--show-toplevel")
        if code or Path(top).resolve() != root:
            raise ValueError("需要明确的规范仓库根，不能用父目录或业务子目录")
        code, remote = git("remote", "get-url", "origin")
        if code or not re.fullmatch(r"ssh://[^/@]+@git\.fxft\.net:2222/other/aura-code-nexus\.git/?", remote, re.I):
            raise ValueError("origin 未匹配约定规范仓库；先核实位置，不向其他仓库生成")
        _, repository["branch"] = git("branch", "--show-current")
        _, repository["head"] = git("rev-parse", "--verify", "HEAD")
        if repository["branch"] != "1.0.0":
            issue("incomplete", "branch_needs_confirmation", root, "当前非维护分支1.0.0；核实个人分支目标，不自动切换")
        target = resolve(package)
        gov = (root / GOV).resolve()
        public = (root / PUBLIC).resolve()
        if mode == "candidate":
            if not target.is_relative_to(gov) or target.name != "候选对外内容" or target.parent == gov:
                raise ValueError("新包应位于治理区的具体能力目录/候选对外内容")
        elif not target.is_relative_to(public) or target == public:
            raise ValueError("现行修订应指向公司规范05-能力包下的具体包目录")
        record_path = resolve(record) if record else None
        if record_path and (not record_path.is_relative_to(gov) or record_path.is_relative_to(target)):
            raise ValueError("内部记录必须在能力包治理区，不能进入候选对外内容或现行公开包")
        if phase == "content":
            if not target.is_dir():
                raise ValueError("待检查能力包目录不存在")
            if not record_path or not record_path.is_file():
                issue("incomplete", "missing_internal_record", record or "", "未取得已归并的内部记录，无法核对证据归属")
            documents = sorted(target.rglob("*.md"))
            if not documents:
                issue("incomplete", "empty_delivery", target, "没有对外文档")
            if len(documents) > 3:
                issue("error", "too_many_documents", target, f"对外Markdown共{len(documents)}份，超过三份")
            for doc in documents:
                if not doc.resolve().is_relative_to(root):
                    issue("error", "external_file", doc, "文件解析后超出规范库；未读取")
                    continue
                files.append(str(doc.relative_to(root)))
                if doc.parent != target:
                    issue("incomplete", "nested_document", doc, "正文散入子目录，核实是否应归并三份正文")
                if not re.match(r"^\d{2}-", doc.name):
                    issue("incomplete", "unnumbered_document", doc, "文档没有顺序编号，核对既有命名及模板")
                if "内部定义" in doc.name or "审查报告" in doc.name:
                    issue("error", "internal_document", doc, "内部材料进入对外目录")
                text = doc.read_text(encoding="utf-8-sig")
                if not text.strip():
                    issue("incomplete", "empty_document", doc, "正文为空，不能作为已完成的交付文件")
                visible, fence = [], False
                for number, line in enumerate(text.splitlines(), 1):
                    if re.match(r"^\s*(?:`{3,}|~{3,})", line):
                        fence = not fence
                        continue
                    if not fence:
                        visible.append((number, line))
                if fence:
                    issue("incomplete", "unclosed_fence", doc, "代码块未闭合，正文检查不完整")
                blocks, current = [], None
                for number, line in visible:
                    heading = re.match(r"^(#{2,6})\s+(.*)", line)
                    if heading and current and len(heading[1]) <= current["depth"]:
                        blocks.append(current)
                        current = None
                    match = re.search(r"规则\s+`?([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)+)", line) if heading else None
                    if match:
                        current = dict(id=match[1], depth=len(heading[1]), line=number, text=[])
                    if current:
                        current["text"].append(line)
                    location = f"{doc}:{number}"
                    if re.search(r"<[^>]*(?:填写|稳定|版本|名称|编号)[^>]*>|\[填写\]|\b(?:TODO|TBD)\b", line, re.I):
                        issue("incomplete", "placeholder", location, "残留常见模板占位，需补充或说明不适用")
                    if re.search(r"本轮任务|源码盘点过程|审查评分", line):
                        issue("incomplete", "process_text_candidate", location, "疑似建设过程说明，需判断是否属于使用者内容")
                    for link in re.findall(r"\]\((<[^>]+>|[^)\s]+)(?:\s+\"[^\"]*\")?\)", line):
                        link = link.strip("<>")
                        if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", link) or link.startswith(("//", "#")):
                            continue
                        destination = (doc.parent / unquote(urlsplit(link).path)).resolve()
                        if destination.is_relative_to(gov) and not destination.is_relative_to(target):
                            issue("error", "internal_link", location, "对外文档链接内部治理资料")
                        elif not destination.exists():
                            issue("error", "broken_link", location, f"本地链接不存在：{link}")
                if current:
                    blocks.append(current)
                if re.search(r"使用|接入", doc.stem) and not blocks:
                    issue("incomplete", "unparsed_rules", doc, "使用手册未解析到规则编号块；需人工核对规则覆盖，不按零规则通过")
                for block in blocks:
                    identity = block["id"]
                    location = f"{doc}:{block['line']}"
                    if identity in rules:
                        issue("error", "duplicate_rule", location, f"规则{identity}重复定义，首次为{rules[identity]}")
                    rules[identity] = location
                    body = "\n".join(block["text"])
                    for code, pattern, message in [
                        ("missing_necessity", r"必要性.{0,8}(?:必须|条件必须|可选)", "缺少可识别必要性标注"),
                        ("missing_positive", r"正例|正确用法|正确示例|正确做法", "缺少相邻正例标记"),
                        ("missing_negative", r"反例|错误用法|错误示例|错误做法", "缺少相邻反例标记"),
                    ]:
                        if not re.search(pattern, body):
                            issue("incomplete", code, location, message)
    except (OSError, ValueError, UnicodeError, subprocess.TimeoutExpired) as exc:
        issue("error", "invalid_input", root, str(exc))
    errors = sum(i["level"] == "error" for i in issues)
    incomplete = sum(i["level"] == "incomplete" for i in issues)
    code = 1 if errors else 2 if incomplete else 0
    return code, dict(
        schemaVersion=1, standardsRoot=str(root), phase=phase, mode=mode,
        repository=repository, files=files, rules=rules, issues=issues,
        summary=dict(errors=errors, incomplete=incomplete),
        limitations=["只核对选定输出与已识别正文标记，不证明能力、契约、版本或示例真实可用。",
                     "未识别的规则写法、正反例内容充分性、总分总阅读闭环和源代码映射须人工复核；preflight不检查正文。"],
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--standards-root", type=Path, required=True)
    parser.add_argument("--package-path", required=True)
    parser.add_argument("--phase", choices=["preflight", "content"], default="content")
    parser.add_argument("--mode", choices=["candidate", "update"], default="candidate")
    parser.add_argument("--internal-record")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    code, result = check(args.standards_root, args.package_path, args.phase, args.mode, args.internal_record)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"files={len(result['files'])}; rules={len(result['rules'])}; errors={result['summary']['errors']}; incomplete={result['summary']['incomplete']}")
        for item in result["issues"]:
            print(f"[{item['level']}] {item['path']} {item['code']}: {item['message']}")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
