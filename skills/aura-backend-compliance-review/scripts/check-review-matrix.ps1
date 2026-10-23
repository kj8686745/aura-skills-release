#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResultPath,
    [Parameter(Mandatory = $true)]
    [string]$MatrixPath,
    [ValidateSet('Change', 'Project')]
    [string]$Mode = 'Change',
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$rulePattern = '(?<![A-Z0-9-])AURA-[A-Z0-9-]+-[0-9]{3,}(?![A-Z0-9-])'

function Read-Utf8([string]$Path) {
    [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path)
}

function Get-Rules([string]$Text) {
    @([regex]::Matches($Text, $rulePattern) | ForEach-Object Value | Sort-Object -Unique)
}

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

$matrix = (Resolve-Path -LiteralPath $MatrixPath).Path
$matrixRules = @(Get-Rules (Read-Utf8 $matrix))
if (-not $matrixRules.Count) { throw '规范矩阵没有解析到规则 ID' }
$matrixSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($id in $matrixRules) { $null = $matrixSet.Add($id) }

$references = [Collections.Generic.List[object]]::new()
$files = @(Get-ResultFiles $ResultPath $Mode)
foreach ($file in $files) {
    $lines = (Read-Utf8 $file.path) -split "`r?`n"
    for ($index = 0; $index -lt $lines.Count; $index++) {
        foreach ($match in [regex]::Matches($lines[$index], $rulePattern)) {
            $references.Add([pscustomobject]@{
                id = $match.Value
                file = $file.name
                line = $index + 1
            })
        }
    }
}

$referencedIds = @($references.id | Sort-Object -Unique)
$unknown = @($references | Where-Object { -not $matrixSet.Contains($_.id) } | Sort-Object id, file, line)
$duplicates = @($references | Group-Object id | Where-Object Count -gt 1 | ForEach-Object {
    [pscustomobject]@{ id = $_.Name; occurrences = $_.Count }
})
$unreferenced = @($matrixRules | Where-Object { $_ -notin $referencedIds })
$result = [ordered]@{
    status = if ($unknown.Count) { 'error' } elseif (-not $referencedIds.Count) { 'incomplete' } else { 'passed' }
    mode = $Mode
    resultPath = [IO.Path]::GetFileName($ResultPath.TrimEnd([char[]]'\/'))
    matrixPath = [IO.Path]::GetFileName($matrix)
    matrixRuleCount = $matrixRules.Count
    referencedRuleCount = $referencedIds.Count
    unknownRuleCount = $unknown.Count
    duplicateReferenceCount = $duplicates.Count
    unreferencedRuleCount = $unreferenced.Count
    unknownRules = $unknown
    duplicateReferences = $duplicates
}

$result | ConvertTo-Json -Depth 8
if ($unknown.Count) { exit 1 }
if (-not $referencedIds.Count) { exit 2 }
exit 0
