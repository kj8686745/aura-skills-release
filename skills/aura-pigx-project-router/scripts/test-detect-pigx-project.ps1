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
  param([string]$ProjectPath, [string]$Task)
  $output = & $powerShellExe -NoProfile -ExecutionPolicy Bypass -File $detector -ProjectPath $ProjectPath -TaskDescription $Task -Json
  if ($LASTEXITCODE -ne 0) { throw "识别脚本退出码错误：$LASTEXITCODE" }
  return (($output -join "`n") | ConvertFrom-Json)
}

function Assert-Equal {
  param($Actual, $Expected, [string]$Message)
  if ($Actual -ne $Expected) { throw "$Message，期望 $Expected，实际 $Actual。" }
}

New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
  $integrated = Join-Path $testRoot 'integrated'
  Write-FixtureFile $integrated 'src/config/moduleFederationBaseConfig.ts' 'export const currentRemoteConfig = {};'
  Write-FixtureFile $integrated 'src/hooks/moduleFederation.ts' 'export const exposeModules = {};'
  Write-FixtureFile $integrated 'src/utils/moduleFederationRegistry.ts' 'export const getModuleFederationLoader = () => null;'
  Write-FixtureFile $integrated 'vite.config.ts' "import { federation } from '@module-federation/vite'; federation({});"
  $result = Invoke-Detector $integrated '新增订单 CRUD 页面和正式菜单按钮'
  Assert-Equal $result.projectType 'Integrated' 'PIGX 综合端识别失败'
  Assert-Equal $result.recommendedSkills[0] 'aura-pigx-web-develop' 'PIGX CRUD 未分流到 Web 开发技能'
  $result = Invoke-Detector $integrated '新增正式菜单和 v-auth 按钮权限'
  Assert-Equal $result.recommendedSkills[0] 'aura-pigx-web-develop' '正式菜单/按钮未分流到 Web 开发技能'
  $result = Invoke-Detector $integrated '新增远程 manifest 配置'
  Assert-Equal @($result.recommendedSkills).Count 2 '模块联邦配置未串联双技能'
  $result = Invoke-Detector $integrated '审计模块联邦配置'
  Assert-Equal @($result.recommendedSkills).Count 1 '纯审计不应进入 Web 开发流程'
  Assert-Equal $result.recommendedSkills[0] 'aura-pigx-module-federation-check' '纯审计技能错误'

  $notPigx = Join-Path $testRoot 'vue-vite'
  Write-FixtureFile $notPigx 'package.json' '{"dependencies":{"vue":"3.5.0","vite":"6.0.0"}}'
  Write-FixtureFile $notPigx 'vite.config.ts' 'export default {};'
  $result = Invoke-Detector $notPigx '新增 CRUD 页面'
  Assert-Equal $result.projectType 'NotPIGX' '普通 Vue/Vite 应识别为 NotPIGX'
  Assert-Equal @($result.recommendedSkills).Count 0 '普通 Vue/Vite 不应加载 PIGX Web 技能'

  $incomplete = Join-Path $testRoot 'incomplete'
  Write-FixtureFile $incomplete 'vite.config.ts' "import { federation } from '@module-federation/vite'; federation({});"
  $result = Invoke-Detector $incomplete '配置模块联邦 remote'
  Assert-Equal $result.projectType 'IncompleteCandidate' '不完整候选识别失败'
  Assert-Equal @($result.recommendedSkills).Count 0 '不完整候选不应自动接管'

  $reactMf = Join-Path $testRoot 'react-mf'
  Write-FixtureFile $reactMf 'package.json' '{"dependencies":{"react":"19.0.0"}}'
  Write-FixtureFile $reactMf 'vite.config.ts' "import { federation } from '@module-federation/vite'; federation({});"
  $result = Invoke-Detector $reactMf '新增 remote'
  Assert-Equal $result.projectType 'IncompleteCandidate' 'React 模块联邦应作为不完整候选报告'
  Assert-Equal @($result.recommendedSkills).Count 0 'React 模块联邦不应误入 PIGX Web 流程'

  Write-Host '✓ PIGX 项目分流器回归测试通过。' -ForegroundColor Green
} finally {
  if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}
