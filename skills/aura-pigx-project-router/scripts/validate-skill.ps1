# PIGX 项目分流技能结构与脚本校验

[CmdletBinding()]
param([string]$SkillPath = (Join-Path $PSScriptRoot '..'))

$ErrorActionPreference = 'Stop'
$errors = [System.Collections.Generic.List[string]]::new()
$root = (Resolve-Path -LiteralPath $SkillPath).Path
$required = @('VERSION', 'SKILL.md', 'agents/openai.yaml', 'scripts/detect-pigx-project.ps1', 'scripts/test-detect-pigx-project.ps1')
foreach ($relativePath in $required) {
  if (-not (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf)) { [void]$errors.Add("缺少必要文件：$relativePath") }
}

$version = if (Test-Path -LiteralPath (Join-Path $root 'VERSION')) { (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim() } else { '' }
if ($version -notmatch '^\d+\.\d+\.\d+$') { [void]$errors.Add('VERSION 必须使用语义化版本号。') }
$skillPath = Join-Path $root 'SKILL.md'
if (Test-Path -LiteralPath $skillPath) {
  $content = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
  if ($content -notmatch '(?m)^name:\s*aura-pigx-project-router\s*$') { [void]$errors.Add('SKILL.md name 不正确。') }
  if ($content -notmatch '(?m)^description:\s*\S.+$') { [void]$errors.Add('SKILL.md description 不能为空。') }
  if ($version -and -not $content.Contains("当前版本：``$version``")) { [void]$errors.Add('SKILL.md 展示版本与 VERSION 不一致。') }
  foreach ($keyword in @('currentRemoteConfig', 'exposeModules', 'getModuleFederationLoader', '@module-federation/vite', 'NotPIGX', 'IncompleteCandidate')) {
    if (-not $content.Contains($keyword)) { [void]$errors.Add("SKILL.md 缺少分流关键字：$keyword") }
  }
}

$openAiPath = Join-Path $root 'agents/openai.yaml'
if ((Test-Path -LiteralPath $openAiPath) -and -not ((Get-Content -LiteralPath $openAiPath -Raw -Encoding UTF8).Contains('$aura-pigx-project-router'))) { [void]$errors.Add('agents/openai.yaml 默认提示未引用技能名。') }

Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {
  $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { [void]$errors.Add("文件包含 UTF-8 BOM：$($_.FullName.Substring($root.Length + 1))") }
}

Get-ChildItem -LiteralPath (Join-Path $root 'scripts') -File -Filter '*.ps1' | ForEach-Object {
  $tokens = $null; $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
  foreach ($parseError in $parseErrors) { [void]$errors.Add("PowerShell 语法错误：$($_.Name):$($parseError.Extent.StartLineNumber) $($parseError.Message)") }
}

foreach ($errorItem in $errors) { Write-Host "✗ $errorItem" -ForegroundColor Red }
if ($errors.Count -gt 0) { exit 1 }
Write-Host "✓ aura-pigx-project-router $version 技能校验通过。" -ForegroundColor Green
