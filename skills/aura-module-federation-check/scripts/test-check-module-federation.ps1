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
	param([string]$Root, [string]$DeclaredVersion = '1.12.1', [string]$InstalledVersion = '1.12.1',
		[string]$LockSpecifier = $DeclaredVersion, [string]$LockVersion = $InstalledVersion)
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
	# 锁包含另一个 importer 和传递依赖，用于发现按全文件首个版本匹配的误判。
	if ($LockSpecifier) {
		Write-FixtureFile $Root 'pnpm-lock.yaml' @"
lockfileVersion: '9.0'
importers:
  apps/other:
    dependencies:
      '@fxft/aura-web-kit':
        specifier: 1.9.0
        version: 1.9.0
  .:
    dependencies:
      '@fxft/aura-web-kit':
        specifier: '$LockSpecifier'
        version: '$LockVersion'
packages:
  '@fxft/aura-web-kit@1.9.0': {}
"@
	}
	if ($InstalledVersion) {
		$exports = [ordered]@{}
		foreach ($entry in @('federation', 'federation/config', 'browser/assets', 'vite', 'postcss')) {
			$exports["./$entry"] = @{ types = "./dist/$entry.d.ts"; import = "./dist/$entry.js" }
			Write-FixtureFile $Root "node_modules/@fxft/aura-web-kit/dist/$entry.d.ts" 'export {};'
			Write-FixtureFile $Root "node_modules/@fxft/aura-web-kit/dist/$entry.js" 'export {};'
		}
		$exports['./types/remote-core'] = @{ types = './dist/types/remote-core.d.ts' }
		$installedPackage = @{ name = '@fxft/aura-web-kit'; version = $InstalledVersion; exports = $exports }
		Write-FixtureFile $Root 'node_modules/@fxft/aura-web-kit/package.json' ($installedPackage | ConvertTo-Json -Depth 6)
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
	Write-FixtureFile $integratedRoot 'README.md' '本项目由 pigx-nexus 模板创建。'
	$viteFile = 'vite.config.mts'
	$formattedVite = (Get-Content -LiteralPath (Join-Path $integratedRoot $viteFile) -Raw -Encoding UTF8).Replace("filename: 'remoteEntry.js'", 'filename:"remoteEntry.js"').Replace('vue: { singleton:', "vue: {`nsingleton:")
	Write-FixtureFile $integratedRoot $viteFile $formattedVite
	$result = Invoke-CheckerJson -ProjectPath $integratedRoot
	Assert-Equal $result.ExitCode 0 'README 模板历史和等效 Vite 格式不能导致身份或配置整改'
	Assert-Equal @($result.Report.findings | Where-Object { $_.ruleId -eq 'MF-ID-001' -and $_.severity -eq 'warning' }).Count 1 '模板历史只应提示核对'

	$kitRoot = Join-Path $testRoot 'kit-integrated'
	New-KitFixture -Root $kitRoot
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Equal $result.Report.projectType 'Integrated' '公共包综合端识别失败'
	Assert-Equal $result.ExitCode 0 '1.2.0 绑定、多级路径或 >=22.12.0 约束误报'
	Assert-Rule $result.Report 'MF-RUNTIME-007'

	# 同时检查实装门槛、当前 importer 的来源和声明范围；缺证与已知偏差分别累计。
	$versionCases = @(
		@{ Name = 'floor'; Declared = '1.12.1'; Installed = '1.12.1'; Errors = 0; Manual = 0 },
		@{ Name = 'higher'; Declared = '10.0.0'; Installed = '10.0.0'; Errors = 0; Manual = 0 },
		@{ Name = 'metadata'; Declared = '1.12.1+ci.2'; Installed = '1.12.1+ci.2'; Errors = 0; Manual = 0 },
		@{ Name = 'low'; Declared = '1.12.0'; Installed = '1.12.0'; Errors = 1; Manual = 0 },
		@{ Name = 'floor-prerelease'; Declared = '1.12.1-rc.1'; Installed = '1.12.1-rc.1'; Errors = 1; Manual = 0 },
		@{ Name = 'explicit-prerelease'; Declared = '1.13.0-rc.1'; Installed = '1.13.0-rc.1'; Errors = 0; Manual = 0 },
		@{ Name = 'range-and-peers'; Declared = '^1.9.0'; Installed = '1.13.0'; LockVersion = '1.13.0(vue@3.5.0)'; Errors = 0; Manual = 0 },
		@{ Name = 'range-mismatch'; Declared = '~1.12.1'; Installed = '1.13.0'; Errors = 1; Manual = 0 },
		@{ Name = 'lock-specifier-mismatch'; Declared = '^1.12.1'; Installed = '1.12.2'; LockSpecifier = '~1.12.1'; Errors = 1; Manual = 0 },
		@{ Name = 'lock-install-mismatch'; Declared = '^1.12.1'; Installed = '1.12.2'; LockVersion = '1.12.1'; Errors = 1; Manual = 0 },
		@{ Name = 'catalog'; Declared = 'catalog:'; Installed = '1.12.1'; Errors = 0; Manual = 1 },
		@{ Name = 'missing-lock'; Declared = '1.12.1'; Installed = '1.12.1'; LockSpecifier = ''; Errors = 0; Manual = 1 },
		@{ Name = 'missing-install'; Declared = '1.12.1'; Installed = ''; LockVersion = '1.12.1'; Errors = 0; Manual = 1 },
		@{ Name = 'bad-install'; Declared = '^1.12.1'; Installed = '01.12.1'; LockVersion = '1.12.1'; Errors = 0; Manual = 1 },
		@{ Name = 'bad-lock'; Declared = '^1.12.1'; Installed = '1.12.1'; LockVersion = 'link:../kit'; Errors = 0; Manual = 1 },
		@{ Name = 'undeclared'; Declared = ''; Installed = '1.12.1'; Errors = 1; Manual = 1 }
	)
	foreach ($case in $versionCases) {
		$versionRoot = Join-Path $testRoot ('version-' + $case.Name)
		$argsForCase = @{ Root = $versionRoot; DeclaredVersion = $case.Declared; InstalledVersion = $case.Installed }
		foreach ($key in @('LockSpecifier', 'LockVersion')) {
			if ($case.ContainsKey($key)) { $argsForCase[$key] = $case[$key] }
		}
		New-KitFixture @argsForCase
		$result = Invoke-CheckerJson -ProjectPath $versionRoot
		$versionFindings = @($result.Report.findings | Where-Object ruleId -eq 'MF-DEP-004')
		Assert-Equal @($versionFindings | Where-Object severity -eq 'error').Count $case.Errors "web-kit $($case.Name) 错误数"
		Assert-Equal @($versionFindings | Where-Object severity -eq 'manual').Count $case.Manual "web-kit $($case.Name) 待确认数"
		$expectedExit = if ($case.Errors -gt 0) { 1 } else { 0 }
		Assert-Equal $result.ExitCode $expectedExit "web-kit $($case.Name) 退出码"
	}
	$missingExportRoot = Join-Path $testRoot 'missing-kit-export'
	New-KitFixture -Root $missingExportRoot
	$exportPackagePath = 'node_modules/@fxft/aura-web-kit/package.json'
	$exportPackage = Get-Content -LiteralPath (Join-Path $missingExportRoot $exportPackagePath) -Raw | ConvertFrom-Json
	$exportPackage.exports.PSObject.Properties.Remove('./vite')
	Write-FixtureFile $missingExportRoot $exportPackagePath ($exportPackage | ConvertTo-Json -Depth 5)
	$result = Invoke-CheckerJson -ProjectPath $missingExportRoot
	Assert-Equal $result.ExitCode 1 '基线 web-kit 缺失公开入口仍须失败'
	Assert-Equal @($result.Report.findings | Where-Object { $_.ruleId -eq 'MF-DEP-004' -and $_.severity -eq 'error' }).Count 1 '缺失入口错误未保留'

	$exportPackage.exports | Add-Member -NotePropertyName './vite' -NotePropertyValue @{ types = './dist/vite.d.ts'; import = './dist/missing.js' }
	Write-FixtureFile $missingExportRoot $exportPackagePath ($exportPackage | ConvertTo-Json -Depth 5)
	$result = Invoke-CheckerJson -ProjectPath $missingExportRoot
	Assert-Equal @($result.Report.findings | Where-Object { $_.ruleId -eq 'MF-DEP-004' -and $_.message.Contains('missing.js') }).Count 1 '公开入口映射目标缺失'

	# 子项目应只读取共享锁中自己的 importer，即使其他项目使用相同的包名与不同的版本。
	$workspace = Join-Path $testRoot 'workspace'
	$member = Join-Path $workspace 'apps/order'
	New-KitFixture -Root $member -LockSpecifier ''
	Write-FixtureFile $workspace 'pnpm-workspace.yaml' "packages: ['apps/*']"
	$rootLock = Get-Content -LiteralPath (Join-Path $kitRoot 'pnpm-lock.yaml') -Raw -Encoding UTF8
	Write-FixtureFile $workspace 'pnpm-lock.yaml' ($rootLock.Replace('  .:', '  apps/order:'))
	$result = Invoke-CheckerJson -ProjectPath $member
	Assert-Equal @($result.Report.findings | Where-Object ruleId -eq 'MF-DEP-004').Count 0 'workspace 应匹配当前 importer'
	Write-FixtureFile $workspace 'pnpm-lock.yaml' ($rootLock.Replace('  .:', '  apps/elsewhere:'))
	$result = Invoke-CheckerJson -ProjectPath $member
	Assert-Equal @($result.Report.findings | Where-Object { $_.ruleId -eq 'MF-DEP-004' -and $_.severity -eq 'manual' }).Count 1 '缺 importer 应保留未证实'

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
	$kitManifestPath = 'node_modules/@fxft/aura-web-kit/package.json'
	$kitManifest = Get-Content -LiteralPath (Join-Path $kitRoot $kitManifestPath) -Raw -Encoding UTF8
	$nestedTypes = $kitManifest | ConvertFrom-Json
	$nestedTypes.exports.'./types/remote-core'.types = @{ default = './dist/types/remote-core.d.ts' }
	Write-FixtureFile $kitRoot $kitManifestPath ($nestedTypes | ConvertTo-Json -Depth 7)
	$result = Invoke-CheckerJson -ProjectPath $kitRoot
	Assert-Equal $result.ExitCode 0 '嵌套类型条件等待解析，不应触发本地声明整改'
	Assert-Equal @($result.Report.findings | Where-Object { $_.ruleId -eq 'MF-CONSUMER-005' -and $_.severity -eq 'manual' }).Count 1 '已引用但未解析的类型入口应保留未证实'
	Write-FixtureFile $kitRoot $kitManifestPath $kitManifest
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
	# 先使用两种纯类型导入，验证它们不会给已有地图与视频核对增加预构建要求。
	$templateEntry = '@fxft/aura-web-kit/theme-core/template-runtime'
	Write-FixtureFile $prebuildRoot 'src/template.ts' "import type { AuraTemplateRuntime } from '$templateEntry';`nimport { type AuraTemplateOption } from '$templateEntry';"
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
	# 再加入带别名的值导入；同一精确子入口此时应出现在预构建核对结果中。
	Write-FixtureFile $prebuildRoot 'src/template.ts' "import { type AuraTemplateRuntime, createAuraTemplateRuntime as create } from '$templateEntry';"
	Write-FixtureFile $prebuildRoot 'vite.config.mts' ($viteSource + "`nconst auditOptions = { optimizeDeps: { include: ['@fxft/ui-plus/dist/es/components/map/index.js', '@fxft/ui-plus/dist/es/components/web-multi-video/index.js'] } };")
	$result = Invoke-CheckerJson -ProjectPath $prebuildRoot
	$prebuildFindings = @($result.Report.findings | Where-Object ruleId -eq 'MF-VITE-008')
	if (@($prebuildFindings | Where-Object severity -eq 'manual').Count -ne 2) { throw '已配置入口仍应要求冷启动人工验证。' }
	if ($prebuildFindings.Message -match '/web-video/') { throw '未使用单路视频不应要求预构建。' }
	Assert-Equal @($prebuildFindings | Where-Object { $_.severity -eq 'warning' -and $_.message.Contains($templateEntry) }).Count 1 '混合导入中的运行时值应触发公共入口核对'
	Write-Host '✓ 模块联邦检查器回归测试通过。' -ForegroundColor Green
} finally {
	$resolvedTemp = [System.IO.Path]::GetFullPath($testRoot)
	$systemTemp = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
	if ($resolvedTemp.StartsWith($systemTemp, [System.StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemp)) {
		Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
	}
}
