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

function Get-FrontendStackIssue {
  param([string]$Root)

  # 在检查 Aura 配置前确认目标是实际的 Vue 3 + Vite 包，避免把相似配置当成项目身份。
  $manifest = Join-Path $Root 'package.json'
  if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { return '缺少前端 package.json。' }
  try {
    $package = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $package -or $package -isnot [pscustomobject]) { return '前端 package.json 不是有效的包清单。' }
  } catch {
    return '无法解析前端 package.json。'
  }

  # 与正式审查的声明口径一致，仅合并直接依赖和开发依赖，不根据目录或间接依赖推断版本。
  $dependencies = @{}
  foreach ($section in @('dependencies', 'devDependencies')) {
    $property = $package.PSObject.Properties[$section]
    if ($null -ne $property -and $null -ne $property.Value) {
      foreach ($dependency in $property.Value.PSObject.Properties) { $dependencies[$dependency.Name] = [string]$dependency.Value }
    }
  }
  if ($dependencies.vue -notmatch '^[\^~= ]*3(?:\.|$)' -or [string]::IsNullOrWhiteSpace($dependencies.vite)) {
    return '无法从依赖声明确认 Vue 3 + Vite。'
  }
  return ''
}

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
$frontendStackIssue = Get-FrontendStackIssue $resolvedProjectPath
# 清单门槛未通过时保留原因，证据列表为空表示四项 Aura 文件尚未核对。
$definitionsToCheck = if (-not $frontendStackIssue) { $evidenceDefinitions }
foreach ($definition in $definitionsToCheck) {
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
# 脚本按用户要做的事给出提示。审查对象可以是已有修改，少量领域术语也不足以确认专项任务。
$federationPattern = '(模块联邦|联邦(?:配置|基线)|module\s+federation|\bmf-manifest\.json\b|远程菜单|\b(?:remotes?|exposes?)\s*(?:配置|模块)|\bshared\s+singleton\b|远程\s*(?:\S{0,12}模块\s*)?(?:remote|manifest)\b)'
$resolverContext = '(?:vite|组件|自动导入)'
$prebuildPattern = "(预构建|\b(?:optimizeDeps|auraAutoOptimizeDeps)\b|$resolverContext.{0,12}\bresolver\b|\bresolver\b.{0,12}$resolverContext|(?:调整|修改|配置|检查)\s*(?:resolver\s*配置|自动导入)|(?:新增|升级)\s*公共(?:组件|依赖))"
$firstVisitPattern = '(?:首次|第一次)(?:访问|进(?:入)?|打开|点击|切换)'
$firstMenuReload = ($normalizedTask -match "$firstVisitPattern.{0,12}菜单|菜单.{0,12}$firstVisitPattern") -and
  ($normalizedTask -match '刷新|重载|full-reload')
$reviewPattern = '(审查|审计|评审|\b(?:audit|review)\b)'
$inspectionPattern = '(检查|核查|验收|\b(?:check|inspect)\b)'
$reviewObjectPattern = '(前端|代码|规范|全部项目|全项目|六文件|结果包|\bdiff\b|这次变更|本次变更|这次修改|本次修改|\b(?:files|changes)\b)'
$frontendReviewScopePattern = '(前端\s*(?:代码|规范)|代码(?:和|与)?规范|全部项目|全项目|六文件|结果包|\bdiff\b|这次变更|本次变更|这次修改|本次修改|\b(?:files|changes)\b)'
$candidateReviewPattern = '(前端.{0,12}规范|代码.{0,6}规范|完整规范|正式审查|六文件|全项目前端)'
$consultationPattern = '(怎么拆|如何拆|拆分建议|(?:结构|拆分|测试).{0,12}(?:合理|建议)|(?:看|评估).{0,12}结构|先给建议)'
$diagnosisPattern = '(排查|诊断|定位.{0,12}(?:故障|问题|原因)|为什么|为何|什么原因|\b(?:debug|diagnose|troubleshoot|why)\b)'
$writeActionPattern = '(?:新增|添加|调整|修改|改动|改[大小为成]|修复|接入|实现|开发|删除|补齐|重构|升级|\b(?:add|change|fix|implement|update|remove|refactor)\b)'
$writeRequestPattern = "(?:^\s*(?:请|帮我|给.{1,24}?)?\s*|(?<![不勿])(?:再|然后|并且?|后再)\s*)(?:仅|只)?\s*$writeActionPattern"
$mapPattern = '(地图|\b(?:fxftmap|geojson)\b|轨迹回放|热力图|电子围栏)'
$videoPattern = '(监控视频|(?:接入|集成)\s*视频|视频(?:页面|监控|直播|回放|点播|播放|分屏|模块)|摄像头|录像回放|\b(?:fxftwebvideo|fxftwebmultivideo|ptz)\b|云台|点播)'
$isFederationTask = ($normalizedTask -match "$federationPattern|$prebuildPattern") -or $firstMenuReload
# 先处理专项目标与审查请求，保留原始范围给后续技能。范围内含 diff 等改动词也不改变审查意图。
$hasWriteRequest = $normalizedTask -match $writeRequestPattern
$negativeWritePattern = '(?:不(?:再|要|得|用)?|不能|无需|勿)(?:修改|改动|修复|整改|改)(?:(?:业务)?(?:源码|代码|配置|文件)(?!(?:之|以)?外)|(?!\p{L}))'
$reviewScopeText = $normalizedTask -replace $negativeWritePattern, ''
$isCandidateReview = ($normalizedTask -match $candidateReviewPattern) -and ($normalizedTask -match "$reviewPattern|$inspectionPattern")
# 只读由用户限制的动作决定。只限某项配置的检查或修复仍保留对应动作。
$limitedReadActionPattern = '(?:仅|只)(?:做)?(?:检查|核对|核查|审查|审计|排查|复检|报告|给建议|看)'
$isExplicitFederationScope = $normalizedTask -match "$limitedReadActionPattern\s*(?:$federationPattern|$prebuildPattern)"
$readOnlyPattern = "(只读|$limitedReadActionPattern|\bread[- ]only\b|\breport\s+only\b)"
$readOnlyStagePattern = "(改前基线|联邦基线|修(?:改|复)前.{0,6}基线|复(?:检|查|核)|先给建议|$reviewPattern)"
$hasReadOnlyConstraint = $normalizedTask -match "$readOnlyPattern|$negativeWritePattern"
$useFederationCheck = $isFederationTask -and (-not $hasWriteRequest -or $hasReadOnlyConstraint) -and
  ($firstMenuReload -or $hasReadOnlyConstraint -or ($normalizedTask -match "$inspectionPattern|$diagnosisPattern|$readOnlyStagePattern|核对|看(?:一)?下")) -and
  ($isExplicitFederationScope -or ($reviewScopeText -notmatch $frontendReviewScopePattern))
$isAuditOnly = $useFederationCheck -and ($hasReadOnlyConstraint -or ($normalizedTask -match $readOnlyStagePattern))
$isFrontendReview = -not ($hasWriteRequest -or $useFederationCheck) -and (($normalizedTask -match $reviewPattern) -or
  (($normalizedTask -match $inspectionPattern) -and ($reviewScopeText -match $reviewObjectPattern)))
$isConsultation = -not ($hasWriteRequest -or $isFrontendReview -or $useFederationCheck) -and ($normalizedTask -match $consultationPattern)
$isDiagnosis = -not ($hasWriteRequest -or $isFrontendReview -or $useFederationCheck -or $isConsultation) -and ($normalizedTask -match $diagnosisPattern)
$isMapTask = $normalizedTask -match $mapPattern
$isVideoTask = $normalizedTask -match $videoPattern
$hasAvailabilityContext = $PSBoundParameters.ContainsKey('AvailableSkills')

$recommendedSkills = @()
$unavailableSkills = @()
# 探针只判断综合端身份，框架仓库的归属由分流技能根据包与源码证据判断。
$workflow = '未识别为 AURA 综合端。已确认的 AURA 框架库按技能入口的框架分支处理，其他项目结束综合端分流。'
if ($frontendStackIssue) {
  $workflow = "$frontendStackIssue $workflow"
} elseif ($projectType -eq 'Integrated') {
  if ($isFrontendReview -or $isConsultation) {
    $recommendedSkills = @('aura-web-review')
    if ($isConsultation) { $workflow = '保留用户所指范围，进入只读结构或测试咨询。' }
    else { $workflow = '传递原请求与审查范围，由前端审查技能选择模式和交付。' }
  } elseif ($useFederationCheck) {
    $recommendedSkills = @('aura-module-federation-check')
    if ($isAuditOnly) { $workflow = '保留请求范围，执行只读模块联邦或预构建检查。' }
    else { $workflow = '先做模块联邦专项检查，补齐常规证据。按 Web 开发规范修复确定问题并复检。有实质方案取舍时列出选项。' }
  } else {
    $recommendedSkills = @('aura-web-develop')
    if ($isMapTask) { $recommendedSkills += 'fmap-2d' }
    if ($isVideoTask) { $recommendedSkills += 'fxft-video' }
    if ($isFederationTask) {
      $recommendedSkills += 'aura-module-federation-check'
    }
    if ($isDiagnosis) {
      $workflow = '按用户范围排查业务故障并给出原因及证据，修复另按用户授权处理。'
    } elseif ($isFederationTask) {
      $workflow = 'Web 开发主导实现；模块联邦检查技能负责改前基线与改后复检。'
    } elseif ($isMapTask -or $isVideoTask) {
      $workflow = 'Web 开发主导业务实现；已命中的可用地图或视频技能提供专项规范。'
    } else {
      $workflow = '进入 PIGX 综合端业务开发流程。'
    }
    if ($hasWriteRequest -and ($normalizedTask -match "$reviewPattern|$inspectionPattern|$diagnosisPattern")) {
      $workflow += ' 按原请求保留明确的排查、检查或验收阶段。'
    }
  }
} elseif ($projectType -eq 'IncompleteCandidate') {
  if ($isFrontendReview -and $isCandidateReview -and $hasAuraEvidence) {
    $recommendedSkills = @('aura-web-review')
    $workflow = '已有 Aura 专有证据且明确要求规范审查；传递原请求和范围，由审查技能按所选模式取证并报告缺项。'
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
  frontendStackIssue = $frontendStackIssue
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
