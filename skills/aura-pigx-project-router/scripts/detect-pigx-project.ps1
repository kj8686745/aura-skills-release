# PIGX 综合端只读识别与任务分流

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath,
  [string]$TaskDescription = '',
  [switch]$Json
)

$ErrorActionPreference = 'Stop'
$resolvedProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path

function Test-FileContains {
  param([string]$Path, [string]$Pattern)
  return (Test-Path -LiteralPath $Path -PathType Leaf) -and
    ((Get-Content -LiteralPath $Path -Raw -Encoding UTF8) -match $Pattern)
}

$evidenceDefinitions = @(
  @{ Key = 'currentRemoteConfig'; Label = 'currentRemoteConfig 综合端基础配置'; Path = 'src/config/moduleFederationBaseConfig.ts'; Pattern = '\bcurrentRemoteConfig\b' },
  @{ Key = 'exposeModules'; Label = 'exposeModules 标准聚合入口'; Path = 'src/hooks/moduleFederation.ts'; Pattern = '\bexposeModules\b' },
  @{ Key = 'getModuleFederationLoader'; Label = 'getModuleFederationLoader 运行时注册表'; Path = 'src/utils/moduleFederationRegistry.ts'; Pattern = '\bgetModuleFederationLoader\b' },
  @{ Key = 'viteFederation'; Label = '@module-federation/vite 的 federation() 配置'; Path = 'vite.config.*'; Pattern = '' }
)

$matched = [System.Collections.Generic.List[string]]::new()
$missing = [System.Collections.Generic.List[string]]::new()
foreach ($definition in $evidenceDefinitions) {
  $isMatched = $false
  if ($definition.Key -eq 'viteFederation') {
    $viteFiles = @(Get-ChildItem -LiteralPath $resolvedProjectPath -File -Filter 'vite.config.*' -ErrorAction SilentlyContinue)
    $viteContent = ($viteFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"
    $isMatched = $viteContent -match '@module-federation/vite' -and $viteContent -match '\bfederation\s*\('
  } else {
    $isMatched = Test-FileContains -Path (Join-Path $resolvedProjectPath $definition.Path) -Pattern $definition.Pattern
  }

  if ($isMatched) { [void]$matched.Add($definition.Label) }
  else { [void]$missing.Add($definition.Label) }
}

$projectType = if ($matched.Count -eq $evidenceDefinitions.Count) { 'Integrated' }
elseif ($matched.Count -eq 0) { 'NotPIGX' }
else { 'IncompleteCandidate' }

$normalizedTask = $TaskDescription.ToLowerInvariant()
$federationPattern = '(remote|expose|manifest|远程菜单|shared|运行时入口|模块联邦|联邦配置)'
$auditPattern = '(检查|审计|评审|验收|排查|audit|review|inspect)'
$implementationPattern = '(开发|修改|新增|修复|接入|实现|create|add|change|configure|fix|implement)'
$isFederationTask = $normalizedTask -match $federationPattern
$isAuditOnly = ($normalizedTask -match $auditPattern) -and -not ($normalizedTask -match $implementationPattern)

$recommendedSkills = @()
$workflow = '退出，不接管该项目。'
if ($projectType -eq 'Integrated') {
  if ($isAuditOnly) {
    $recommendedSkills = @('aura-pigx-module-federation-check')
    $workflow = '只读模块联邦检查。'
  } elseif ($isFederationTask) {
    $recommendedSkills = @('aura-pigx-web-develop', 'aura-pigx-module-federation-check')
    $workflow = 'Web 开发主导实现；修改前运行检查技能做基线，修改后再次运行做复检。'
  } else {
    $recommendedSkills = @('aura-pigx-web-develop')
    $workflow = '进入 PIGX 综合端业务开发流程。'
  }
} elseif ($projectType -eq 'IncompleteCandidate') {
  $workflow = '仅报告缺失证据；用户明确要求建设为 PIGX 综合端时才进入 PIGX 开发流程。'
}

$result = [pscustomobject]@{
  projectType = $projectType
  matchedEvidence = @($matched)
  missingEvidence = @($missing)
  isFederationTask = $isFederationTask
  isAuditOnly = $isAuditOnly
  recommendedSkills = $recommendedSkills
  workflow = $workflow
}

if ($Json) { $result | ConvertTo-Json -Depth 4; exit 0 }

Write-Host "项目类型：$projectType"
Write-Host "已命中：$($matched -join '；')"
if ($missing.Count -gt 0) { Write-Host "缺失：$($missing -join '；')" }
Write-Host "建议：$workflow"
if ($recommendedSkills.Count -gt 0) { Write-Host "加载技能：$($recommendedSkills -join '、')" }
