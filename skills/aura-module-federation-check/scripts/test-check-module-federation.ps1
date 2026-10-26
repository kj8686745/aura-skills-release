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
  "engines": { "node": ">=22.12.0" },
  "dependencies": {
    "element-plus": "2.14.6",
    "vue": "3.5.13",
    "vue-router": "4.6.4",
    "vue-i18n": "9.2.2",
    "pinia": "2.3.1"
  },
  "devDependencies": {
    "@module-federation/vite": "1.23.5",
    "@module-federation/enhanced": "2.9.2",
    "vite": "6.4.3",
    "typescript": "5.9.3",
    "eslint": "8.57.1",
    "@typescript-eslint/parser": "8.46.1",
    "@typescript-eslint/eslint-plugin": "8.46.1"
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
	param([string]$Root, [string]$DeclaredVersion = '1.9.0', [string]$InstalledVersion = '1.9.0')
	New-IntegratedScaffold -Root $Root
	$packageFile = Join-Path $Root 'package.json'
	$package = Get-Content -LiteralPath $packageFile -Raw | ConvertFrom-Json
	$package.engines.node = '>=22.12.0'
	$package.dependencies.'element-plus' = '2.14.6'
	if ($DeclaredVersion) {
		$package.dependencies | Add-Member -NotePropertyName '@fxft/aura-web-kit' -NotePropertyValue $DeclaredVersion
	}
	Write-FixtureFile $Root 'package.json' ($package | ConvertTo-Json -Depth 5)
	$vite = Get-Content -LiteralPath (Join-Path $Root 'vite.config.mts') -Raw
	$vite += @'

import { auraAutoOptimizeDeps, pruneFederationSsrImports, stabilizeFederationDevOptimizer, createAuraAutoImportPreset } from '@fxft/aura-web-kit/vite';
pruneFederationSsrImports(); stabilizeFederationDevOptimizer();
const autoImports = createAuraAutoImportPreset({ projectHooks: pathResolve('./src/config/aura/index.ts') });
auraAutoOptimizeDeps({ resolvers: createComponentResolvers, imports: autoImports, exposes: exposeModules });
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
	$installedPackage = @'
{"version":"1.9.0","exports":{"./federation":{"types":"./dist/federation.d.ts"},"./federation/config":{},"./browser/assets":{},"./vite":{},"./postcss":{},"./types/remote-core":{"types":"./dist/types/remote-core.d.ts"}}}
'@
	if ($InstalledVersion) {
		Write-FixtureFile $Root 'node_modules/@fxft/aura-web-kit/package.json' ($installedPackage.Replace('1.9.0', $InstalledVersion))
		Write-FixtureFile $Root 'node_modules/@fxft/aura-web-kit/dist/types/remote-core.d.ts' "declare module 'aura-core/api/example.ts' { export const read: () => void; }"
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
	New-KitFixture -Root $integratedRoot
	$result = Invoke-CheckerJson -ProjectPath $integratedRoot
	Assert-Equal $result.Report.projectType 'Integrated' '综合端类型识别失败'
	Assert-Equal $result.ExitCode 0 '合规综合端退出码错误'

	$kitRoot = Join-Path $testRoot 'kit-integrated'
	New-KitFixture -Root $kitRoot
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Equal $result.Report.projectType 'Integrated' '公共包综合端识别失败'
	Assert-Equal $result.ExitCode 0 '1.2.0 绑定、多级路径或 >=22.12.0 约束误报'
	Assert-Rule $result.Report 'MF-RUNTIME-007'

	# 每例使用独立项目，并同时设置声明与安装，声明与安装均按精确1.9.0检出偏差。
	$versionCases = @(
		@{ Name = 'baseline'; Declared = '1.9.0'; Installed = '1.9.0'; Errors = 0; Manual = 0 },
		@{ Name = 'patch'; Declared = '1.9.1'; Installed = '1.9.1'; Errors = 2; Manual = 0 },
		@{ Name = 'minor'; Declared = '1.10.0'; Installed = '1.10.0'; Errors = 2; Manual = 0 },
		@{ Name = 'major'; Declared = '2.0.0'; Installed = '2.0.0'; Errors = 2; Manual = 0 },
		@{ Name = 'double-digit-major'; Declared = '10.0.0'; Installed = '10.0.0'; Errors = 2; Manual = 0 },
		@{ Name = 'metadata'; Declared = '1.9.0+build.1'; Installed = '1.9.0+build.1'; Errors = 2; Manual = 0 },
		@{ Name = 'low-minor'; Declared = '1.8.99'; Installed = '1.8.99'; Errors = 2; Manual = 0 },
		@{ Name = 'low-major'; Declared = '0.99.99'; Installed = '0.99.99'; Errors = 2; Manual = 0 },
		@{ Name = 'minimum-prerelease'; Declared = '1.9.0-rc.1'; Installed = '1.9.0-rc.1'; Errors = 2; Manual = 0 },
		@{ Name = 'higher-prerelease'; Declared = '1.10.0-rc.1'; Installed = '1.10.0-rc.1'; Errors = 2; Manual = 0 },
		@{ Name = 'range-installed'; Declared = '^1.9.0'; Installed = '1.9.1'; Errors = 2; Manual = 0 },
		@{ Name = 'range-installed-low'; Declared = '>=1.8.0'; Installed = '1.8.99'; Errors = 2; Manual = 0 },
		@{ Name = 'exact-mismatch'; Declared = '1.9.0'; Installed = '1.9.1'; Errors = 1; Manual = 0 },
		@{ Name = 'installed-low-priority'; Declared = '1.9.1'; Installed = '1.8.99'; Errors = 2; Manual = 0 },
		@{ Name = 'invalid-installed'; Declared = '^1.9.0'; Installed = 'unknown'; Errors = 2; Manual = 0 },
		@{ Name = 'invalid-leading-zero'; Declared = '*'; Installed = '01.9.0'; Errors = 2; Manual = 0 },
		@{ Name = 'range-uninstalled'; Declared = '^1.9.0'; Installed = ''; Errors = 1; Manual = 1 },
		@{ Name = 'tag-uninstalled'; Declared = 'latest'; Installed = ''; Errors = 1; Manual = 1 },
		@{ Name = 'baseline-uninstalled'; Declared = '1.9.0'; Installed = ''; Errors = 0; Manual = 1 },
		@{ Name = 'range-installed-baseline'; Declared = '^1.9.0'; Installed = '1.9.0'; Errors = 1; Manual = 0 },
		@{ Name = 'exact-uninstalled'; Declared = '1.10.0'; Installed = ''; Errors = 1; Manual = 1 },
		@{ Name = 'low-uninstalled'; Declared = '1.8.99'; Installed = ''; Errors = 1; Manual = 1 },
		@{ Name = 'undeclared'; Declared = ''; Installed = '1.9.1'; Errors = 2; Manual = 0 }
	)
	foreach ($case in $versionCases) {
		$versionRoot = Join-Path $testRoot ('version-' + $case.Name)
		New-KitFixture -Root $versionRoot -DeclaredVersion $case.Declared -InstalledVersion $case.Installed
		$result = Invoke-CheckerJson -ProjectPath $versionRoot
		$versionFindings = @($result.Report.findings | Where-Object ruleId -eq 'MF-DEP-004')
		Assert-Equal @($versionFindings | Where-Object severity -eq 'error').Count $case.Errors "web-kit $($case.Name) 错误数"
		Assert-Equal @($versionFindings | Where-Object severity -eq 'manual').Count $case.Manual "web-kit $($case.Name) 待确认数"
		$expectedExit = if ($case.Errors -gt 0) { 1 } else { 0 }
		Assert-Equal $result.ExitCode $expectedExit "web-kit $($case.Name) 退出码"
	}
	$missingExportRoot = Join-Path $testRoot 'missing-kit-export'
	New-KitFixture -Root $missingExportRoot -DeclaredVersion '1.9.0' -InstalledVersion '1.9.0'
	$exportPackagePath = 'node_modules/@fxft/aura-web-kit/package.json'
	$exportPackage = Get-Content -LiteralPath (Join-Path $missingExportRoot $exportPackagePath) -Raw | ConvertFrom-Json
	$exportPackage.exports.PSObject.Properties.Remove('./vite')
	Write-FixtureFile $missingExportRoot $exportPackagePath ($exportPackage | ConvertTo-Json -Depth 5)
	$result = Invoke-CheckerJson -ProjectPath $missingExportRoot
	Assert-Equal $result.ExitCode 1 '基线 web-kit 缺失公开入口仍须失败'
	Assert-Equal @($result.Report.findings | Where-Object { $_.ruleId -eq 'MF-DEP-004' -and $_.severity -eq 'error' }).Count 1 '缺失入口错误未保留'

	$bindingPath = Join-Path $kitRoot 'src/config/aura/federation.ts'
	$binding = Get-Content -LiteralPath $bindingPath -Raw
	Write-FixtureFile $kitRoot 'src/config/aura/federation.ts' ($binding.Replace('elementProvider: ModuleFederationElementProvider,', ''))
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Equal $result.ExitCode 1 '缺失 Provider 必须失败'
	Assert-Rule $result.Report 'MF-RUNTIME-006'
	Write-FixtureFile $kitRoot 'src/config/aura/federation.ts' $binding

	$kitPackage = Get-Content -LiteralPath (Join-Path $kitRoot 'package.json') -Raw
	Write-FixtureFile $kitRoot 'package.json' ($kitPackage.Replace('>=22.12.0', '>=20'))
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Rule $result.Report 'MF-DEP-003'
	Write-FixtureFile $kitRoot 'package.json' ($kitPackage.Replace('2.14.6', '2.14.3'))
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Rule $result.Report 'MF-VITE-003'
	Write-FixtureFile $kitRoot 'package.json' $kitPackage

	foreach ($oldVersion in @('5.9.3', '8.57.1', '8.46.1')) {
		Write-FixtureFile $kitRoot 'package.json' ($kitPackage.Replace($oldVersion, '0.0.1'))
		$result = Invoke-CheckerJson -ProjectPath $kitRoot
		Assert-Rule $result.Report 'MF-DEP-005'
	}
	Write-FixtureFile $kitRoot 'package.json' ($kitPackage.Replace('1.23.5', '1.18.2'))
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Rule $result.Report 'MF-DEP-001'
	Write-FixtureFile $kitRoot 'package.json' $kitPackage
	$modernVite = Get-Content -LiteralPath (Join-Path $kitRoot 'vite.config.mts') -Raw
	Write-FixtureFile $kitRoot 'vite.config.mts' ($modernVite + "`nstabilizeFederationModuleScan();")
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Rule $result.Report 'MF-VITE-006'
	Write-FixtureFile $kitRoot 'vite.config.mts' $modernVite

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

	$prebuildRoot = Join-Path $testRoot 'prebuild-integrated'
	Copy-Item -LiteralPath $integratedRoot -Destination $prebuildRoot -Recurse
	Write-FixtureFile $prebuildRoot 'src/views/map.vue' '<template><FxftMap /><fxft-web-multi-video /></template>'
	$vitePath = Join-Path $prebuildRoot 'vite.config.mts'
	$viteSource = Get-Content -LiteralPath $vitePath -Raw -Encoding UTF8
	$result = Invoke-CheckerJson -ProjectPath $prebuildRoot
	$prebuildFindings = @($result.Report.findings | Where-Object ruleId -eq 'MF-VITE-008')
	Assert-Equal @($prebuildFindings | Where-Object severity -eq 'warning').Count 0 '自动收集不得要求重复手工 include'
	Assert-Equal @($prebuildFindings | Where-Object severity -eq 'manual').Count 2 '自动收集仍需最终配置和冷启动补证'
	$viteSource = $viteSource.Replace('auraAutoOptimizeDeps({ resolvers: createComponentResolvers, imports: autoImports, exposes: exposeModules });', '// auraAutoOptimizeDeps({});')
	Write-FixtureFile $prebuildRoot 'vite.config.mts' ($viteSource + "`nconst auditOptions = { optimizeDeps: { include: ['@fxft/ui-plus'] } };")
	$result = Invoke-CheckerJson -ProjectPath $prebuildRoot
	$prebuildFindings = @($result.Report.findings | Where-Object ruleId -eq 'MF-VITE-008')
	if (@($prebuildFindings | Where-Object severity -eq 'warning').Count -ne 2) { throw '根包 include 不能替代地图和多路视频入口。' }
	Write-FixtureFile $prebuildRoot 'vite.config.mts' ($viteSource + "`nconst auditOptions = { optimizeDeps: { include: ['@fxft/ui-plus/dist/es/components/map/index.js', '@fxft/ui-plus/dist/es/components/web-multi-video/index.js'] } };")
	$result = Invoke-CheckerJson -ProjectPath $prebuildRoot
	$prebuildFindings = @($result.Report.findings | Where-Object ruleId -eq 'MF-VITE-008')
	if (@($prebuildFindings | Where-Object severity -eq 'manual').Count -ne 2) { throw '已配置入口仍应要求冷启动人工验证。' }
	if ($prebuildFindings.Message -match '/web-video/') { throw '未使用单路视频不应要求预构建。' }
	Write-Host '✓ 模块联邦检查器回归测试通过。' -ForegroundColor Green
} finally {
	$resolvedTemp = [System.IO.Path]::GetFullPath($testRoot)
	$systemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
	if ($resolvedTemp.StartsWith($systemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemp)) {
		Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
	}
}
