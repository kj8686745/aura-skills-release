# 分流器三类项目与正反例回归测试

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$detector = Join-Path $PSScriptRoot 'detect-pigx-project.ps1'
$powerShellExe = (Get-Process -Id $PID).Path
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("aura-pigx-router-" + [guid]::NewGuid().ToString('N'))
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Write-FixtureFile {
  param([string]$Root, [string]$RelativePath, [string]$Content)
  $path = Join-Path $Root $RelativePath
  New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
  [System.IO.File]::WriteAllText($path, $Content, $utf8NoBom)
}

function Invoke-Detector {
  param([string]$ProjectPath, [string]$Task, [string[]]$AvailableSkills)
  $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $detector, '-ProjectPath', $ProjectPath, '-TaskDescription', $Task, '-Json')
  if ($PSBoundParameters.ContainsKey('AvailableSkills')) {
    $arguments += '-AvailableSkills'
    # 5.1 启动子进程时丢弃空字符串；逗号经脚本拆分/Trim 后仍表示空集合。
    $arguments += $(if ($AvailableSkills.Count) { $AvailableSkills -join ',' } else { ',' })
  }
  $output = & $powerShellExe @arguments
  if ($LASTEXITCODE -ne 0) { throw "识别脚本退出码错误：$LASTEXITCODE" }
  return (($output -join "`n") | ConvertFrom-Json)
}

function Assert-Equal {
  param($Actual, $Expected, [string]$Message)
  if ($Actual -ne $Expected) { throw "$Message，期望 $Expected，实际 $Actual。" }
}

function Assert-Skills {
  param([object[]]$Actual, [string[]]$Expected, [string]$Message)
  $actualText = @($Actual) -join ','
  $expectedText = @($Expected) -join ','
  if ($actualText -ne $expectedText) { throw "$Message，期望 $expectedText，实际 $actualText。" }
}

