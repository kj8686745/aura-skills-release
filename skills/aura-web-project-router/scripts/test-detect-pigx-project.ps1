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
  $result = Invoke-Detector $integrated '审查前端代码和规范，生成六文件结果包，不修改代码'
  Assert-Skills $result.recommendedSkills @('aura-web-review') '综合前端审查应选择审查技能'
  $result = Invoke-Detector $integrated '检查当前模块联邦配置，只做审计，不修改代码'
  Assert-Skills $result.recommendedSkills @('aura-module-federation-check') '不修改代码不应误触发开发或综合审查'
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
  $result = Invoke-Detector $incomplete '新增业务页面'
  Assert-Skills $result.recommendedSkills @() '候选审查不能降低业务开发门槛'

  $reactMf = Join-Path $testRoot 'react-mf'
  Write-FixtureFile $reactMf 'package.json' '{"dependencies":{"react":"19.0.0"}}'
  Write-FixtureFile $reactMf 'vite.config.ts' "import { federation } from '@module-federation/vite'; federation({});"
  $result = Invoke-Detector $reactMf '新增 remote'
  Assert-Equal $result.projectType 'IncompleteCandidate' 'React 模块联邦应作为不完整候选报告'
  Assert-Equal @($result.recommendedSkills).Count 0 'React 模块联邦不应误入 PIGX Web 流程'

  Write-Host '✓ PIGX 项目分流器回归测试通过。' -ForegroundColor Green
} finally {
  $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
  $tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
  if (-not $resolvedTestRoot.StartsWith($tempParent, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolvedTestRoot) -notmatch '^aura-pigx-router-[0-9a-f]{32}$') { throw '测试目录边界异常。' }
  if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}
