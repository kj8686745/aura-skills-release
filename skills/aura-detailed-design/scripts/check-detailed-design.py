#!/usr/bin/env python3
"""Read-only checks for the AURA detailed-design Markdown template, not its semantics."""
import argparse
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


def check(path, mode):
    issues = []

    def issue(level, code, line, message):
        issues.append(dict(level=level, code=code, line=line, message=message))

    try:
        text = path.read_text(encoding="utf-8-sig")
    except (OSError, UnicodeError) as exc:
        issue("error", "input_unreadable", 0, str(exc))
        return finish(path, mode, issues, {})
    lines = text.splitlines()
    visible, fence = [], None
    for number, line in enumerate(lines, 1):
        marker = re.match(r"^\s*(`{3,}|~{3,})", line)
        if marker:
            token = marker[1]
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence) and not line[marker.end():].strip():
                fence = None
            continue
        if fence is None:
            visible.append((number, line))
    if fence:
        issue("incomplete", "unclosed_fence", len(lines), "代码块未闭合，部分内容未解析")

    placeholder = re.compile(r"\[(?:填写|需要时增加|M-编号|C-编号|项目编号-领域-序号|[^\]\n]*待填写[^\]\n]*)\]|\b(?:TODO|TBD)\b", re.I)
    for number, line in visible:
        if placeholder.search(line):
            issue("incomplete", "placeholder", number, "仍有模板占位内容，确认适用性后补写或说明不适用原因")

    # Simple pipe tables only. Do not silently accept a table we cannot parse.
    tables, block = [], []
    for number, line in visible + [(len(lines) + 1, "")]:
        if line.strip().startswith("|") and line.strip().endswith("|"):
            if block and number != block[-1][0] + 1:
                tables.append(block)
                block = []
            block.append((number, line))
        elif block:
            tables.append(block)
            block = []
    parsed = []
    for table in tables:
        rows = [(n, [cell.strip().strip("`") for cell in re.split(r"(?<!\\)\|", row.strip()[1:-1])]) for n, row in table]
        if len(rows) < 2 or not all(re.fullmatch(r":?-{3,}:?", c.replace(" ", "")) for c in rows[1][1]):
            issue("incomplete", "unsupported_table", rows[0][0], "表格分隔行不支持，需人工核对")
            continue
        width = len(rows[0][1])
        if any(len(cells) != width for _, cells in rows):
            issue("incomplete", "unsupported_table", rows[0][0], "表格列数不一致或单元格含复杂竖线，需人工核对")
            continue
        parsed.append((rows[0][1], rows[2:]))

    def section_says_none(label):
        active = False
        for _, line in visible:
            heading = re.match(r"^(#{2,6})\s+(.+)", line)
            if heading:
                if label in heading[2]:
                    active = True
                    continue
                if active:
                    break
            elif active and re.match(r"^\s*(?:[-*]\s+)?无(?:[，；：:。\s]|$)", line):
                if len(line.strip().rstrip("。")) > 1:
                    return True
        return False

    definitions = {"M": {}, "C": {}}
    inventories_parsed = {"M": False, "C": False}
    changed = set()
    if mode == "full":
        for prefix, header, section in [("M", "模块编号", "模块清单"), ("C", "契约编号", "契约清单")]:
            selected = [(headers, rows) for headers, rows in parsed if header in headers and headers[0] == header]
            if not selected and not section_says_none(section):
                issue("incomplete", "missing_inventory", 0, f"未解析到{section}；无此对象时在对应节说明原因")
            for headers, rows in selected:
                for number, cells in rows:
                    identity = cells[0]
                    if not re.fullmatch(prefix + r"-\d{2,}", identity):
                        issue("incomplete", "unsupported_id", number, f"{header}未采用 {prefix}-01 形式或仍为占位")
                        continue
                    if identity in definitions[prefix]:
                        issue("error", "duplicate_id", number, f"{identity} 重复定义（首次在 {definitions[prefix][identity]} 行）")
                    definitions[prefix][identity] = number
                    if prefix == "M":
                        if "变更类型" not in headers:
                            issue("incomplete", "missing_change_type", number, "模块未标明变更类型，无法判断卡片范围")
                        else:
                            change = cells[headers.index("变更类型")]
                            if change == "不变":
                                continue
                            if change not in {"新增", "修改", "删除", "迁移"}:
                                issue("incomplete", "unsupported_change_type", number, "模块变更类型需人工核对")
                            changed.add(identity)
            if selected and not definitions[prefix] and not section_says_none(section):
                issue("incomplete", "empty_inventory", 0, f"{section}无可核对的记录")
            inventories_parsed[prefix] = bool(definitions[prefix]) or section_says_none(section)

        cards, in_cards = {}, False
        for number, line in visible:
            if re.match(r"^##\s+", line):
                in_cards = "模块技术实现卡片" in line
            if in_cards and re.match(r"^#{3,6}\s+", line):
                ids = re.findall(r"(?<![\w-])M-\d{2,}(?![\w-])", line)
                if len(ids) > 1:
                    issue("incomplete", "unsupported_card", number, "一个模块卡片标题含多个模块，需人工核对")
                for identity in ids:
                    if identity in cards:
                        issue("error", "duplicate_card", number, f"{identity} 存在重复模块卡片")
                    cards[identity] = number
        for identity in sorted(changed - cards.keys()):
            issue("error", "missing_card", definitions["M"][identity], f"变更模块 {identity} 缺少实现卡片")
        # References in diagrams and code blocks count too, but are not definitions.
        for number, line in enumerate(lines, 1):
            for identity in set(re.findall(r"(?<![\w-])[MC]-\d{2,}(?![\w-])", line)):
                if inventories_parsed[identity[0]] and identity not in definitions[identity[0]]:
                    issue("error", "undefined_id", number, f"引用了未登记编号 {identity}")
    else:
        required = {"技术目标与范围", "受影响模块与文件", "事实、约束与假设", "明确不影响的边界", "实现差异", "验证方式与证据", "风险与人工确认", "编码准入结论"}
        fields = {cells[0] for _, rows in parsed for _, cells in rows if cells}
        for field in sorted(required - fields):
            issue("incomplete", "missing_simplified_field", 0, f"简化记录未解析到：{field}")
        for _, rows in parsed:
            for number, cells in rows:
                if cells[0] in required and not any(cells[1:]):
                    issue("incomplete", "empty_simplified_field", number, f"简化记录为空：{cells[0]}")

    # Admission is a chosen table value, not a word mentioned somewhere in prose.
    admission_rows = [
        (n, cells[1]) for _, rows in parsed for n, cells in rows
        if len(cells) >= 2 and cells[0] in {"编码准入", "编码准入结论"}
    ]
    if not admission_rows:
        issue("incomplete", "missing_admission", 0, "未解析到编码准入结论行")
    for number, value in admission_rows:
        # Reasons may mention blocked modules; only inspect the selected-value column.
        choices = r"有条件进入编码|可进入编码|阻断"
        chosen = re.fullmatch(choices, value) if mode == "full" else re.match(r"^(?:" + choices + r")(?=$|[；;，,。\s（(：:])", value)
        alternatives = re.search(r"(?:" + choices + r")\s*(?:/|或)\s*(?:" + choices + r")", value)
        if not chosen or alternatives:
            issue("incomplete", "unselected_admission", number, "准入结论需选择唯一一项，不能保留多选占位")

    checked_links = 0
    for number, line in visible:
        line = re.sub(r"`+[^`]*`+", "", line)
        if re.search(r"\]\[[^\]]*\]", line):
            issue("incomplete", "reference_link", number, "引用式链接未自动解析，需人工核对")
        for target in re.findall(r"\]\((<[^>]+>|[^)\s]+)(?:\s+\"[^\"]*\")?\)", line):
            target = target.strip("<>")
            if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", target) or target.startswith(("//", "#")):
                continue
            try:
                local = unquote(urlsplit(target).path)
            except ValueError:
                issue("incomplete", "unsupported_link", number, f"无法解析链接：{target}")
                continue
            if not local:
                continue
            checked_links += 1
            if not (path.parent / local).exists():
                issue("error", "broken_local_link", number, f"本地文档链接不存在：{target}")

    counts = dict(modules=len(definitions["M"]), contracts=len(definitions["C"]), localLinks=checked_links)
    return finish(path, mode, issues, counts)


def finish(path, mode, issues, counts):
    errors = sum(i["level"] == "error" for i in issues)
    incomplete = sum(i["level"] == "incomplete" for i in issues)
    code = 1 if errors else 2 if incomplete else 0
    return code, dict(
        schemaVersion=1, design=str(path), mode=mode,
        status="failed" if errors else "partial" if incomplete else "passed",
        summary=dict(errors=errors, incomplete=incomplete, **counts), issues=issues,
        limitations=["仅检查支持的 Markdown 模板机械项，不证明技术充分性、代码一致性或编码准入。",
                     "代码块不作占位与链接扫描；远端链接、章节锚点、复杂表格和引用式链接须人工核对。"],
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--design", type=Path, required=True)
    parser.add_argument("--mode", choices=["full", "simplified"], required=True)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    code, result = check(args.design.resolve(), args.mode)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(f"{result['status']}: errors={result['summary']['errors']}; incomplete={result['summary']['incomplete']}")
        for item in result["issues"]:
            print(f"[{item['level']}] {args.design}:{item['line']} {item['code']} {item['message']}")
    return code


if __name__ == "__main__":
    sys.exit(main())
