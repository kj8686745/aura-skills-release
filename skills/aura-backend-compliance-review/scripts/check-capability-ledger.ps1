#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$document = Get-Content -LiteralPath (Resolve-Path -LiteralPath $InputPath).Path -Raw -Encoding UTF8 | ConvertFrom-Json
$ledger = if ($null -ne $document.capabilityReuse) { $document.capabilityReuse } else { $document }
$issues = [Collections.Generic.List[object]]::new()
$items = @($ledger.items)

if ($ledger.status -ne 'candidate-only') {
    $issues.Add([pscustomobject]@{ code = 'invalid_status'; message = '能力候选账本必须保留 candidate-only 状态' })
}
if (-not $items.Count) {
    $issues.Add([pscustomobject]@{ code = 'missing_items'; message = '未找到能力候选条目' })
}

$allowedStatuses = @('not-evaluated', 'confirmed-reuse', 'duplicate-candidate', 'not-applicable', 'unproven', 'excluded')
$capabilityIds = [Collections.Generic.HashSet[string]]::new()
foreach ($item in $items) {
    $id = [string]$item.capabilityId
    if ([string]::IsNullOrWhiteSpace($id)) {
        $issues.Add([pscustomobject]@{ code = 'missing_capability_id'; message = '候选条目缺 capabilityId' })
        continue
    }
    if (-not $capabilityIds.Add($id)) {
        $issues.Add([pscustomobject]@{ code = 'duplicate_capability_id'; capabilityId = $id; message = '能力 ID 重复' })
    }
    foreach ($field in @('publicReference', 'triggerStatus', 'signals', 'possibleDuplicateImplementations', 'reviewStatus')) {
        if ($null -eq $item.$field) {
            $issues.Add([pscustomobject]@{ code = 'missing_field'; capabilityId = $id; field = $field; message = '候选条目缺必要字段' })
        }
    }
    if ($item.reviewStatus -and $item.reviewStatus -notin $allowedStatuses) {
        $issues.Add([pscustomobject]@{ code = 'invalid_review_status'; capabilityId = $id; message = '能力复核状态不在允许集合内' })
    }
    if ($item.triggerStatus -eq 'signals-found' -and @($item.signals).Count -eq 0 -and @($item.dependencyDeclarations).Count -eq 0) {
        $issues.Add([pscustomobject]@{ code = 'signal_status_without_evidence'; capabilityId = $id; message = 'signals-found 但没有信号或依赖证据' })
    }
    foreach ($signal in @($item.signals)) {
        if ([string]::IsNullOrWhiteSpace([string]$signal.path) -or $null -eq $signal.line) {
            $issues.Add([pscustomobject]@{ code = 'incomplete_signal'; capabilityId = $id; message = '能力线索缺路径或行号' })
        }
    }
}

$result = [ordered]@{
    status = if (@($issues | Where-Object code -in @('invalid_status', 'missing_items', 'missing_capability_id', 'missing_field', 'invalid_review_status', 'signal_status_without_evidence', 'incomplete_signal')).Count) { 'failed' } else { 'passed' }
    input = [IO.Path]::GetFileName((Resolve-Path -LiteralPath $InputPath).Path)
    inputShape = if ($null -ne $document.capabilityReuse) { 'scope.capabilityReuse' } else { 'ledger' }
    capabilityCount = $items.Count
    signalCount = @($items | ForEach-Object { @($_.signals) }).Count
    duplicateCandidateCount = @($items | ForEach-Object { @($_.possibleDuplicateImplementations) }).Count
    unevaluatedCount = @($items | Where-Object reviewStatus -eq 'not-evaluated').Count
    issues = @($issues)
    limitations = @('只校验候选账本结构和证据字段，不判断能力是否真正复用、是否构成违规或运行是否生效。', 'candidate-only 和 not-evaluated 是正常初始状态，不代表能力不适用或项目不合规。')
}

$result | ConvertTo-Json -Depth 8
if ($result.status -eq 'failed') { exit 1 }
exit 0
