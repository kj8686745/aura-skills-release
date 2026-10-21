# PIGX 综合端只读识别与任务分流

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath,
  [string]$TaskDescription = '',
  [string[]]$AvailableSkills = @(),
  [switch]$Json
)

$ErrorActionPreference = 'Stop'
$resolvedProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
$availableSkillSet = @($AvailableSkills | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })

function Test-FileContains {
  param([string]$Path, [string]$Pattern)
  return (Test-Path -LiteralPath $Path -PathType Leaf) -and
    ((Get-Content -LiteralPath $Path -Raw -Encoding UTF8) -match $Pattern)
}

$evidenceDefinitions = @(
  @{ Key = 'currentRemoteConfig'; Label = 'currentRemoteConfig 综合端基础配置'; Path = 'src/config/moduleFederationBaseConfig.ts'; Pattern = '\bcurrentRemoteConfig\b' },
  @{ Key = 'exposeModules'; Label = 'exposeModules 标准聚合入口'; Path = 'src/hooks/moduleFederation.ts'; Pattern = '\bexposeModules\b' },
  @{ Key = 'runtimeBinding'; Label = 'config/aura/federation 公共包运行时绑定'; Path = 'src/config/aura/federation.ts'; Pattern = '@fxft/aura-web-kit/federation' },
  @{ Key = 'viteFederation'; Label = '@module-federation/vite 的 federation() 配置'; Path = 'vite.config.*'; Pattern = '' }
)

$matched = [System.Collections.Generic.List[string]]::new()
$missing = [System.Collections.Generic.List[string]]::new()
$hasAuraEvidence = $false
foreach ($definition in $evidenceDefinitions) {
  $isMatched = $false
  if ($definition.Key -eq 'viteFederation') {
    foreach ($extension in @('ts', 'js', 'mts', 'mjs', 'cts', 'cjs')) {
      $vitePath = Join-Path $resolvedProjectPath ('vite.config.' + $extension)
      if ((Test-FileContains $vitePath '@module-federation/vite') -and (Test-FileContains $vitePath '\bfederation\s*\(')) { $isMatched = $true }
    }
  } else {
    $isMatched = Test-FileContains -Path (Join-Path $resolvedProjectPath $definition.Path) -Pattern $definition.Pattern
  }

  if ($isMatched) {
    [void]$matched.Add($definition.Label)
    if ($definition.Key -ne 'viteFederation') { $hasAuraEvidence = $true }
  }
  else { [void]$missing.Add($definition.Label) }
}

$projectType = if ($matched.Count -eq $evidenceDefinitions.Count) { 'Integrated' }
elseif ($matched.Count -eq 0) { 'NotPIGX' }
else { 'IncompleteCandidate' }

$normalizedTask = $TaskDescription.ToLowerInvariant()
$federationPattern = '(remote|expose|manifest|远程菜单|shared|运行时入口|模块联邦|联邦配置)'
$auditPattern = '(检查|审查|审计|评审|验收|排查|audit|review|inspect)'
$implementationPattern = '(开发|修改|新增|修复|接入|实现|create|add|change|configure|fix|implement)'
$mapPattern = '(二维地图|2d\s*地图|地图|点位|marker|聚合|轨迹回放|热力图|绘制|geojson|电子围栏)'
$videoPattern = '(监控视频|视频|摄像头|单路|多路|录像回放|点播|ptz|云台|分屏|拖拽换位|全屏)'
$isFederationTask = $normalizedTask -match $federationPattern
$intentText = $normalizedTask -replace '不(?:修改|新增|修复|开发|接入|实现)(?:业务)?(?:代码|源码|配置)?', ''
$isReviewRequest = ($normalizedTask -match $auditPattern) -and -not ($intentText -match $implementationPattern)
$isFrontendReview = $isReviewRequest -and (($intentText -match '(前端|代码|规范|全项目|结果包|code\s*review)') -or -not $isFederationTask) -and -not ($normalizedTask -match '(?:仅|只)(?:做|检查|审查|审计)?\s*模块联邦')
$isAuditOnly = $isFederationTask -and $isReviewRequest -and -not $isFrontendReview
$isMapTask = $normalizedTask -match $mapPattern
$isVideoTask = $normalizedTask -match $videoPattern
$hasAvailabilityContext = $PSBoundParameters.ContainsKey('AvailableSkills')

