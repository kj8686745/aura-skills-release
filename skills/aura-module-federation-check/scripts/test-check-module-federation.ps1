# 使用临时项目验证端类型识别、退出码和综合端核心规则

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$checker = Join-Path $PSScriptRoot 'check-module-federation.ps1'
$powerShellExe = (Get-Process -Id $PID).Path
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("aura-pigx-mf-check-" + [guid]::NewGuid().ToString('N'))
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Write-FixtureFile {
	param([string]$Root, [string]$RelativePath, [string]$Content)
	$fullPath = Join-Path $Root $RelativePath
	$directory = Split-Path -Parent $fullPath
	if ($directory) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
	[System.IO.File]::WriteAllText($fullPath, $Content, $utf8NoBom)
}

function New-IntegratedScaffold {
	param([string]$Root)
	New-Item -ItemType Directory -Path $Root -Force | Out-Null
	Write-FixtureFile $Root 'package.json' @'
{
  "name": "aura-order-web",
  "packageManager": "pnpm@10.28.0",
  "engines": { "node": ">=22" },
  "dependencies": {
    "element-plus": "2.14.6",
    "vue": "3.5.13",
    "vue-router": "4.6.4",
    "vue-i18n": "9.2.2",
    "pinia": "2.3.1"
  },
  "devDependencies": {
    "@module-federation/vite": "1.18.2",
    "@module-federation/enhanced": "2.8.0",
    "vite": "6.4.3"
  }
}
'@
	Write-FixtureFile $Root 'vite.config.mts' @'
import { federation } from '@module-federation/vite';
import { skipModuleFederationRemotePreload } from './vite-plugins/skip-module-federation-remote-preload';
federation({
  name: currentFederationName,
  filename: 'remoteEntry.js',
  manifest: true,
  bundleAllCSS: false,
  exposes: exposeModules,
  shared: {
    vue: { singleton: true, requiredVersion: '^3.5.13' },
    'vue-router': { singleton: true, requiredVersion: '^4.6.4' },
    'vue-i18n': { singleton: true, requiredVersion: '^9.2.2' },
    pinia: { singleton: true, requiredVersion: '^2.3.1' },
    'element-plus': { singleton: true, requiredVersion: '^2.14.6' }
  }
});
skipModuleFederationRemotePreload();
export default { build: { modulePreload: false } };
'@
	Write-FixtureFile $Root '.env' "VITE_PUBLIC_PATH=/auraOrderWeb/`n"
	Write-FixtureFile $Root 'index.html' "<script>localStorage.getItem('order-web:bootstrap-config')</script>"
	Write-FixtureFile $Root 'postcss.config.js' "const REMOTE_SCOPE = '.aura-mf-remote-scope.aura-mf-remote-aura-order-web';"
	Write-FixtureFile $Root 'src/config/moduleFederationBaseConfig.ts' @'
export const currentRemoteConfig = {
  remoteName: 'aura-order-web',
  remoteEntryName: 'auraOrderWeb',
  i18nScanDirs: [] as readonly string[]
};
export const moduleFederationRemoteNames = [] as const;
'@
	Write-FixtureFile $Root 'src/config/siteConfig.ts' "export const siteConfig = { systemId: 'order-web' };"
	Write-FixtureFile $Root 'src/config/viteModuleFederationConfig.ts' "export const getModuleFederationRemoteEntries = () => ({});"
	Write-FixtureFile $Root 'src/config/remoteConfig.ts' "export const moduleFederationRemoteEntries = {};"
	Write-FixtureFile $Root 'src/hooks/moduleFederation.ts' @'
export const utilsExposes = {
  './utils/mitt': './src/utils/mitt.ts',
  './moduleFederation/runtime': './src/hooks/moduleFederation.ts'
};
export const styleExposes = {
  './styles/moduleFederationTailwind.ts': './src/styles/moduleFederationTailwind.ts'
};
export const i18nExposes = {
  './i18n/langs': './src/i18n/moduleFederation.ts'
};
export const exposeModules = {
  ...utilsExposes,
  ...styleExposes,
  ...i18nExposes
};
'@
	Write-FixtureFile $Root 'src/utils/mitt.ts' 'export default {};'
	Write-FixtureFile $Root 'src/components/ModuleFederationElementProvider/index.vue' '<template><slot /></template>'
	Write-FixtureFile $Root 'src/styles/moduleFederationTailwind.ts' "import './moduleFederationTailwind.css';"
	Write-FixtureFile $Root 'src/styles/moduleFederationTailwind.css' '.aura-mf-remote-scope.aura-mf-remote-aura-order-web { width: 100%; }'
	Write-FixtureFile $Root 'src/i18n/moduleFederation.ts' 'export default {};'
}