New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
  $integrated = Join-Path $testRoot 'integrated'
  $vueViteManifest = '{"dependencies":{"vue":"^3.5.0"},"devDependencies":{"vite":"^6.0.0"}}'
  Write-FixtureFile $integrated 'package.json' $vueViteManifest
  Write-FixtureFile $integrated 'src/config/moduleFederationBaseConfig.ts' 'export const currentRemoteConfig = {};'
  Write-FixtureFile $integrated 'src/hooks/moduleFederation.ts' 'export const exposeModules = {};'
  Write-FixtureFile $integrated 'src/config/aura/federation.ts' "export * from '@fxft/aura-web-kit/federation';"
  Write-FixtureFile $integrated 'vite.config.ts' "import { federation } from '@module-federation/vite'; federation({});"
  $result = Invoke-Detector $integrated '新增订单 CRUD 页面和正式菜单按钮'
  Assert-Equal $result.projectType 'Integrated' 'PIGX 综合端识别失败'
  Assert-Equal $result.recommendedSkills[0] 'aura-web-develop' 'PIGX CRUD 未分流到 Web 开发技能'
  $result = Invoke-Detector $integrated '新增正式菜单和 v-auth 按钮权限'
  Assert-Equal $result.recommendedSkills[0] 'aura-web-develop' '正式菜单/按钮未分流到 Web 开发技能'
  $result = Invoke-Detector $integrated '新增远程 manifest 配置'
  Assert-Equal @($result.recommendedSkills).Count 2 '模块联邦配置未串联双技能'
  $result = Invoke-Detector $integrated '新增地图页面，展示点位聚合、轨迹回放和热力图' @('aura-web-develop', 'fmap-2d', 'fxft-video')
  Assert-Skills $result.recommendedSkills @('aura-web-develop', 'fmap-2d') 'PIGX 地图未分流到 Web + 地图技能'
  $result = Invoke-Detector $integrated '接入四路监控视频，支持 PTZ 和拖拽换位' @('aura-web-develop', 'fmap-2d', 'fxft-video')
  Assert-Skills $result.recommendedSkills @('aura-web-develop', 'fxft-video') 'PIGX 视频未分流到 Web + 视频技能'
  foreach ($request in @('新增视频页面', '接入视频')) {
    $result = Invoke-Detector $integrated $request
    Assert-Skills $result.recommendedSkills @('aura-web-develop', 'fxft-video') '常见视频开发应保留专项分流'
  }
  $result = Invoke-Detector $integrated '调整 Vite 的 exposes 配置'
  Assert-Skills $result.recommendedSkills @('aura-web-develop', 'aura-module-federation-check') '明确的 Vite expose 配置应走模块联邦基线和复检'
  $result = Invoke-Detector $integrated '新增远程地图模块 manifest 配置' @('aura-web-develop', 'fmap-2d', 'fxft-video', 'aura-module-federation-check')
  Assert-Skills $result.recommendedSkills @('aura-web-develop', 'fmap-2d', 'aura-module-federation-check') '地图模块联邦未串联三技能'
  $result = Invoke-Detector $integrated '新增远程视频模块 remote 配置' @('aura-web-develop', 'fmap-2d', 'fxft-video', 'aura-module-federation-check')
  Assert-Skills $result.recommendedSkills @('aura-web-develop', 'fxft-video', 'aura-module-federation-check') '视频模块联邦未串联三技能'
  $result = Invoke-Detector $integrated '新增设备地图点位' @()
  Assert-Skills $result.recommendedSkills @() '可用技能列表为空时不得假称 Web 技能已加载'
  Assert-Skills $result.unavailableSkills @('aura-web-develop', 'fmap-2d') '缺失技能列表不完整'
  Assert-Equal $result.unavailableSpecializedSkills[0] 'fmap-2d' '缺失地图技能未输出降级信息'
  if ($result.workflow -notmatch '提示用户是否安装') { throw '缺失技能时未生成安装提示。' }
  $result = Invoke-Detector $integrated '新增设备地图点位' @('aura-web-develop')
  Assert-Skills $result.recommendedSkills @('aura-web-develop') '地图专项缺失时应保留已安装的 Web 技能'
  Assert-Skills $result.unavailableSkills @('fmap-2d') '缺失地图技能未进入通用缺失列表'
  $result = Invoke-Detector $integrated '审计模块联邦配置' @()
  Assert-Skills $result.recommendedSkills @() '检查技能缺失时不得假称已加载'
  Assert-Skills $result.unavailableSkills @('aura-module-federation-check') '缺失模块联邦检查技能未被报告'
  $result = Invoke-Detector $integrated '审计模块联邦配置'
  Assert-Equal @($result.recommendedSkills).Count 1 '纯审计不应进入 Web 开发流程'
  Assert-Equal $result.recommendedSkills[0] 'aura-module-federation-check' '纯审计技能错误'
  Assert-Equal $result.isAuditOnly $true '模块联邦审计应按只读取证'
  $result = Invoke-Detector $integrated '审查前端代码和规范，生成六文件结果包，不修改代码'
  Assert-Skills $result.recommendedSkills @('aura-web-review') '综合前端审查应选择审查技能'
  foreach ($request in @('审查这次修改的 diff', '检查订单列表这次 diff')) {
    $result = Invoke-Detector $integrated $request
    Assert-Skills $result.recommendedSkills @('aura-web-review') '当前 diff 的审查应交审查技能'
    if ($result.workflow -match '六文件') { throw '限定 diff 不应被路由预定为六文件交付。' }
  }
  $result = Invoke-Detector $integrated '排查报警详情打不开的原因'
  Assert-Skills $result.recommendedSkills @('aura-web-develop') '普通业务故障应进入业务诊断'
  $readOnlyReason = Invoke-Detector $integrated '只看这个按钮为什么置灰，不改代码'
  Assert-Equal $readOnlyReason.workflow $result.workflow '只询问故障原因应复用业务诊断流程'
  $withFix = Invoke-Detector $integrated '先查按钮为什么置灰，然后修复'
  Assert-Skills $withFix.recommendedSkills @('aura-web-develop') '明确要求修复应保留开发技能'
  if ($withFix.workflow -eq $readOnlyReason.workflow) { throw '已授权的修复不能仅交给只读诊断。' }
  if ($result.workflow -notmatch '修复另按用户授权') { throw '普通诊断不应擅自启动修复。' }
  $result = Invoke-Detector $integrated '看下地图页面怎么拆，先给建议'
  Assert-Skills $result.recommendedSkills @('aura-web-review') '地图结构建议应进入只读咨询'
  if ($result.workflow -notmatch '只读结构或测试咨询') { throw '结构咨询不应默认进入审查报告流程。' }
  foreach ($request in @('给订单列表新增全屏按钮', '把刚才按钮的间距改小', '给同一个列表新增订单状态筛选', '新增订单数据聚合视图', '修改 PWA manifest 配置')) {
    $result = Invoke-Detector $integrated $request
    Assert-Skills $result.recommendedSkills @('aura-web-develop') '普通业务改动不因通用词语加载专项技能'
  }
  $result = Invoke-Detector $integrated '修改按钮后检查 diff'
  Assert-Skills $result.recommendedSkills @('aura-web-develop') '先修改再检查的任务必须保留实施'
  if ($result.workflow -notmatch '保留明确的排查、检查或验收阶段') { throw '混合请求的检查阶段没有交接。' }
  $result = Invoke-Detector $integrated '修复模块联邦配置并验收'
  Assert-Skills $result.recommendedSkills @('aura-web-develop', 'aura-module-federation-check') '联邦修复并验收必须保留实施与联邦复检'
  foreach ($request in @(
      '先做模块联邦改前基线，然后调整 shared 配置',
      '先做联邦基线，再修复已确认问题',
      '只修复模块联邦的 shared，不改其他文件',
      '只修复模块联邦的 shared 并复检，不改配置之外的文件')) {
    $result = Invoke-Detector $integrated $request
    Assert-Skills $result.recommendedSkills @('aura-web-develop', 'aura-module-federation-check') "明确实施应保留基线和复检，用户请求：$request"
    Assert-Equal $result.isAuditOnly $false "限定修改范围仍是实施，用户请求：$request"
  }
  foreach ($request in @(
      '检查模块联邦配置',
      '检查模块联邦配置，范围只限 shared',
      '排查 Vite dev 首次进入设备菜单时为什么会重载',
      '检查 Vite 组件 resolver 配置')) {
    $result = Invoke-Detector $integrated $request
    Assert-Skills $result.recommendedSkills @('aura-module-federation-check') "专项检查应由联邦技能牵引，用户请求：$request"
    Assert-Equal $result.isAuditOnly $false "未限定只读的专项检查应允许修复，用户请求：$request"
  }
  $result = Invoke-Detector $integrated '升级公共组件并检查预构建'
  Assert-Skills $result.recommendedSkills @('aura-web-develop', 'aura-module-federation-check') '显式调整公共依赖预构建需走开发、基线和复检'
  $result = Invoke-Detector $integrated '修复按钮打不开'
  Assert-Skills $result.recommendedSkills @('aura-web-develop') '明确修复应进入开发'
  $result = Invoke-Detector $integrated '审查这次 diff，不再修改源码'
  Assert-Skills $result.recommendedSkills @('aura-web-review') '明确只读的审查不得进入开发'
  foreach ($request in @(
      '检查当前模块联邦配置，只做审计，不修改代码',
      '模块联邦配置先给建议，不改',
      'Vite 公共依赖预构建只报告',
      '仅检查模块联邦的 shared 配置',
      '检查模块联邦配置，范围仅限 shared，仅检查、不改代码',
      '排查首次打开报警菜单后刷新，只读',
      '做模块联邦改前基线',
      '对模块联邦改动做一次复检')) {
    $result = Invoke-Detector $integrated $request
    Assert-Skills $result.recommendedSkills @('aura-module-federation-check') "限定范围应做联邦专项取证，用户请求：$request"
    Assert-Equal $result.isAuditOnly $true "保留明确只读范围，用户请求：$request"
  }
  $result = Invoke-Detector $integrated '审查全项目前端代码和规范，包括模块联邦配置与依赖预构建'
  Assert-Skills $result.recommendedSkills @('aura-web-review') '明确综合审查不能被提及的专项覆盖'
  foreach ($request in @('修改设备列表的刷新按钮', '调整接口域名的 DNS resolver 配置')) {
    $result = Invoke-Detector $integrated $request
    Assert-Skills $result.recommendedSkills @('aura-web-develop') "一般刷新与业务 resolver 不应进入联邦专项，用户请求：$request"
  }
  $result = Invoke-Detector $integrated '审查前端规范' @()
  Assert-Skills $result.recommendedSkills @() '审查技能缺失不能假称可用'
  Assert-Skills $result.unavailableSkills @('aura-web-review') '应说明缺失审查技能'

  $notPigx = Join-Path $testRoot 'vue-vite'
  Write-FixtureFile $notPigx 'package.json' '{"dependencies":{"vue":"3.5.0","vite":"6.0.0"}}'
  Write-FixtureFile $notPigx 'vite.config.ts' 'export default {};'
  $result = Invoke-Detector $notPigx '新增 CRUD 页面'
  Assert-Equal $result.projectType 'NotPIGX' '普通 Vue/Vite 应识别为 NotPIGX'
  Assert-Equal @($result.recommendedSkills).Count 0 '普通 Vue/Vite 不应加载 PIGX Web 技能'
  $result = Invoke-Detector $notPigx '新增地图页面和视频监控'
  Assert-Equal @($result.recommendedSkills).Count 0 '非 PIGX 地图/视频项目不应进入 PIGX 流程'

  $incomplete = Join-Path $testRoot 'incomplete'
  Write-FixtureFile $incomplete 'package.json' $vueViteManifest
  Write-FixtureFile $incomplete 'vite.config.ts' "import { federation } from '@module-federation/vite'; federation({});"
  $result = Invoke-Detector $incomplete '配置模块联邦 remote'
  Assert-Equal $result.projectType 'IncompleteCandidate' '不完整候选识别失败'
  Assert-Equal @($result.recommendedSkills).Count 0 '不完整候选不应自动接管'
  $result = Invoke-Detector $incomplete '审查前端代码规范'
  Assert-Skills $result.recommendedSkills @() '仅模块联邦插件不是 Aura 专有证据'
  Write-FixtureFile $incomplete 'src/config/moduleFederationBaseConfig.ts' 'export const currentRemoteConfig = {};'
  Write-FixtureFile $incomplete 'src/hooks/moduleFederation.ts' 'export const exposeModules = {};'
  $result = Invoke-Detector $incomplete '审查前端代码规范'
  Assert-Equal $result.projectType 'IncompleteCandidate' '缺当前运行时绑定应保留候选类型'
  Assert-Skills $result.recommendedSkills @('aura-web-review') '明确规范审查应允许有 Aura 证据的候选'
  $result = Invoke-Detector $incomplete '审查这次 diff 是否符合前端规范'
  Assert-Skills $result.recommendedSkills @('aura-web-review') 'Aura 候选的限定 diff 可做明确要求的规范审查'
  if ($result.workflow -match 'ReviewCandidate|六文件|盘点') { throw '候选局部审查不能强制执行正式盘点或生成六文件。' }
  $result = Invoke-Detector $incomplete '审查这次修改的 diff'
  Assert-Skills $result.recommendedSkills @() '候选的普通 diff 审查不应自动升级成规范审查'
  $result = Invoke-Detector $incomplete '新增业务页面'
  Assert-Skills $result.recommendedSkills @() '候选审查不能降低业务开发门槛'

  $reactMf = Join-Path $testRoot 'react-mf'
  Write-FixtureFile $reactMf 'package.json' '{"dependencies":{"react":"19.0.0"},"devDependencies":{"vite":"6.0.0"}}'
  Write-FixtureFile $reactMf 'src/config/moduleFederationBaseConfig.ts' 'export const currentRemoteConfig = {};'
  Write-FixtureFile $reactMf 'src/hooks/moduleFederation.ts' 'export const exposeModules = {};'
  Write-FixtureFile $reactMf 'src/config/aura/federation.ts' "export * from '@fxft/aura-web-kit/federation';"
  Write-FixtureFile $reactMf 'vite.config.ts' "import { federation } from '@module-federation/vite'; federation({});"
  $result = Invoke-Detector $reactMf '审查全项目前端规范'
  Assert-Equal $result.projectType 'NotPIGX' 'React 模块联邦不应作为 Aura 候选'
  Assert-Skills $result.recommendedSkills @() 'React 模块联邦不应误入 PIGX Web 流程'
  Assert-Equal @($result.matchedEvidence).Count 0 '技术栈未确认时不应读取 Aura 身份文件'

  # 沿用完整身份文件，验证缺失、无效或不明确的清单不能被文件证据绕过。
  $noManifest = Join-Path $testRoot 'no-manifest'
  Copy-Item -LiteralPath $integrated -Destination $noManifest -Recurse
  Remove-Item -LiteralPath (Join-Path $noManifest 'package.json')
  $result = Invoke-Detector $noManifest '修改订单列表按钮样式'
  Assert-Equal $result.projectType 'NotPIGX' '缺少清单不能据文件猜为综合端'
  Assert-Skills $result.recommendedSkills @() '缺少清单不应分流到 Web 技能'
  if ($result.frontendStackIssue -notmatch '缺少.*package.json') { throw '缺少清单时没有报告识别依据。' }
  foreach ($invalidManifest in @('{bad json}', '{"dependencies":{"vue":"2.7.16","vite":"6.0.0"}}', '{"dependencies":{"vue":"catalog:","vite":"6.0.0"}}', '{"dependencies":{"vue":"3.5.0"}}')) {
    Write-FixtureFile $noManifest 'package.json' $invalidManifest
    $result = Invoke-Detector $noManifest '审查前端规范'
    Assert-Equal $result.projectType 'NotPIGX' '技术栈不能明确判为 Vue 3 + Vite'
    Assert-Skills $result.recommendedSkills @() '技术栈未确认不能自动进入审查'
  }

  Write-Host '✓ PIGX 项目分流器回归测试通过。' -ForegroundColor Green
} finally {
  $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
  $tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
  if (-not $resolvedTestRoot.StartsWith($tempParent, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolvedTestRoot) -notmatch '^aura-pigx-router-[0-9a-f]{32}$') { throw '测试目录边界异常。' }
  if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}
