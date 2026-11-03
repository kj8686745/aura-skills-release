param(
  [Parameter(Mandatory = $true)]
  [string]$CompilerProjectPath
)

# Execute the public scanner against isolated fixtures; reuse installed compiler dependencies only.
$ErrorActionPreference = 'Stop'
$checker = Join-Path $PSScriptRoot 'check-project-rules.ps1'
$powerShellExe = (Get-Process -Id $PID).Path
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('aura-ui-rules-' + [guid]::NewGuid().ToString('N'))
$originalNodePath = $env:NODE_PATH
$env:NODE_PATH = Join-Path (Resolve-Path -LiteralPath $CompilerProjectPath).Path 'node_modules'
$encoding = [Text.UTF8Encoding]::new($false)
$count = 0

function Write-Fixture {
  param([string]$Path, [string]$Content)
  $target = Join-Path $testRoot $Path
  New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
  [IO.File]::WriteAllText($target, $Content, $encoding)
}

function Invoke-Case {
  param([string]$Name, [string[]]$Paths, [int]$Exit, [string]$Expected = '', [switch]$EmptyFiles, [switch]$AllSources, [string]$Forbidden = '')
  # -Command is needed to preserve an array argument and an explicit empty -Files collection.
  $invocation = "& '$($checker.Replace("'", "''"))' -ProjectPath '$($testRoot.Replace("'", "''"))' -StrictUiContracts"
  if (-not $AllSources) {
    $invocation += ' -Files @('
    if (-not $EmptyFiles) { $invocation += ($Paths | ForEach-Object { "'$($_.Replace("'", "''"))'" }) -join ',' }
    $invocation += ')'
  }
  $invocation += '; exit $LASTEXITCODE'
  $output = (& $powerShellExe -NoProfile -Command $invocation 2>&1) -join "`n"
  if ($LASTEXITCODE -ne $Exit -or ($Expected -and $output -notmatch $Expected) -or ($Forbidden -and $output -match $Forbidden)) { throw "$Name failed: exit=$LASTEXITCODE expected=$Exit`n$output" }
  $script:count++
}

try {
  New-Item -ItemType Directory -Path (Join-Path $testRoot 'src') -Force | Out-Null
  Invoke-Case 'empty source tree' @() 2 '没有有效' -AllSources
  Write-Fixture 'src/example.ts' 'export const count = 1;'
  Write-Fixture 'src/i18n/en.ts' "export default { device: { title: 'Device', nested: { name: 'Nested' } }, sibling: { name: 'Sibling' } };"
  Write-Fixture 'src/i18n/zh-cn.ts' "const messages = { device: { title: 'Device', nested: { name: 'Nested' } }, sibling: { name: 'Sibling' } }; export default messages;"
  Invoke-Case 'missing' @('src/missing.ts') 2 '未找到'
  Invoke-Case 'mixed' @('src/example.ts', 'src/missing.ts') 2 '扫描不完整'
  Invoke-Case 'empty collection' @() 2 '没有有效' -EmptyFiles
  Invoke-Case 'blank path' @('') 2 '空路径'
  Invoke-Case 'unsupported' @('package.json') 2 '不受支持'
  $lockedPath = Join-Path $testRoot 'src/example.ts'
  $lockedFile = [IO.File]::Open($lockedPath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
  try { Invoke-Case 'unreadable file' @('src/example.ts') 2 '无法读取源码' } finally { $lockedFile.Dispose() }
  Write-Fixture 'src/example.ts' "t('device.title'); t('device.nested.name');"
  Invoke-Case 'valid and deeply nested' @('src/example.ts') 0
  Write-Fixture 'src/example.ts' "t('device.name');"
  Invoke-Case 'sibling is not nested' @('src/example.ts') 1 'device.name.*未在'
  Write-Fixture 'src/example.ts' @'
const text = "t('device.missing')";
// t('device.missing')
/* t('device.missing') */
t('device.title');
'@
  Invoke-Case 'strings and comments' @('src/example.ts') 0
  Write-Fixture 'src/i18n/en.ts' "namespace Locale { export const messages = { device: { title: 'Device' } }; } export default Locale.messages;"
  Write-Fixture 'src/example.ts' "t('device.title');"
  Invoke-Case 'namespace and alias' @('src/example.ts') 0
  Write-Fixture 'src/i18n/en.ts' "export default { 'device.name': 'Name', device: { ['link-url']: 'https://example.test/path//name' } };"
  Write-Fixture 'src/i18n/zh-cn.ts' "export default { 'device.name': 'Name', device: { 'link-url': 'https://example.test/path//name' } };"
  Write-Fixture 'src/example.ts' "const url = 'https://example.test/path//name'; t('device.name'); t('device.link-url');"
  Invoke-Case 'quoted dotted keys, computed literal keys and URL strings' @('src/example.ts') 0
  Write-Fixture 'src/i18n/zh-cn.ts' "export default { device: { title: 'Device' } };"
  Write-Fixture 'src/example.ts' "t('device.title');"
  Write-Fixture 'src/i18n/en.ts' "import other from './external'; export default { ...other };"
  Invoke-Case 'import uncertainty' @('src/example.ts') 2 '无法静态确认'
  Write-Fixture 'src/i18n/en.ts' "export default { device: { title: loadText() } };"
  Invoke-Case 'dynamic value uncertainty' @('src/example.ts') 2 '无法静态确认'
  Write-Fixture 'src/i18n/en.ts' "let messages = { device: { title: 'Device' } }; messages = loadMessages(); export default messages;"
  Invoke-Case 'mutated alias uncertainty' @('src/example.ts') 2 '无法静态确认'
  Write-Fixture 'src/i18n/en.ts' "export default { device: { title: 'Device' } };"
  Write-Fixture 'src/example.ts' 't(dynamicKey);'
  Invoke-Case 'dynamic call uncertainty' @('src/example.ts') 2 '动态 i18n key'

  Write-Fixture 'src/i18n/zh-cn.ts' "export default { common: { retry: '重试私密文案' }, history: { first: '历史', second: '历史' } };"
  Write-Fixture 'src/i18n/en.ts' "export default { common: { retry: 'Private retry text' }, history: { first: 'Historical', second: 'Historical' } };"
  Write-Fixture 'src/modules/i18n/zh-cn.ts' "const retry = '重试私密文案'; const actions = { retry }; export default { asset: { ...actions }, iot: actions };"
  Write-Fixture 'src/modules/i18n/en.ts' "const retry = 'Private retry text'; const actions = { retry }; export default { asset: { ...actions }, iot: actions };"
  Write-Fixture 'src/example.ts' "t('iot.retry');"
  Invoke-Case 'public and business bilingual duplicate with static spread and references' @('src/example.ts') 2 '双语重复候选.*common.retry.*i18n/zh-cn.ts:1.*asset.retry.*iot.retry' -Forbidden '重试私密文案|Private retry text|history.first|history.second'
  Write-Fixture 'src/example.ts' 'export const count = 1;'
  Invoke-Case 'unselected historical duplicates are context only' @('src/example.ts') 0 -Forbidden '双语重复候选：'
  Invoke-Case 'selected locale definitions need no call sites' @('src/modules/i18n/en.ts') 2 '双语重复候选.*common.retry.*asset.retry.*iot.retry' -Forbidden 'history.first|history.second'
  Invoke-Case 'all-source scan includes historical duplicates' @() 2 '双语重复候选.*history.first.*history.second' -AllSources
  Write-Fixture 'src/views/i18n-check.vue' '<template><div>{{ $t("asset.retry") }}</div></template>'
  Invoke-Case 'Vue dollar-t literal participates in scoped duplicates' @('src/views/i18n-check.vue') 2 '双语重复候选.*asset.retry' -Forbidden 'history.first|history.second'
  Remove-Item -LiteralPath (Join-Path $testRoot 'src/views/i18n-check.vue') -Force
  Write-Fixture 'src/modules/i18n/en.ts' "export default { asset: { retry: 'Retry asset' }, iot: { retry: 'Retry iot' } };"
  Write-Fixture 'src/example.ts' "t('iot.retry');"
  Invoke-Case 'Chinese-only match with different English is not duplicate' @('src/example.ts') 0 -Forbidden '双语重复候选：'
  Write-Fixture 'src/modules/i18n/en.ts' "export default { asset: { retry: 'Private retry text' }, iot: { retry: loadText() } };"
  Invoke-Case 'dynamic translation is unconfirmed rather than duplicate' @('src/example.ts') 2 '无法静态确认' -Forbidden '双语重复候选：'
  Invoke-Case 'selected dynamic locale remains unconfirmed without calls' @('src/modules/i18n/en.ts') 2 '无法静态确认'
  Write-Fixture 'src/modules/i18n/en.ts' "import messages from './external'; export default messages;"
  Invoke-Case 'selected imported locale remains unconfirmed without calls' @('src/modules/i18n/en.ts') 2 '无法静态确认' -Forbidden '双语重复候选：'
  Write-Fixture 'src/modules/i18n/en.ts' "export default { asset: { retry: 'Private retry text' }, iot: { retry: 'Private retry text' } };"
  Write-Fixture 'src/override/en.ts' "export default { iot: { retry: 'Different override' } };"
  Invoke-Case 'conflicting same-key files never select an arbitrary winner' @('src/example.ts') 2 'iot.retry.*不同静态定义' -Forbidden '双语重复候选：'
  Write-Fixture 'src/override/en.ts' "export default { iot: { retry: 'Private retry text' } };"
  Invoke-Case 'identical same-key files keep all definition locations' @('src/example.ts') 2 '双语重复候选.*iot.retry.*src/override/en.ts:1'
  Write-Fixture 'src/modules/i18n/en.ts' 'export default { asset: {} };'
  Write-Fixture 'src/override/en.ts' 'export default {};'
  Invoke-Case 'missing one language cannot form a duplicate pair' @('src/example.ts') 1 'iot.retry.*未在 en.ts' -Forbidden '双语重复候选：'
  Remove-Item -LiteralPath (Join-Path $testRoot 'src/modules/i18n/en.ts'), (Join-Path $testRoot 'src/modules/i18n/zh-cn.ts'), (Join-Path $testRoot 'src/override/en.ts') -Force
  Write-Fixture 'src/i18n/zh-cn.ts' "export default { device: { title: 'Device' } };"
  Write-Fixture 'src/i18n/en.ts' "export default { device: { title: 'Device' } };"
  Write-Fixture 'src/api/model.ts' @'
export interface DictRow {
  /** @dictKey test_status */
  status?: number;
  statusName?: string;
}
export interface OtherRow { statusName: string; }
'@
  Write-Fixture 'src/views/test/index.vue' @'
<template><div>{{ row.statusName }}</div></template>
<script setup lang="ts">
import type { DictRow } from '/@/api/model';
const row: DictRow = {};
</script>
'@
  Invoke-Case 'selected view retains API context and binds type' @('src/views/test/index.vue') 1 '已绑定类型.*test_status'
  Write-Fixture 'src/views/test/index.vue' @'
<template><div>{{ row.statusName }}</div></template>
<script setup lang="ts">
import type { OtherRow } from '/@/api/model';
const row: OtherRow = { statusName: 'Label' };
</script>
'@
  Invoke-Case 'same name on unrelated concrete type' @('src/views/test/index.vue') 0
  Write-Fixture 'src/views/test/index.vue' @'
<template><div /></template>
<script setup lang="ts">
import type { DictRow } from '/@/api/model';
const row: DictRow = {};
const payload = row.statusName;
</script>
'@
  Invoke-Case 'script read does not prove display violation' @('src/views/test/index.vue') 2 '未确认用于展示'
  Write-Fixture 'src/views/test/index.vue' @'
<template><div v-for="row in rows">{{ row.statusName }}</div></template>
<script setup lang="ts">
import type { DictRow } from '/@/api/model';
const row: DictRow = {};
const rows: any[] = [];
</script>
'@
  Invoke-Case 'template aliases never borrow a same-name setup binding' @('src/views/test/index.vue') 2 '候选待人工核对'
  Write-Fixture 'src/views/test/index.vue' '<template><div>{{ scope.row.statusName }}</div></template><script setup lang="ts">const scope: any = {};</script>'
  Invoke-Case 'unbound same-name candidate' @('src/views/test/index.vue') 2 '候选待人工核对'
  Write-Fixture 'src/views/test/index.vue' @'
<template><div>{{ t('device.title') }}</div></template>
<script setup lang="ts">
const text = "t('device.missing')";
// t('device.missing')
</script>
'@
  Invoke-Case 'Vue expressions versus script strings' @('src/views/test/index.vue') 0
  Remove-Item -LiteralPath (Join-Path $testRoot 'src/i18n/en.ts'), (Join-Path $testRoot 'src/i18n/zh-cn.ts') -Force
  Invoke-Case 'API-only scan needs no language packages' @('src/api/model.ts') 0
  Write-Host "UI contract regression passed: $count cases."
} finally {
  $env:NODE_PATH = $originalNodePath
  $resolved = [IO.Path]::GetFullPath($testRoot)
  $tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
  if ($resolved.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolved)) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
