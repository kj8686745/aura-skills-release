#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ResultPath, [switch]$Json)
# Checks human-authored decisions; never creates findings from code patterns.
$ErrorActionPreference = 'Stop'
$issues = [Collections.Generic.List[object]]::new()
function Add-Issue($Level, $Code, $Path, $Message) { $issues.Add([ordered]@{level=$Level;code=$Code;path=$Path;message=$Message}) }
function Strip-Examples($Text) { [regex]::Replace($Text, '(?ms)^\s*(`{3,}|~{3,})[^\r\n]*\r?\n.*?^\s*\1\s*$|<!--.*?-->', '') }
function Value-Of($Body, $Field) {
    $m = [regex]::Match($Body, '(?m)^\s*-\s*\*\*' + [regex]::Escape($Field) + '\*\*\s*[：:]\s*(?<value>[^\r\n]+)')
    return $m.Groups['value'].Value.Trim()
}
try {
    $root = (Resolve-Path -LiteralPath $ResultPath).Path
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw '需要四份报告所在目录' }
    $names = @('01-规范审查结果.md','02-代码缺陷审查报告.md','03-公共能力提炼建议.md','04-优秀实践评估.md')
    $texts = @{}
    foreach ($name in $names) {
        $file = Join-Path $root $name
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Add-Issue error missing_dimension_file $name '缺少四维报告'; continue }
        $texts[$name] = Strip-Examples ([IO.File]::ReadAllText($file))
        if ([string]::IsNullOrWhiteSpace($texts[$name])) { Add-Issue error empty_report $name '报告为空' }
        if ($texts[$name] -match '\[待填写\]|\[填写[^\]]*\]|(?m)^\s*\|\s*实数\s*\||P0/P1/P2/P3|已确认缺陷 / 待补证|提炼候选 / 不建议提炼|已确认实践 / 待补证') { Add-Issue incomplete unfilled_template $name '仍有未裁定模板占位内容' }
        foreach ($m in [regex]::Matches($texts[$name], '\[[^\]\r\n]+\]\((?<target>[^\s)]+)\)')) {
            $target = $m.Groups['target'].Value; $part = $target.Split('#')[0]
            if (-not $part -or $target -match '^(?:[A-Za-z][A-Za-z0-9+.-]*:|//)') { continue }
            $path = [IO.Path]::GetFullPath((Join-Path $root ([Uri]::UnescapeDataString($part))))
            if (-not $path.StartsWith($root.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { Add-Issue incomplete external_reference $name '包外链接需按审查基线核对'; continue }
            if (-not (Test-Path -LiteralPath $path)) { Add-Issue error missing_link $name "引用不存在：$target" }
        }
    }
    foreach ($file in Get-ChildItem -LiteralPath $root -File -Filter '*.md') { if ($file.Name -notin $names) { Add-Issue error extra_report $file.Name '新结果包根目录仅保留四份报告，过程表归入规范报告' } }
    $norm = [string]$texts[$names[0]]
    $eIds = @([regex]::Matches($norm, '(?m)^\s*\|\s*(E-\d{3,})\s*\|') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    foreach ($name in $names[1..3]) {
        foreach ($ref in @([regex]::Matches([string]$texts[$name], '(?<![A-Z0-9-])E-\d{3,}(?![A-Z0-9-])') | ForEach-Object Value | Sort-Object -Unique)) {
            if ($ref -notin $eIds) { Add-Issue error unknown_dimension_evidence $name "报告引用未定义证据：$ref" }
        }
    }
    foreach ($name in $names[1..3]) { if ($norm -notmatch [regex]::Escape($name)) { Add-Issue incomplete missing_navigation $names[0] "首页缺少报告导航：$name" } }
    $definitions = @{}
    foreach ($m in [regex]::Matches($norm, '(?m)^#{1,6}[ \t]+(F-\d{3,})[：: \t]')) { $definitions[$m.Groups[1].Value] = $names[0] }
    $specs = @(
        @{name=$names[1];prefix='D';states=@('已确认缺陷','待补证','维护建议');fields=@('状态','代码位置','判断依据','触发与影响','证据','优先级','建议与关闭条件','关联发现');columns=@('已确认缺陷','待补证','维护建议')},
        @{name=$names[2];prefix='R';states=@('提炼候选','不建议提炼','待补证');fields=@('状态','代码位置','共同处理与差异','已有能力比对','建议归属与契约','收益与成本','证据','验证与迁移','关联发现');columns=@('提炼候选','不建议提炼','待补证')},
        @{name=$names[3];prefix='G';states=@('已确认实践','待补证');fields=@('状态','代码位置','具体机制','收益与证据边界','适用条件与限制','证据','推广建议','关联发现');columns=@('已确认实践','待补证')}
    )
    $summaries = @{}; $cardsById = @{}
    foreach ($spec in $specs) {
        $text = [string]$texts[$spec.name]
        foreach ($heading in @('一、结论与范围', $(if($spec.prefix -eq 'D'){'二、分项分析'}elseif($spec.prefix -eq 'R'){'二、候选与边界分析'}else{'二、实践与推广条件'}))) {
            if ($text -notmatch ('(?m)^#{1,6}\s+'+[regex]::Escape($heading)+'\s*$')) { Add-Issue error missing_dimension_section $spec.name "缺少章节：$heading" }
        }
        if ($text -notmatch '(?m)^#{1,6}\s+三、\S+') { Add-Issue error missing_dimension_conclusion $spec.name '缺少处理/推广结论及未证实边界章节' }
        $counts = @{}; foreach ($s in $spec.states) { $counts[$s]=0 }
        $pattern = '(?ms)^#{3,6}[ \t]+(?<id>'+$spec.prefix+'-\d{3,})[：: \t]+[^\r\n]+\r?\n(?<body>.*?)(?=^#{1,6}[ \t]+|\z)'
        $cards = @([regex]::Matches($text, $pattern))
        foreach ($card in $cards) {
            $id=$card.Groups['id'].Value; $body=$card.Groups['body'].Value
            if ($definitions.ContainsKey($id)) { Add-Issue error duplicate_dimension_id $spec.name "重复卡片：$id" } else { $definitions[$id]=$spec.name; $cardsById[$id]=$body }
            foreach ($field in $spec.fields) { if (-not (Value-Of $body $field)) { Add-Issue error missing_dimension_field $spec.name "$id 缺字段：$field" } }
            $state = Value-Of $body '状态'
            if ($state -notin $spec.states) { Add-Issue error invalid_dimension_state $spec.name "$id 状态无效" } else { $counts[$state]++ }
            $ev = @([regex]::Matches((Value-Of $body '证据'), '(?<![A-Z0-9-])E-\d{3,}(?![A-Z0-9-])') | ForEach-Object Value | Sort-Object -Unique)
            if (-not $ev.Count) { Add-Issue error dimension_missing_evidence $spec.name "$id 没有证据引用" }
            foreach ($ref in $ev) { if ($ref -notin $eIds) { Add-Issue error unknown_dimension_evidence $spec.name "$id 引用未定义证据：$ref" } }
            $priority = Value-Of $body '优先级'
            if ($spec.prefix -eq 'D') {
                if ($state -eq '已确认缺陷' -and $priority -notmatch '^P[0-3](?:[；;，,。\s]|$)') { Add-Issue error defect_priority $spec.name "$id 已确认缺陷缺有效优先级" }
                if ($state -ne '已确认缺陷' -and $priority -match '\bP[0-3]\b') { Add-Issue error suggestion_counted_as_defect $spec.name "$id 待补证/维护建议不能计确认缺陷优先级" }
            }
            if ((Value-Of $body '代码位置') -in @('无','待补充','未提供','见证据')) { Add-Issue incomplete vague_code_position $spec.name "$id 代码位置无法定位" }
        }
        $summaries[$spec.prefix]=$counts
        $lines=$text -split '\r?\n'; $tableFound=$false
        for ($i=0;$i -lt $lines.Count-2;$i++) {
            $cells=@(($lines[$i].Trim().Trim('|') -split '\|') | ForEach-Object {$_.Trim().Replace('`','')})
            if (($cells -join '|') -ne ($spec.columns -join '|')) { continue }
            if ($tableFound) { Add-Issue error duplicate_dimension_summary $spec.name '只能有一份当前维度统计';continue }; $tableFound=$true
            $values=@(($lines[$i+2].Trim().Trim('|') -split '\|') | ForEach-Object {$_.Trim()})
            if ($values.Count -ne $spec.columns.Count) { Add-Issue error dimension_count $spec.name '统计列数不匹配';continue }
            for ($c=0;$c -lt $values.Count;$c++) { if ($values[$c] -notmatch '^\d+$' -or [long]$values[$c] -ne $counts[$spec.columns[$c]]) { Add-Issue error dimension_count $spec.name '统计与对应状态卡片数量不一致' } }
        }
        if (-not $tableFound) { Add-Issue error missing_dimension_summary $spec.name '缺少本维度独立统计' }
        if ($text -notmatch '01-规范审查结果\.md') { Add-Issue incomplete missing_evidence_navigation $spec.name '缺少共享基线/证据入口' }
        if (-not $cards.Count -and $text -notmatch '(已检查|已核对|已读取|已分析)' ) { Add-Issue incomplete zero_without_coverage $spec.name '零项报告仍需实际检查范围与依据；未检查不可判0项通过' }
        if (-not $cards.Count -and $text -notmatch 'E-\d{3,}') { Add-Issue incomplete zero_without_evidence $spec.name '零项结论缺可回指证据' }
    }
    foreach ($id in $cardsById.Keys) {
        foreach ($ref in @([regex]::Matches((Value-Of $cardsById[$id] '关联发现'), '(?<![A-Z0-9-])[FDRG]-\d{3,}(?![A-Z0-9-])') | ForEach-Object Value)) {
            if (-not $definitions.ContainsKey($ref)) { Add-Issue error unknown_cross_finding $definitions[$id] "$id 关联不存在的 $ref" }
            if ($ref -eq $id) { Add-Issue error self_reference $definitions[$id] "$id 不能把自身作为关联发现" }
        }
    }
    $errors=@($issues | Where-Object level -eq error).Count; $incomplete=@($issues | Where-Object level -eq incomplete).Count
    $result=[ordered]@{schemaVersion=2;formatVersion='2.0.0';status=$(if($errors){'failed'}elseif($incomplete){'partial'}else{'passed'});summary=@{errors=$errors;incomplete=$incomplete;dimensions=$summaries};issues=@($issues.ToArray());limitations=@('只检查四维报告的结构、计数、声明字段与引用，不能判定缺陷真实性、抽取价值、实践优秀程度或主发现去重语义。','零项、报告齐全和工具通过均不证明全项目合规或运行验收。')}
} catch { $result=@{status='failed';summary=@{errors=1;incomplete=0};issues=@(@{level='error';code='input_or_execution_error';path=$ResultPath;message=$_.Exception.Message})} }
if ($Json) { $result | ConvertTo-Json -Depth 10 } else { "四维报告检查：$($result.status)，错误=$($result.summary.errors)，待复核=$($result.summary.incomplete)" }
if ($result.summary.errors) { exit 1 }; if ($result.summary.incomplete) { exit 2 }; exit 0