$recommendedSkills = @()
$unavailableSkills = @()
$workflow = '退出，不接管该项目。'
if ($projectType -eq 'Integrated') {
  if ($isFrontendReview) {
    $recommendedSkills = @('aura-web-review')
    $workflow = '按随包最新前端规范只读审查并生成六文件结果包。'
  } elseif ($isAuditOnly) {
    $recommendedSkills = @('aura-module-federation-check')
    $workflow = '只读模块联邦检查。'
  } else {
    $recommendedSkills = @('aura-web-develop')
    $specializedSkills = @()
    if ($isMapTask) { $specializedSkills += 'fmap-2d' }
    if ($isVideoTask) { $specializedSkills += 'fxft-video' }
    foreach ($specializedSkill in $specializedSkills) {
      $recommendedSkills += $specializedSkill
    }
    if ($isFederationTask) {
      $recommendedSkills += 'aura-module-federation-check'
      $workflow = 'Web 开发主导实现；模块联邦检查技能负责改前基线与改后复检。'
    } elseif ($specializedSkills.Count -gt 0) {
      $workflow = 'Web 开发主导业务实现；已命中的可用地图或视频技能提供专项规范。'
    } else {
      $workflow = '进入 PIGX 综合端业务开发流程。'
    }
  }
} elseif ($projectType -eq 'IncompleteCandidate') {
  if ($isFrontendReview -and $hasAuraEvidence) {
    $recommendedSkills = @('aura-web-review')
    $workflow = '已有 Aura 专有证据且明确要求规范审查；使用 ReviewCandidate 盘点，按最新规范取证报告缺项，不恢复旧副本。'
  } else {
    $workflow = '仅报告缺失证据；业务开发仍需确认完整综合端身份，不因单一模块联邦特征接管。'
  }
}

if ($hasAvailabilityContext -and $recommendedSkills.Count -gt 0) {
  $desiredSkills = @($recommendedSkills)
  $recommendedSkills = @($desiredSkills | Where-Object { $availableSkillSet -contains $_ })
  $unavailableSkills = @($desiredSkills | Where-Object { $availableSkillSet -notcontains $_ })
  if ($unavailableSkills.Count -gt 0) {
    $workflow += " 缺少技能：$($unavailableSkills -join '、')；必须提示用户是否安装，未经明确授权不得安装。"
  }
}

$unavailableSpecializedSkills = @($unavailableSkills | Where-Object { $_ -in @('fmap-2d', 'fxft-video') })

$result = [pscustomobject]@{
  projectType = $projectType
  matchedEvidence = @($matched)
  missingEvidence = @($missing)
  isFederationTask = $isFederationTask
  isAuditOnly = $isAuditOnly
  isMapTask = $isMapTask
  isVideoTask = $isVideoTask
  recommendedSkills = $recommendedSkills
  unavailableSkills = $unavailableSkills
  unavailableSpecializedSkills = $unavailableSpecializedSkills
  workflow = $workflow
}

if ($Json) { $result | ConvertTo-Json -Depth 4; exit 0 }

Write-Host "项目类型：$projectType"
Write-Host "已命中：$($matched -join '；')"
if ($missing.Count -gt 0) { Write-Host "缺失：$($missing -join '；')" }
Write-Host "建议：$workflow"
if ($recommendedSkills.Count -gt 0) { Write-Host "加载技能：$($recommendedSkills -join '、')" }
if ($unavailableSkills.Count -gt 0) { Write-Host "缺少技能：$($unavailableSkills -join '、')；请提示用户是否安装。用户拒绝或安装失败后，再按可降级/必需边界处理。" }
