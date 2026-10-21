# PowerShell 5.1 / 7；只读盘点与六文件结构检查，不执行项目脚本或判定规范。
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)][ValidateSet('Collect', 'Check')][string]$Action,
	[string]$ProjectRoot,
	[string]$OutputDirectory,
	[string[]]$Scope = @(),
	[switch]$ReviewCandidate,
	[string]$ReportDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$reportFiles = @('00-结果包说明.md', '01-审查报告.md', '02-规则核查矩阵.md', '03-证据与执行记录.md', '04-整改与复核清单.md', '05-扫描候选与判定.md')

function Get-SafePath([string]$Value) {
	if ([string]::IsNullOrWhiteSpace($Value)) { throw '缺少目录或路径参数。' }
	$full = [IO.Path]::GetFullPath($Value)
	$cursor = $full
	while ($cursor) {
		if (Test-Path -LiteralPath $cursor) {
			$item = Get-Item -LiteralPath $cursor -Force
			if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw '路径包含符号链接或 junction；请选择直接目录。' }
		}
		$parent = [IO.Path]::GetDirectoryName($cursor)
		if ($parent -eq $cursor) { break }
		$cursor = $parent
	}
	return $full
}

function Test-Within([string]$Root, [string]$Path) {
	return $Path.Equals($Root, [StringComparison]::OrdinalIgnoreCase) -or $Path.StartsWith($Root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

function Get-LocalPath([string]$Root, [string]$Relative) {
	if ([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative) -or $Relative -match '[:\x00-\x1f]') { throw '需要目录内相对路径。' }
	$full = Get-SafePath (Join-Path $Root $Relative)
	if (-not (Test-Within $Root $full)) { throw '相对路径越界。' }
	return $full
}

function Get-Hash([byte[]]$Bytes) {
	$sha = [Security.Cryptography.SHA256]::Create()
	try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
	finally { $sha.Dispose() }
}

function Test-IdentityFile([string]$Root, [string]$Relative, [string[]]$Patterns) {
	$file = Get-LocalPath $Root $Relative
	if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return $false }
	if ((Get-Item -LiteralPath $file).Length -gt 2000000) { return $false }
	try { $source = [IO.File]::ReadAllText($file) }
	catch { return $false }
	foreach ($pattern in $Patterns) { if ($source -notmatch $pattern) { return $false } }
	return $true
}

if ($Action -eq 'Collect') {
	$root = (Get-SafePath $ProjectRoot).TrimEnd('\', '/')
	if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw '项目目录不存在。' }
	$manifest = Get-LocalPath $root 'package.json'
	if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw '缺少前端 package.json；未开始盘点。' }
	try { $package = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json }
	catch { throw '无法解析前端 package.json；未开始盘点。' }
	$dependencies = @{}
	foreach ($section in @('dependencies', 'devDependencies')) {
		$property = $package.PSObject.Properties[$section]
		if ($null -ne $property -and $null -ne $property.Value) {
			foreach ($dependency in $property.Value.PSObject.Properties) { $dependencies[$dependency.Name] = [string]$dependency.Value }
		}
	}
	if (-not $dependencies.ContainsKey('vue') -or $dependencies.vue -notmatch '^[\^~= ]*3(?:\.|$)' -or -not $dependencies.ContainsKey('vite') -or [string]::IsNullOrWhiteSpace($dependencies.vite)) { throw '仅支持可确认的 Vue 3 + Vite 前端项目；当前依赖声明不符合或版本无法确认，未开始盘点。' }
	# 四项证据只用于识别，不代替源码语义审查；当前绑定不要求恢复旧运行时副本。
	$identity = [ordered]@{
		currentRemoteConfig = Test-IdentityFile $root 'src/config/moduleFederationBaseConfig.ts' @('\bcurrentRemoteConfig\b')
		exposeModules = Test-IdentityFile $root 'src/hooks/moduleFederation.ts' @('\bexposeModules\b')
		runtimeBinding = Test-IdentityFile $root 'src/config/aura/federation.ts' @('@fxft/aura-web-kit/federation')
		viteFederation = $false
	}
	foreach ($extension in @('ts', 'js', 'mts', 'mjs', 'cts', 'cjs')) {
		if (Test-IdentityFile $root ('vite.config.' + $extension) @('@module-federation/vite', '\bfederation\s*\(')) { $identity.viteFederation = $true }
	}
	$matched = @($identity.Keys | Where-Object { $identity[$_] })
	$missing = @($identity.Keys | Where-Object { -not $identity[$_] })
	$identityType = if ($missing.Count -eq 0) { 'Integrated' } elseif ($matched.Count -eq 0) { 'NotAura' } else { 'IncompleteCandidate' }
	$hasAuraEvidence = $identity.currentRemoteConfig -or $identity.exposeModules -or $identity.runtimeBinding
	if ($identityType -ne 'Integrated' -and -not ($ReviewCandidate -and $hasAuraEvidence)) {
		[pscustomobject]@{ action = 'Collect'; projectType = $identityType; matchedEvidence = $matched; missingEvidence = $missing; inventoryCreated = $false; status = '未确认当前 Aura 综合端，仅返回识别事实；未开始专项盘点。' }
		return
	}
	if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
		$shortCommit = ''
		if (Get-Command git -ErrorAction SilentlyContinue) {
			try { $shortCommit = [string](& git -C $root rev-parse --short=8 HEAD 2>$null) } catch { $shortCommit = '' }
		}
		if ($shortCommit -notmatch '^[0-9a-fA-F]{7,40}$') { $shortCommit = 'nogit-' + (Get-Date -Format 'HHmmss') }
		$baseName = '审查结果包-' + [IO.Path]::GetFileName($root) + '-' + $shortCommit + '-' + (Get-Date -Format 'yyyy-MM-dd')
		$reportPath = Join-Path $root $baseName
		$sequence = 2
		while (Test-Path -LiteralPath $reportPath) { $reportPath = Join-Path $root ($baseName + '-' + $sequence); $sequence++ }
		$out = Get-SafePath (Join-Path $reportPath '证据')
	} else {
		$out = Get-SafePath $OutputDirectory
		$reportPath = $out
	}
	if (Test-Within $root $out) {
		if ($out -eq $root -or $out.Substring($root.Length + 1) -notmatch '^审查结果包-[^\\/]+(?:[\\/]|$)') { throw '项目内输出仅允许根目录下专用审查结果包-*目录及其子目录；不能写入项目根或源码目录。' }
		$reportPath = Join-Path $root (($out.Substring($root.Length + 1) -split '[\\/]', 2)[0])
	}
	$destination = Get-LocalPath $out 'inventory.json'
	if (Test-Path -LiteralPath $destination) { throw 'inventory.json 已存在；使用新的盘点目录，不覆盖历史证据。' }
	$assets = New-Object 'System.Collections.Generic.List[object]'
	$candidates = New-Object 'System.Collections.Generic.List[object]'
	$failures = New-Object 'System.Collections.Generic.List[object]'
	$excluded = @{}
	$seen = @{}
	$queue = New-Object 'System.Collections.Generic.Queue[string]'
	if ($Scope.Count -eq 0) { $queue.Enqueue($root) }
	else {
		foreach ($part in $Scope) {
			if ($part -match '^(?:backend|server|审查结果包-[^\\/]+)(?:[\\/]|$)') { throw '指定范围不属于前端扫描对象。' }
			$queue.Enqueue((Get-LocalPath $root $part))
		}
	}
	$extensions = @('.vue', '.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.mts', '.cts', '.json', '.css', '.scss', '.less', '.html', '.yaml', '.yml')
	$sourceExtensions = @('.vue', '.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.mts', '.cts')
	$signals = @(
		@{ name = '直接请求'; rule = 'AURA-BASE-FE-006'; pattern = '\b(?:fetch\s*\(|axios\.(?:create|get|post|put|delete)\s*\()' },
		@{ name = '公共包内部路径'; rule = 'AURA-BASE-FE-021'; pattern = '@fxft/aura-web-kit/(?:src|dist)/' },
		@{ name = '旧联邦扫描插件'; rule = 'AURA-BASE-FE-023'; pattern = '\bstabilizeFederationModuleScan\s*\(' },
		@{ name = '原生表单调用'; rule = 'AURA-BASE-FE-019'; pattern = '\.(?:validate|resetFields|clearValidate)\s*\(' }
	)
	while ($queue.Count -gt 0) {
		$path = $queue.Dequeue()
		if ($seen.ContainsKey($path)) { continue }
		$seen[$path] = $true
		$relative = if ($path -eq $root) { '.' } else { $path.Substring($root.Length + 1).Replace('\', '/') }
		try { $item = Get-Item -LiteralPath $path -Force }
		catch { $failures.Add([ordered]@{ file = $relative; operation = 'stat'; error = $_.Exception.GetType().Name }); continue }
		$reason = $null
		if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $reason = '链接/junction 未读取' }
		elseif ($item.PSIsContainer -and $item.Name.StartsWith('审查结果包-')) { $reason = '审查结果包及证据不属于被审资产' }
		elseif ($item.PSIsContainer -and $relative -match '^(?:backend|server)$') { $reason = '非前端实现目录' }
		elseif ($item.PSIsContainer -and ($item.Name -in @('node_modules', 'dist', 'build', 'coverage', '证据') -or $item.Name.StartsWith('.')) -and $path -ne $root) { $reason = '依赖、生成物或隐藏目录' }
		elseif (-not $item.PSIsContainer -and ($item.Name -match '^(?:\.npmrc|\.yarnrc|\.env)(?:\.|$)' -or $item.Name -match '(?i)(?:credential|secret|token|password)' -or $item.Extension -in @('.pem', '.key', '.pfx', '.p12'))) { $reason = '敏感配置/凭据文件未读取' }
		elseif (-not $item.PSIsContainer -and $item.Extension -notin $extensions) { $reason = '非盘点类型' }
		if ($reason) { if (-not $excluded.ContainsKey($reason)) { $excluded[$reason] = 0 }; $excluded[$reason]++; continue }
		if ($item.PSIsContainer) {
			try { foreach ($child in @(Get-ChildItem -LiteralPath $path -Force | Sort-Object Name)) { $queue.Enqueue($child.FullName) } }
			catch { $failures.Add([ordered]@{ file = $relative; operation = 'enumerate'; error = $_.Exception.GetType().Name }) }
			continue
		}
		try {
			# SHA-256 不输出文件内容。大文件不读入内存进行候选扫描。
			$hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
			$scan = $item.Length -le 2000000 -and $item.Extension -in $sourceExtensions -and $item.Name -notmatch 'lock'
			$asset = [ordered]@{ file = $relative; sha256 = $hash; bytes = $item.Length; candidateScan = 'not-scanned' }
			$assets.Add($asset)
			if (-not $scan) { continue }
			$bytes = [IO.File]::ReadAllBytes($path)
			if ((Get-Hash $bytes) -ne $hash) { throw 'SourceChangedDuringRead' }
			$utf8 = New-Object Text.UTF8Encoding($false, $true)
			$content = $utf8.GetString($bytes)
			$lines = $content -split '\r?\n'
			for ($line = 0; $line -lt $lines.Count; $line++) {
				foreach ($signal in $signals) {
					foreach ($match in [regex]::Matches($lines[$line], $signal.pattern)) {
						$candidates.Add([ordered]@{ file = $relative; line = $line + 1; column = $match.Index + 1; signal = $signal.name; ruleHint = $signal.rule; sha256 = $hash; decision = '待补证' })
					}
				}
			}
			$asset.candidateScan = 'scanned'
		}
		catch { $failures.Add([ordered]@{ file = $relative; operation = 'hash-or-scan'; error = $_.Exception.GetType().Name }) }
	}
	$sorted = @($assets | Sort-Object { $_.file })
	$fingerprintInput = ($sorted | ForEach-Object { $_.file + "`t" + $_.sha256 }) -join "`n"
	$result = [ordered]@{
		formatVersion = '1.0.0'; kind = 'inventory-only'; capturedAt = [DateTimeOffset]::Now.ToString('o')
		reportDirectory = $reportPath
		identification = [ordered]@{ projectType = $identityType; matchedEvidence = $matched; missingEvidence = $missing; limitation = '多文件语法识别，Agent 仍需核对真实配置与调用关系。' }
		project = $root; scope = @($Scope); scopeKind = $(if ($Scope.Count) { 'limited' } else { 'project' })
		fingerprint = Get-Hash ([Text.Encoding]::UTF8.GetBytes($fingerprintInput))
		assets = $sorted; candidates = @($candidates.ToArray()); excluded = $excluded; failures = @($failures.ToArray())
		limitations = @('文件摘要与语法候选不是规则判定；零命中不表示通过。', '文件类型/目录排除与读取失败需由 Agent 补充盘点并说明覆盖边界。', '每次盘点独立；候选无 F/E/C 编号，复核时由 Agent 映射已有稳定 ID。')
	}
	$null = New-Item -ItemType Directory -Path $out -Force
	# CreateNew 防止并发或误用覆盖已有盘点。
	$stream = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
	$writer = New-Object IO.StreamWriter($stream, (New-Object Text.UTF8Encoding($false)))
	try { $writer.WriteLine(($result | ConvertTo-Json -Depth 10)) } finally { $writer.Dispose() }
	[pscustomobject]@{ action = 'Collect'; projectType = $identityType; reportDirectory = $reportPath; output = $destination; assets = $assets.Count; rawCandidates = $candidates.Count; failures = $failures.Count; status = '仅盘点，未完成审查' }
	return
}