function Invoke-CheckerJson {
	param([string]$ProjectPath, [string[]]$ExtraArgs = @())
	$arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $checker, '-ProjectPath', $ProjectPath, '-Json') + $ExtraArgs
	$output = & $powerShellExe @arguments 2>&1
	$exitCode = $LASTEXITCODE
	[pscustomobject]@{
		ExitCode = $exitCode
		Report = (($output -join "`n") | ConvertFrom-Json)
	}
}

function New-KitFixture {
	param([string]$Root)
	New-IntegratedScaffold -Root $Root
	$packageFile = Join-Path $Root 'package.json'
	$package = Get-Content -LiteralPath $packageFile -Raw | ConvertFrom-Json
	$package.engines.node = '>=22'
	$package.dependencies.'element-plus' = '2.14.6'
	$package.dependencies | Add-Member -NotePropertyName '@fxft/aura-web-kit' -NotePropertyValue '1.6.15'
	Write-FixtureFile $Root 'package.json' ($package | ConvertTo-Json -Depth 5)
	$vite = Get-Content -LiteralPath (Join-Path $Root 'vite.config.mts') -Raw
	$vite += @'

import { auraOptimizeDeps, stabilizeFederationModuleScan, pruneFederationSsrImports, stabilizeFederationDevOptimizer, createAuraAutoImports } from '@fxft/aura-web-kit/vite';
stabilizeFederationModuleScan(); pruneFederationSsrImports(); stabilizeFederationDevOptimizer();
createAuraAutoImports({ projectHooks: pathResolve('./src/config/aura/index.ts') });
const include = [...auraOptimizeDeps];
'@
	Write-FixtureFile $Root 'vite.config.mts' $vite
	Write-FixtureFile $Root 'postcss.config.js' "const { createAuraPostcssPlugins } = require('@fxft/aura-web-kit/postcss'); createAuraPostcssPlugins({ remoteScope: '.aura-mf-remote-scope.aura-mf-remote-aura-order-web' });"
	$base = (Get-Content -LiteralPath (Join-Path $Root 'src/config/moduleFederationBaseConfig.ts') -Raw).Replace("'auraOrderWeb'", "'/aura/orderWeb'")
	Write-FixtureFile $Root 'src/config/moduleFederationBaseConfig.ts' $base
	Write-FixtureFile $Root '.env' 'VITE_PUBLIC_PATH=/aura/orderWeb/'
	Write-FixtureFile $Root 'index.html' "<script>localStorage.getItem('aura-order-web:bootstrap-config')</script>"
	Write-FixtureFile $Root 'src/config/aura/federation.ts' @'
import { createFederationRemotes, createFederationStyles, createFederationI18n, createFederationRegistry } from '@fxft/aura-web-kit/federation';
import { registerRemotes, loadRemote } from '@module-federation/enhanced/runtime';
const remotes = createFederationRemotes({ entries: moduleFederationRemoteEntries, registerRemotes });
const styles = createFederationStyles({ getRemoteManifestEntry: remotes.getRemoteManifestEntry });
const i18n = createFederationI18n({ loadRemote });
const registry = createFederationRegistry({ loadRemote, remotes, styles, i18n, elementProvider: ModuleFederationElementProvider, getRemoteScopeClass });
export const { getModuleFederationLoader } = registry;
'@
	Write-FixtureFile $Root 'node_modules/@fxft/aura-web-kit/package.json' @'
{"version":"1.6.15","exports":{"./federation":{"types":"./dist/federation.d.ts"},"./federation/config":{},"./browser/assets":{},"./vite":{},"./postcss":{},"./types/remote-core":{"types":"./dist/types/remote-core.d.ts"}}}
'@
	Write-FixtureFile $Root 'node_modules/@fxft/aura-web-kit/dist/types/remote-core.d.ts' "declare module 'aura-core/api/example.ts' { export const read: () => void; }"
}

function Assert-Equal {
	param($Actual, $Expected, [string]$Message)
	if ($Actual -ne $Expected) { throw "$Message，期望 $Expected，实际 $Actual。" }
}

