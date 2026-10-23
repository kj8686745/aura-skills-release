#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$LedgerPath,
    [Parameter(Mandatory = $true)]
    [string]$ResultPath,
    [ValidateSet('Change', 'Project')]
    [string]$Mode = 'Change',
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$ledgerDocument = Get-Content -LiteralPath (Resolve-Path -LiteralPath $LedgerPath).Path -Raw -Encoding UTF8 | ConvertFrom-Json
$ledger = if ($null -ne $ledgerDocument.capabilityReuse) { $ledgerDocument.capabilityReuse } else { $ledgerDocument }
$items = @($ledger.items)

$resultResolved = (Resolve-Path -LiteralPath $ResultPath).Path
if ($Mode -eq 'Change') {
    if (-not (Test-Path -LiteralPath $resultResolved -PathType Leaf)) { throw 'Change 模式要求一个报告文件' }
    $texts = @([IO.File]::ReadAllText($resultResolved))
} else {
    if (-not (Test-Path -LiteralPath $resultResolved -PathType Container)) { throw 'Project 模式要求结果包目录' }
    $texts = @(Get-ChildItem -LiteralPath $resultResolved -File -Filter '*.md' | ForEach-Object { [IO.File]::ReadAllText($_.FullName) })
}
$reportText = $texts -join "`n"
$missing = [Collections.Generic.List[object]]::new()
$unclassified = [Collections.Generic.List[object]]::new()
foreach ($item in $items) {
    $id = [string]$item.capabilityId
    if ([string]::IsNullOrWhiteSpace($id)) { continue }
    if ($reportText -notmatch [regex]::Escape($id)) {
        $missing.Add([pscustomobject]@{ capabilityId = $id; triggerStatus = [string]$item.triggerStatus; reviewStatus = [string]$item.reviewStatus })
        continue
    }
    if ([string]$item.reviewStatus -eq 'not-evaluated' -and [string]$item.triggerStatus -eq 'signals-found') {
        $unclassified.Add([pscustomobject]@{ capabilityId = $id; message = '候选已进入报告，但仍需在能力复用账本中补充人工结论和 E/F/C 回指' })
    }
}

$result = [ordered]@{
    status = if ($missing.Count -or $unclassified.Count) { 'partial' } else { 'passed' }
    mode = $Mode
    ledgerCapabilityCount = $items.Count
    reportCapabilityCount = $items.Count - $missing.Count
    missingCapabilityCount = $missing.Count
    unclassifiedCapabilityCount = $unclassified.Count
    missingCapabilities = @($missing)
    unclassifiedCapabilities = @($unclassified)
    limitations = @('只检查候选账本中的能力 ID 是否进入结果包及是否仍标记未评估，不判断复用结论的真实性。', '不适用或未触发能力也必须保留触发依据；本工具不要求为未触发专项能力创建报告行。')
}

$result | ConvertTo-Json -Depth 8
if ($result.status -eq 'partial') { exit 2 }
exit 0