$report = Get-SafePath $ReportDirectory
$contents = @{}
foreach ($name in $reportFiles) {
	$file = Get-LocalPath $report $name
	if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "缺少结果包文件：$name" }
	$body = [IO.File]::ReadAllText($file)
	if ([string]::IsNullOrWhiteSpace($body)) { throw "结果包文件为空：$name" }
	$contents[$name] = $body
	# 检查普通行内 Markdown 链接，不联网；锚点、引用式链接和语义由 Agent 核对。
	foreach ($match in [regex]::Matches($body, '\[[^\]\r\n]*\]\((?<target><[^>]+>|[^\s)]+)\)')) {
		$target = [Uri]::UnescapeDataString($match.Groups['target'].Value.Trim('<', '>'))
		if ($target.StartsWith('#') -or $target -match '^https?://') { continue }
		$target = ($target -split '#', 2)[0]
		$linked = Get-LocalPath $report $target
		if (-not (Test-Path -LiteralPath $linked)) { throw "结果包本地链接不存在：$name" }
	}
}
$catalog = Get-Content -LiteralPath (Join-Path $PSScriptRoot '../references/rules.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$matrix = $contents['02-规则核查矩阵.md']
$rows = @($matrix -split '\r?\n' | Where-Object { $_ -match '^\s*\|.*AURA-BASE-FE-\d{3}' })
$found = @{}
foreach ($row in $rows) {
	$ids = @([regex]::Matches($row, 'AURA-BASE-FE-\d{3}') | ForEach-Object Value | Select-Object -Unique)
	if ($ids.Count -ne 1) { throw '规则矩阵每行应对应一个原规则 ID。' }
	if ($found.ContainsKey($ids[0])) { throw '规则矩阵存在重复行。' }
	if ($row -notmatch '\|\s*(通过|偏差|未证实|不适用)\s*\|') { throw '规则矩阵缺少明确状态单元格。' }
	$found[$ids[0]] = $true
}
if (@(Compare-Object @($catalog.id | Sort-Object) @($found.Keys | Sort-Object)).Count) { throw '规则矩阵 ID 集合与随包规则不一致。' }
[pscustomobject]@{ action = 'Check'; files = $reportFiles.Count; rules = $found.Count; status = '结构检查通过'; limitations = '仅检查六文件非空、矩阵ID/状态格式和普通行内本地链接；统计闭合、取证覆盖、关联语义、复核、脱敏及质量结论仍须 Agent 核对。' }
