#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$LedgerPath,
    [Parameter(Mandatory = $true)][string]$ResultPath,
    [ValidateSet('Change', 'Project')][string]$Mode = 'Change',
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

function Normalize-Cell([string]$Value) { $Value.Trim().Replace('`', '').Replace('**', '') }
function Get-Cells([string]$Line) {
    @($Line.Trim().Trim('|') -split '(?<!\\)\|' | ForEach-Object { Normalize-Cell $_ })
}
function Test-Basis([string]$Value) {
    $value = Normalize-Cell $Value
    return $value -and $value -notmatch '^(?:[-—?？/]+|无|暂无|无依据|待补充|待核对|待确认|待评估|未评估|不详|未知|N/?A|TBD|编号)$'
}
function Remove-Examples([string]$Text) {
    # Preserve line numbers, including for unclosed comments/fences. Ignore fences inside comments.
    $text = [regex]::Replace($Text, '(?s)<!--.*?(?:-->|\z)', { param($m) [regex]::Replace($m.Value, '[^\r\n]', ' ') })
    $fence = ''; $length = 0
    $clean = foreach ($line in ($text -split '\r?\n')) {
        if ($fence) {
            if ($line -match ('^ {0,3}' + [regex]::Escape($fence) + '{' + $length + ',}[ \t]*$')) { $fence = '' }
            ''
        } elseif ($line -match '^ {0,3}(?<fence>`{3,}|~{3,})') {
            $fence = $Matches.fence.Substring(0, 1); $length = $Matches.fence.Length
            ''
        } elseif ($line -match '^(?: {4}|\t)') { '' }
        else { $line }
    }
    $clean -join "`n"
}
function Read-Tables([string]$Text, [string]$Path) {
    $lines = $Text -split '\r?\n'
    for ($i = 0; $i -lt $lines.Count - 1; $i++) {
        if ($lines[$i] -notmatch '^ {0,3}\|' -or $lines[$i + 1] -notmatch '^ {0,3}\|[\s:|\-]+\|\s*$') { continue }
        $headers = @(Get-Cells $lines[$i]); $separator = @(Get-Cells $lines[$i + 1])
        if ($separator.Count -ne $headers.Count -or @($separator | Where-Object { $_ -notmatch '^:?-{3,}:?$' }).Count) { continue }
        $rows = [Collections.Generic.List[object]]::new(); $j = $i + 2
        while ($j -lt $lines.Count -and $lines[$j] -match '^ {0,3}\|') {
            # Keep malformed rows: another valid row for the same package cannot conceal them.
            $rows.Add(@{ cells = @(Get-Cells $lines[$j]); line = $j + 1 })
            $j++
        }
        @{ headers = $headers; rows = $rows.ToArray(); path = $Path }
        $i = $j - 1
    }
}
function Find-Column($Table, [string]$Pattern) {
    for ($i = 0; $i -lt $Table.headers.Count; $i++) { if ($Table.headers[$i] -match $Pattern) { return $i } }
    return -1
}
function Get-References([string]$Text) {
    @([regex]::Matches($Text, '(?<![A-Za-z0-9-])[EFC]-\d{3,}(?![A-Za-z0-9-])') | ForEach-Object Value | Sort-Object -Unique)
}
function Get-Capabilities([string]$Text) {
    @([regex]::Matches($Text, '(?<![A-Za-z0-9-])AURA-CAP-[A-Z0-9]+(?:-[A-Z0-9]+)*(?![A-Za-z0-9-])') | ForEach-Object Value | Sort-Object -Unique)
}

$ledgerDocument = Get-Content -LiteralPath (Resolve-Path -LiteralPath $LedgerPath).Path -Raw -Encoding UTF8 | ConvertFrom-Json
$ledger = if ($null -ne $ledgerDocument.capabilityReuse) { $ledgerDocument.capabilityReuse } else { $ledgerDocument }
if ($null -eq $ledger -or $ledger.items -isnot [array]) { throw '候选账本必须包含 items 数组（或 scope.capabilityReuse.items）' }
$items = @($ledger.items)
$ledgerIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($item in $items) {
    $id = [string]$item.capabilityId
    if ($id -cnotmatch '^AURA-CAP-[A-Z0-9]+(?:-[A-Z0-9]+)*$' -or -not $ledgerIds.Add($id)) { throw "候选账本能力编号无效或重复：$id" }
}

