#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResultPath,
    [ValidateSet('Change', 'Project')]
    [string]$Mode = 'Change',
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

function Get-ResultFiles([string]$Path, [string]$SelectedMode) {
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if ($SelectedMode -eq 'Change') {
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf) -or [IO.Path]::GetExtension($resolved) -ne '.md') {
            throw 'Change 模式要求一个 Markdown 报告文件'
        }
        return @([pscustomobject]@{ path = $resolved; name = [IO.Path]::GetFileName($resolved) })
    }
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
        throw 'Project 模式要求结果包目录'
    }
    $files = @(Get-ChildItem -LiteralPath $resolved -File -Filter '*.md' | Sort-Object Name)
    if (-not $files.Count) { throw '结果包目录没有 Markdown 文件' }
    return @($files | ForEach-Object { [pscustomobject]@{ path = $_.FullName; name = $_.Name } })
}

$findings = [Collections.Generic.List[object]]::new()
$boundaryHints = [Collections.Generic.List[object]]::new()
$secretPatterns = @(
    @{ code = 'private_key_block'; pattern = '(?i)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----' },
    @{ code = 'credential_url'; pattern = '(?i)\b[a-z][a-z0-9+.-]*://[^\s/]+:[^\s/@]+@' },
    @{ code = 'credential_assignment'; pattern = '(?i)\b(password|passwd|secret|access[_-]?token|refresh[_-]?token|api[_-]?key)\s*[:=]\s*["''`]?[^\s,"''`]{8,}' }
)
$boundaryPatterns = @(
    @{ code = 'external_cache_or_jar'; pattern = '(?i)(\.m2[\\/]|\.gradle[\\/]caches|[^\s`"'']+\.jar\b)' },
    @{ code = 'decompiled_or_neighbor_source'; pattern = '(?i)(反编译源码|SDK\s*内部源码|邻仓库|neighboring repository)' }
)

foreach ($file in @(Get-ResultFiles $ResultPath $Mode)) {
    $lines = [IO.File]::ReadAllLines($file.path)
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        foreach ($rule in $secretPatterns) {
            if ($line -match $rule.pattern) {
                $findings.Add([pscustomobject]@{ code = $rule.code; file = $file.name; line = $index + 1; severity = 'error' })
            }
        }
        foreach ($rule in $boundaryPatterns) {
            if ($line -match $rule.pattern) {
                $boundaryHints.Add([pscustomobject]@{ code = $rule.code; file = $file.name; line = $index + 1; severity = 'review' })
            }
        }
    }
}

$result = [ordered]@{
    status = if ($findings.Count) { 'failed' } elseif ($boundaryHints.Count) { 'partial' } else { 'passed' }
    mode = $Mode
    filesScanned = @((Get-ResultFiles $ResultPath $Mode)).Count
    secretFindingCount = $findings.Count
    boundaryHintCount = $boundaryHints.Count
    findings = @($findings)
    boundaryHints = @($boundaryHints)
    limitations = @(
        '只识别明显凭据模式和审查范围边界线索，不是通用秘密扫描器。',
        '命中边界线索只要求人工确认证据是否越过当前项目，不自动判定业务违规。',
        '输出不回显原始行或命中值，避免扫描工具扩大敏感信息暴露。'
    )
}

$result | ConvertTo-Json -Depth 8
if ($findings.Count) { exit 1 }
if ($boundaryHints.Count) { exit 2 }
exit 0