function Assert-Rule {
	param($Report, [string]$RuleId)
	if (@($Report.findings | Where-Object ruleId -eq $RuleId).Count -eq 0) { throw "未命中预期规则：$RuleId" }
}

New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
	$integratedRoot = Join-Path $testRoot 'integrated'
	New-KitFixture -Root $integratedRoot
	$result = Invoke-CheckerJson -ProjectPath $integratedRoot
	Assert-Equal $result.Report.projectType 'Integrated' '综合端类型识别失败'
	Assert-Equal $result.ExitCode 0 '合规综合端退出码错误'

	$kitRoot = Join-Path $testRoot 'kit-integrated'
	New-KitFixture -Root $kitRoot
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Equal $result.Report.projectType 'Integrated' '公共包综合端识别失败'
	Assert-Equal $result.ExitCode 0 '1.2.0 绑定、多级路径或 >=22 约束误报'
	Assert-Rule $result.Report 'MF-RUNTIME-007'

	$bindingPath = Join-Path $kitRoot 'src/config/aura/federation.ts'
	$binding = Get-Content -LiteralPath $bindingPath -Raw
	Write-FixtureFile $kitRoot 'src/config/aura/federation.ts' ($binding.Replace('elementProvider: ModuleFederationElementProvider,', ''))
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Equal $result.ExitCode 1 '缺失 Provider 必须失败'
	Assert-Rule $result.Report 'MF-RUNTIME-006'
	Write-FixtureFile $kitRoot 'src/config/aura/federation.ts' $binding

	$kitPackage = Get-Content -LiteralPath (Join-Path $kitRoot 'package.json') -Raw
	Write-FixtureFile $kitRoot 'package.json' ($kitPackage.Replace('>=22', '>=20'))
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Rule $result.Report 'MF-DEP-003'
	Write-FixtureFile $kitRoot 'package.json' ($kitPackage.Replace('1.6.15', '1.6.14'))
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Rule $result.Report 'MF-DEP-004'
	Write-FixtureFile $kitRoot 'package.json' ($kitPackage.Replace('2.14.6', '2.14.3'))
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Rule $result.Report 'MF-VITE-003'
	Write-FixtureFile $kitRoot 'package.json' $kitPackage

	$basePath = Join-Path $kitRoot 'src/config/moduleFederationBaseConfig.ts'
	$kitBase = Get-Content -LiteralPath $basePath -Raw
	Write-FixtureFile $kitRoot 'src/config/moduleFederationBaseConfig.ts' ($kitBase.Replace('/aura/orderWeb', '/aura/../orderWeb'))
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Rule $result.Report 'MF-ID-003'
	Write-FixtureFile $kitRoot 'src/config/moduleFederationBaseConfig.ts' ($kitBase.Replace('moduleFederationRemoteNames = []', "moduleFederationRemoteNames = ['aura-core']"))
	Write-FixtureFile $kitRoot 'src/config/remoteConfig.ts' "export const moduleFederationRemoteEntries = { 'aura-core': import.meta.env.VITE_CORE_ENTRY };"
	Write-FixtureFile $kitRoot 'src/config/viteModuleFederationConfig.ts' "export const getModuleFederationRemoteEntries = (env) => ({ 'aura-core': env.VITE_CORE_ENTRY });"
	Write-FixtureFile $kitRoot '.env' "VITE_PUBLIC_PATH=/aura/orderWeb/`nVITE_CORE_ENTRY=/core/mf-manifest.json"
	Write-FixtureFile $kitRoot '.env.development' 'VITE_CORE_ENTRY=https://example.test'
	$kitVite = Get-Content -LiteralPath (Join-Path $kitRoot 'vite.config.mts') -Raw
	Write-FixtureFile $kitRoot 'vite.config.mts' ($kitVite + "`nconst proxy = { '/core': { target: env.VITE_CORE_ENTRY } };")
	Write-FixtureFile $kitRoot 'src/views/example.ts' "import { read } from 'aura-core/api/example.ts';"
	Write-FixtureFile $kitRoot 'src/types/framework.d.ts' "import '@fxft/aura-web-kit/types/remote-core';"
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Equal $result.ExitCode 0 ('已启用的包声明不应误报缺失：' + ($result.Report.findings | Where-Object severity -eq error | ConvertTo-Json -Compress))
	Write-FixtureFile $kitRoot 'src/types/framework.d.ts' "// import '@fxft/aura-web-kit/types/remote-core';"
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Rule $result.Report 'MF-CONSUMER-005'

	$providerRoot = Join-Path $testRoot 'provider'
	Write-FixtureFile $providerRoot 'package.json' '{"name":"provider"}'
	Write-FixtureFile $providerRoot 'vite.config.ts' "export default { exposes: { './Page': './src/Page.vue' } };"
	$result = Invoke-CheckerJson -ProjectPath $providerRoot
	Assert-Equal $result.Report.projectType 'Provider' '生产端类型识别失败'
	Assert-Equal $result.ExitCode 3 '生产端应立即停止'
	Assert-Equal @($result.Report.findings).Count 0 '生产端不应执行综合端规则'

	$consumerRoot = Join-Path $testRoot 'consumer'
	Write-FixtureFile $consumerRoot 'package.json' '{"name":"consumer"}'
	Write-FixtureFile $consumerRoot 'vite.config.ts' "export default { remotes: { core: '/remoteEntry.js' } };"
	$result = Invoke-CheckerJson -ProjectPath $consumerRoot
	Assert-Equal $result.Report.projectType 'Consumer' '消费端类型识别失败'
	Assert-Equal $result.ExitCode 3 '消费端应立即停止'
	Assert-Equal @($result.Report.findings).Count 0 '消费端不应执行综合端规则'

	$unknownRoot = Join-Path $testRoot 'unknown'
	Write-FixtureFile $unknownRoot 'package.json' '{"name":"unknown"}'
	$result = Invoke-CheckerJson -ProjectPath $unknownRoot
	Assert-Equal $result.Report.projectType 'Unknown' '未知类型识别失败'
	Assert-Equal $result.ExitCode 2 '未知类型退出码错误'

	$invalidRoot = Join-Path $testRoot 'invalid-integrated'
	Copy-Item -LiteralPath $integratedRoot -Destination $invalidRoot -Recurse
	Write-FixtureFile $invalidRoot 'src/config/moduleFederationBaseConfig.ts' @'
