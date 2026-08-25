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

function New-IntegratedFixture {
	param([string]$Root)
	New-Item -ItemType Directory -Path $Root -Force | Out-Null
	Write-FixtureFile $Root 'package.json' @'
{
  "name": "aura-order-web",
  "packageManager": "pnpm@10.28.0",
  "engines": { "node": ">=20.12.0" },
  "dependencies": {
    "element-plus": "2.14.3",
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
    'element-plus': { singleton: true, requiredVersion: '^2.14.3' }
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
	Write-FixtureFile $Root 'src/utils/moduleFederationRegistry.ts' @'
export const getModuleFederationLoader = () => null;
const tree = { class: ['aura-mf-remote-scope'] };
h(ModuleFederationElementProvider);
const markers = ['loadError', 'refreshModuleFederationRemote', 'resetRemoteI18nCache', 'resetRemoteStyleCache', 'data-mf-load-error', '重新加载'];
'@
	Write-FixtureFile $Root 'src/utils/moduleFederationRemotes.ts' 'registerRemotes; normalizeRemoteEntry; getRemoteManifestEntry; refreshModuleFederationRemote;'
	Write-FixtureFile $Root 'src/utils/moduleFederationI18n.ts' 'export const ensureRemoteI18nMessages = () => {};'
	Write-FixtureFile $Root 'src/utils/moduleFederationStyles.ts' 'export const ensureRemoteExposeStyles = () => {};'
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
	New-IntegratedFixture -Root $integratedRoot
	$result = Invoke-CheckerJson -ProjectPath $integratedRoot
	Assert-Equal $result.Report.projectType 'Integrated' '综合端类型识别失败'
	Assert-Equal $result.ExitCode 0 '合规综合端退出码错误'

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
