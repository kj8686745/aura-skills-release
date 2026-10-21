# 辅助脚本行为测试；不替代 Agent 按技能进行独立审查。
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'Review-Frontend.ps1'
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$temp = Join-Path $tempBase ('aura-review-test-' + [Guid]::NewGuid().ToString('N'))
$passed = 0
function Assert-True([bool]$Value, [string]$Message) {
	if (-not $Value) { throw $Message }
	$script:passed++
}
function Assert-Rejected([scriptblock]$Operation, [string]$Message) {
	$rejected = $false
	try { & $Operation | Out-Null } catch { $rejected = $true }
	Assert-True $rejected $Message
}
function Write-TestFile([string]$Path, [string]$Text) {
	$null = New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force
	[IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}
try {
	$project = Join-Path $temp 'project'
	$page = Join-Path $project 'src/page.vue'
	Write-TestFile $page '<script setup>const token = "SYNTHETIC-DO-NOT-OUTPUT"; fetch("/a"); axios.get("/b");</script>'
	Write-TestFile (Join-Path $project 'vite.config.mjs') 'import { federation } from "@module-federation/vite"; export default {plugins: [federation({})]};'
	Write-TestFile (Join-Path $project 'src/config/moduleFederationBaseConfig.ts') 'export const currentRemoteConfig = {};'
	Write-TestFile (Join-Path $project 'src/hooks/moduleFederation.ts') 'export const exposeModules = {};'
	Write-TestFile (Join-Path $project 'src/config/aura/federation.ts') 'export { createModuleFederationRuntime } from "@fxft/aura-web-kit/federation";'
	Write-TestFile (Join-Path $project 'package.json') '{"name":"fixture","dependencies":{"vue":"^3.5.0"},"devDependencies":{"vite":"^6.4.0"}}'
	foreach ($name in @('.npmrc', '.env.production', 'secrets.json')) { Write-TestFile (Join-Path $project $name) 'SYNTHETIC-DO-NOT-OUTPUT' }
	Write-TestFile (Join-Path $project 'node_modules/example/index.js') 'fetch("/ignored");'
	Write-TestFile (Join-Path $project 'server/index.ts') 'fetch("/outside-frontend");'
	$before = (Get-FileHash -LiteralPath $page).Hash
	$out = Join-Path $temp 'inventory'
	$result = & $runner -Action Collect -ProjectRoot $project -OutputDirectory $out
	$data = Get-Content -LiteralPath (Join-Path $out 'inventory.json') -Raw -Encoding UTF8 | ConvertFrom-Json
	Assert-True ($result.status -eq '仅盘点，未完成审查' -and $data.kind -eq 'inventory-only') '盘点不能声称完成审查'
	Assert-True ($data.assets.Count -eq 6 -and $data.candidates.Count -eq 2 -and $data.identification.projectType -eq 'Integrated') '当前 Aura 绑定应命中，资产与语法命中数量正确'
	Assert-True (($data.assets.file -contains 'vite.config.mjs') -and $data.failures.Count -eq 0) 'mjs 配置必须盘点'
	Assert-True (-not ((Get-Content -LiteralPath (Join-Path $out 'inventory.json') -Raw) -match 'SYNTHETIC-DO-NOT-OUTPUT')) '不得复制源码与敏感值'
	Assert-True ((Get-FileHash -LiteralPath $page).Hash -eq $before) '不得改变项目文件'
	Assert-Rejected { & $runner -Action Collect -ProjectRoot $project -OutputDirectory $out } '已有盘点必须拒绝覆盖'
	Assert-Rejected { & $runner -Action Collect -ProjectRoot $project -OutputDirectory (Join-Path $project 'out') } '必须拒绝项目内输出'
	Assert-Rejected { & $runner -Action Collect -ProjectRoot $project -OutputDirectory (Join-Path $temp 'bad') -Scope '../inventory' } '必须拒绝范围越界'
	Assert-Rejected { & $runner -Action Collect -ProjectRoot $project -OutputDirectory (Join-Path $temp 'nonfrontend') -Scope 'server' } '必须拒绝非前端实现范围'
	$unsupported = Join-Path $temp 'unsupported'
	Write-TestFile (Join-Path $unsupported 'package.json') '{"name":"fixture-service","dependencies":{"express":"^5.0.0"}}'
	Assert-Rejected { & $runner -Action Collect -ProjectRoot $unsupported -OutputDirectory (Join-Path $temp 'unsupported-out') } '非 Vue3/Vite 项目必须拒绝'
	Write-TestFile (Join-Path $unsupported 'package.json') '{"dependencies":{"vue":"catalog:","vite":"^6.0.0"}}'
	Assert-Rejected { & $runner -Action Collect -ProjectRoot $unsupported -OutputDirectory (Join-Path $temp 'unknown-out') } '无法确认 Vue 主版本不能盲扫'
	Write-TestFile (Join-Path $unsupported 'package.json') '{"dependencies":{"vue":"^3.5.0","vite":"^6.0.0"}}'
	$ordinary = & $runner -Action Collect -ProjectRoot $unsupported -OutputDirectory (Join-Path $temp 'ordinary-out')
	Assert-True ($ordinary.projectType -eq 'NotAura' -and -not $ordinary.inventoryCreated -and -not (Test-Path -LiteralPath (Join-Path $temp 'ordinary-out'))) '普通 Vue/Vite 项目不得套用 Aura 盘点'
	Write-TestFile (Join-Path $unsupported 'vite.config.ts') 'import { federation } from "@module-federation/vite"; federation({});'
	Write-TestFile (Join-Path $unsupported 'src/config/moduleFederationBaseConfig.ts') 'export const currentRemoteConfig = {};'
	Write-TestFile (Join-Path $unsupported 'src/hooks/moduleFederation.ts') 'export const exposeModules = {};'
	$candidate = & $runner -Action Collect -ProjectRoot $unsupported -OutputDirectory (Join-Path $temp 'candidate-out')
	Assert-True ($candidate.projectType -eq 'IncompleteCandidate' -and $candidate.missingEvidence -contains 'runtimeBinding' -and -not $candidate.inventoryCreated) '缺少一项绑定只能返回候选身份'
	$approvedCandidate = & $runner -Action Collect -ProjectRoot $unsupported -OutputDirectory (Join-Path $temp 'candidate-review') -ReviewCandidate
	Assert-True ($approvedCandidate.projectType -eq 'IncompleteCandidate' -and (Test-Path -LiteralPath $approvedCandidate.output)) '明确审查任务必须能盘点有 Aura 专有证据的候选并保留缺项'
	$inside = Join-Path $project '审查结果包-fixture-test/证据/首次盘点'
	Write-TestFile (Join-Path $project '审查结果包-existing/证据/log.ts') 'fetch("/not-source");'
	$insideResult = & $runner -Action Collect -ProjectRoot $project -OutputDirectory $inside
	$insideData = Get-Content -LiteralPath $insideResult.output -Raw -Encoding UTF8 | ConvertFrom-Json
	Assert-True ($insideData.assets.Count -eq 6 -and $insideData.candidates.Count -eq 2) '项目内结果包及其证据不得进入资产或候选'
	Assert-Rejected { & $runner -Action Collect -ProjectRoot $project -OutputDirectory $inside } '项目内盘点证据也禁止覆盖'
	Assert-Rejected { & $runner -Action Collect -ProjectRoot $project -OutputDirectory $project } '禁止项目根输出'
	$defaultFirst = & $runner -Action Collect -ProjectRoot $project
	$defaultSecond = & $runner -Action Collect -ProjectRoot $project
	Assert-True ($defaultFirst.reportDirectory -ne $defaultSecond.reportDirectory -and (Test-Path -LiteralPath $defaultFirst.output) -and (Test-Path -LiteralPath $defaultSecond.output)) '默认结果包重复运行必须选择新目录，不能覆盖'
	$defaultData = Get-Content -LiteralPath $defaultSecond.output -Raw -Encoding UTF8 | ConvertFrom-Json
	Assert-True ($defaultData.reportDirectory -eq $defaultSecond.reportDirectory -and $defaultData.assets.Count -eq 6 -and $defaultData.candidates.Count -eq 2) '默认输出应返回包路径且不扫描已有包'
	$limited = Join-Path $temp 'limited'
	$null = & $runner -Action Collect -ProjectRoot $project -OutputDirectory $limited -Scope 'src/page.vue'
	$limitedData = Get-Content -LiteralPath (Join-Path $limited 'inventory.json') -Raw -Encoding UTF8 | ConvertFrom-Json
	Assert-True ($limitedData.scopeKind -eq 'limited' -and $limitedData.assets.Count -eq 1) '限定范围必须保留范围标记'
	Write-TestFile (Join-Path $project 'src/new.ts') 'export const added = true;'
	$next = Join-Path $temp 'next'
	$null = & $runner -Action Collect -ProjectRoot $project -OutputDirectory $next
	$nextData = Get-Content -LiteralPath (Join-Path $next 'inventory.json') -Raw -Encoding UTF8 | ConvertFrom-Json
	Assert-True ($nextData.fingerprint -ne $data.fingerprint) '新增文件必须改变清单指纹'
	$pack = Join-Path $temp 'report'
	$names = @('00-结果包说明.md', '01-审查报告.md', '02-规则核查矩阵.md', '03-证据与执行记录.md', '04-整改与复核清单.md', '05-扫描候选与判定.md')
	foreach ($name in $names) { Write-TestFile (Join-Path $pack $name) '# 结构测试，不是完成的审查报告' }
	$rules = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../references/rules.json') -Raw -Encoding UTF8 | ConvertFrom-Json
	$matrix = ($rules | ForEach-Object { '| ' + $_.id + ' | 未证实 |' }) -join "`n"
	Write-TestFile (Join-Path $pack '02-规则核查矩阵.md') $matrix
	$check = & $runner -Action Check -ReportDirectory $pack
	Assert-True ($check.status -eq '结构检查通过' -and $check.limitations -match '统计闭合') '结构检查必须明确语义边界'
	Write-TestFile (Join-Path $pack '02-规则核查矩阵.md') ($matrix + "`n| AURA-BASE-FE-001 | 未证实 |")
	Assert-Rejected { & $runner -Action Check -ReportDirectory $pack } '重复规则行必须拒绝'
	Write-TestFile (Join-Path $pack '02-规则核查矩阵.md') $matrix
	Write-TestFile (Join-Path $pack '01-审查报告.md') '[外部文件](../project/package.json)'
	Assert-Rejected { & $runner -Action Check -ReportDirectory $pack } '本地链接越界必须拒绝'
	Write-TestFile (Join-Path $pack '01-审查报告.md') '[丢失附件](证据/missing.txt)'
	Assert-Rejected { & $runner -Action Check -ReportDirectory $pack } '不存在的附件必须拒绝'
	Write-TestFile (Join-Path $pack '01-审查报告.md') ''
	Assert-Rejected { & $runner -Action Check -ReportDirectory $pack } '空报告必须拒绝'
	[pscustomobject]@{ testsPassed = $passed; powershell = $PSVersionTable.PSVersion.ToString(); scope = '辅助脚本行为；不证明 Agent 审查语义' }
}
finally {
	# 只清理本次在系统临时目录生成的精确子目录。
	$resolvedTemp = [IO.Path]::GetFullPath($temp)
	if (-not $resolvedTemp.StartsWith($tempBase.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetFileName($resolvedTemp) -notmatch '^aura-review-test-[0-9a-f]{32}$') { throw '测试临时目录边界检查失败。' }
	if (Test-Path -LiteralPath $resolvedTemp) { Remove-Item -LiteralPath $resolvedTemp -Recurse -Force }
}