export const currentRemoteConfig = {
  remoteName: 'pigx-nexus',
  remoteEntryName: 'pigxNexus',
  i18nScanDirs: [] as readonly string[]
};
export const moduleFederationRemoteNames = ['aura-license-center'] as const;
'@
	Write-FixtureFile $invalidRoot 'src/config/remoteConfig.ts' @'
export const moduleFederationRemoteEntries = {
  'aura-license-center': import.meta.env.VITE_AURA_LICENSE_CENTER_REMOTE_PATH
};
'@
	Write-FixtureFile $invalidRoot 'src/hooks/moduleFederation.ts' @'
export const pageExposes = { './views/order/index.vue': './src/views/order/missing.vue' };
export const utilsExposes = { './moduleFederation/runtime': './src/hooks/moduleFederation.ts' };
export const styleExposes = { './styles/moduleFederationTailwind.ts': './src/styles/moduleFederationTailwind.ts' };
export const i18nExposes = { './i18n/langs': './src/i18n/moduleFederation.ts' };
export const exposeModules = { ...pageExposes, ...utilsExposes, ...styleExposes, ...i18nExposes };
'@
	Write-FixtureFile $invalidRoot 'src/views/bad.vue' @'
<template><RemotePage /></template>
<script setup lang="ts">
import RemotePage from 'aura-license-center/views/page.vue';
</script>
'@
	$result = Invoke-CheckerJson -ProjectPath $invalidRoot -ExtraArgs @('-ComponentPath', '/aura-license-center/page.vue?type=moduleFederation')
	if ($result.ExitCode -ne 1) {
		throw "违规综合端退出码错误，期望 1，实际 $($result.ExitCode)。报告：$($result.Report | ConvertTo-Json -Depth 6 -Compress)"
	}
	foreach ($ruleId in @('MF-ID-001', 'MF-PROVIDER-001', 'MF-CONSUMER-002', 'MF-CONSUMER-004', 'MF-CONSUMER-005', 'MF-CONSUMER-006', 'MF-MENU-001')) {
		Assert-Rule -Report $result.Report -RuleId $ruleId
	}

	Write-Host '✓ 模块联邦检查器回归测试通过。' -ForegroundColor Green
} finally {
	$resolvedTemp = [System.IO.Path]::GetFullPath($testRoot)
	$systemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
	if ($resolvedTemp.StartsWith($systemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemp)) {
		Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
	}
}