$resultResolved = (Resolve-Path -LiteralPath $ResultPath).Path
$texts = [ordered]@{}; $inputIssues = [Collections.Generic.List[object]]::new()
if ($Mode -eq 'Change') {
    if (-not (Test-Path -LiteralPath $resultResolved -PathType Leaf) -or [IO.Path]::GetExtension($resultResolved) -ne '.md') { throw 'Change 模式要求一个 Markdown 报告文件' }
    $texts[$resultResolved] = Remove-Examples ([IO.File]::ReadAllText($resultResolved))
} else {
    if (-not (Test-Path -LiteralPath $resultResolved -PathType Container)) { throw 'Project 模式要求结果包目录' }
    foreach ($name in @('00-结果包说明.md', '01-审查报告.md', '02-规则核查矩阵.md', '03-证据与执行记录.md', '04-整改与复核清单.md', '05-扫描候选与判定.md')) {
        $path = Join-Path $resultResolved $name
        if (Test-Path -LiteralPath $path -PathType Leaf) { $texts[$path] = Remove-Examples ([IO.File]::ReadAllText($path)) }
        else { $inputIssues.Add(@{ code = 'missing_file'; path = $path; message = '缺少标准结果包文件' }) }
    }
}

$tables = @(foreach ($path in $texts.Keys) { Read-Tables $texts[$path] $path })
$definitions = @{}; $rowsById = @{}
foreach ($table in $tables) {
    $capabilityColumn = Find-Column $table '^能力包\s*/\s*编号$'
    if ($capabilityColumn -ge 0) {
        # The evidence file's inventory (证据与状态) is not the human classification ledger.
        if ((Find-Column $table '^状态$') -lt 0 -and (Find-Column $table '^E\s*/\s*F\s*/\s*C\s*编号$') -lt 0) { continue }
        foreach ($row in $table.rows) {
            if ($row.cells.Count -le $capabilityColumn) { continue }
            foreach ($id in (Get-Capabilities $row.cells[$capabilityColumn])) {
                if (-not $rowsById.ContainsKey($id)) { $rowsById[$id] = [Collections.Generic.List[object]]::new() }
                $rowsById[$id].Add(@{ table = $table; row = $row })
            }
        }
        continue
    }
    # Prose, capability rows and rectification tables contain references, not definitions.
    $definitionColumn = Find-Column $table '^(?:证据|候选)\s*ID$'
    if ($definitionColumn -lt 0) { continue }
    $prefix = if ($table.headers[$definitionColumn] -match '^证据') { 'E' } else { 'C' }
    foreach ($row in $table.rows) {
        if ($row.cells.Count -ne $table.headers.Count) { continue }
        $id = $row.cells[$definitionColumn]
        if ($id -cnotmatch ('^' + $prefix + '-\d{3,}$')) { continue }
        $details = @($row.cells | Select-Object -Skip ($definitionColumn + 1))
        if (-not @($details | Where-Object { Test-Basis $_ }).Count) { continue }
        if (-not $definitions.ContainsKey($id)) { $definitions[$id] = [Collections.Generic.List[string]]::new() }
        $definitions[$id].Add(($row.cells -join ' '))
    }
}
foreach ($text in $texts.Values) {
    foreach ($match in [regex]::Matches($text, '(?m)^ {0,3}#{1,6}[ \t]+(?<id>F-\d{3,})[：: \t]+(?<title>[^\r\n]+)\r?$(?:\n(?<body>(?:(?!^ {0,3}#{1,6}[ \t]).*(?:\n|$))*))?')) {
        $id = $match.Groups['id'].Value
        if (-not (Test-Basis $match.Groups['title'].Value) -or -not (Test-Basis $match.Groups['body'].Value)) { continue }
        if (-not $definitions.ContainsKey($id)) { $definitions[$id] = [Collections.Generic.List[string]]::new() }
        $definitions[$id].Add($match.Value)
    }
}

$reportIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($id in (Get-Capabilities ($texts.Values -join "`n"))) { $null = $reportIds.Add($id) }
$missing = [Collections.Generic.List[object]]::new(); $unclassified = [Collections.Generic.List[object]]::new()
foreach ($item in $items) {
    $id = [string]$item.capabilityId
    if (-not $reportIds.Contains($id)) {
        $missing.Add([pscustomobject]@{ capabilityId = $id; triggerStatus = [string]$item.triggerStatus; reviewStatus = [string]$item.reviewStatus })
        continue
    }
    $problems = [Collections.Generic.List[string]]::new()
    if (-not $rowsById.ContainsKey($id)) { $problems.Add('缺少结构化能力账本行') }
    else {
        foreach ($entry in $rowsById[$id]) {
            $table = $entry.table; $row = $entry.row; $location = "$($table.path):$($row.line)"
            $stateColumn = Find-Column $table '^状态$'
            $basisColumn = Find-Column $table '触发.*依据'
            $referenceColumn = Find-Column $table '^E\s*/\s*F\s*/\s*C\s*编号$'
            if ($row.cells.Count -ne $table.headers.Count) { $problems.Add("${location}：表格列数不完整"); continue }
            if ($stateColumn -lt 0 -or $row.cells[$stateColumn] -cnotmatch '^(复用|重复实现|未证实|不适用)$') { $problems.Add("${location}：缺少唯一人工状态") }
            if ($basisColumn -lt 0 -or -not (Test-Basis $row.cells[$basisColumn])) { $problems.Add("${location}：缺少触发/不适用依据") }
            $references = if ($referenceColumn -ge 0) { @(Get-References $row.cells[$referenceColumn]) } else { @() }
            if (-not $references.Count) { $problems.Add("${location}：缺少可解析 E/F/C 回指"); continue }
            # Follow this row's references, including supporting F/C records. Never open linked files.
            $queue = [Collections.Generic.Queue[string]]::new(); $visited = [Collections.Generic.HashSet[string]]::new()
            foreach ($reference in $references) { $queue.Enqueue($reference) }
            while ($queue.Count) {
                $reference = $queue.Dequeue()
                if (-not $visited.Add($reference)) { continue }
                if (-not $definitions.ContainsKey($reference)) { $problems.Add("${location}：引用未定义的 $reference"); continue }
                if ($definitions[$reference].Count -gt 1) { $problems.Add("${location}：$reference 存在多份定义，需人工消歧") }
                foreach ($definition in $definitions[$reference]) { foreach ($nested in (Get-References $definition)) { $queue.Enqueue($nested) } }
            }
        }
    }
    if ($problems.Count) { $unclassified.Add([pscustomobject]@{ capabilityId = $id; message = $problems -join '；' }) }
}

$result = [ordered]@{
    status = if ($missing.Count -or $unclassified.Count -or $inputIssues.Count) { 'partial' } else { 'passed' }
    mode = $Mode
    ledgerCapabilityCount = $items.Count
    reportCapabilityCount = $items.Count - $missing.Count
    missingCapabilityCount = $missing.Count
    unclassifiedCapabilityCount = $unclassified.Count
    missingCapabilities = @($missing.ToArray())
    unclassifiedCapabilities = @($unclassified.ToArray())
    limitations = @('只检查报告中能力账本的逐行人工分类、依据及 E/F/C 定义与回指；passed 不证明能力复用结论真实、项目合规或运行验收。', '未证实是有效人工分类；原始 candidate-only/not-evaluated 候选账本保持只读。', 'Change 仅读取指定报告；Project 仅读取标准六文件；代码围栏、注释、链接目标和额外文件不作为结论或编号定义。')
    inputIssues = @($inputIssues.ToArray())
}
$result | ConvertTo-Json -Depth 8
if ($result.status -eq 'partial') { exit 2 }
exit 0
