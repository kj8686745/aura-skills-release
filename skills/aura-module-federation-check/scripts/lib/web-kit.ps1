# 只读取目标项目的 pnpm importer。共享锁的其他 importer 与 packages 快照都可能使用不同版本。
function Get-MfKitLock {
	param([string]$ProjectPath, [string]$Section)

	$root = Get-Item -LiteralPath $ProjectPath
	if (-not (Test-Path -LiteralPath (Join-Path $root.FullName 'pnpm-lock.yaml'))) {
		while ($root -and -not (Test-Path -LiteralPath (Join-Path $root.FullName 'pnpm-workspace.yaml'))) { $root = $root.Parent }
	}
	if (-not $root) { return }
	$lockPath = Join-Path $root.FullName 'pnpm-lock.yaml'
	if (-not (Test-Path -LiteralPath $lockPath -PathType Leaf)) { return }
	$importer = if ($root.FullName -eq $ProjectPath) { '.' } else { Get-MfRelativePath $root.FullName $ProjectPath }
	$lock = [ordered]@{ File = $lockPath; Importer = $importer; Specifier = ''; Version = '' }

	# 支持 pnpm 生成的分层 YAML；非标准布局保留空证据，交给包管理器复核。
	$inImporters = $inImporter = $inSection = $inPackage = $false
	foreach ($line in [System.IO.File]::ReadLines($lockPath)) {
		if ($line -match '^\s*(?:#.*)?$') { continue }
		if ($line -match '^\S') {
			if ($inImporters) { break }
			$inImporters = $line -match '^importers:\s*$'
		} elseif ($inImporters -and $line -match '^  (\S.*)$') {
			if ($inImporter) { break }
			$inImporter = $line.Trim().TrimEnd(':').Trim('"', "'") -ceq $importer
		} elseif ($inImporter -and $line -match '^    \S') {
			$inSection = $line.Trim() -ceq ($Section + ':')
			$inPackage = $false
		} elseif ($inSection -and $line -match '^      \S') {
			$inPackage = $line.Trim().TrimEnd(':').Trim('"', "'") -ceq '@fxft/aura-web-kit'
		} elseif ($inPackage -and $line -match '^        (specifier|version):\s*(?:''(?<value>[^'']*)''|"(?<value>[^"\\]*)"|(?<value>[^!&*{[\s#''"][^\s#]*))\s*(?:#.*)?$') {
			$value = $Matches.value
			if ($Matches[1] -eq 'specifier') { $lock.Specifier = $value }
			else { $lock.Version = ($value -split '\(', 2)[0] }
		}
	}
	return [pscustomobject]$lock
}

function Get-MfKitSemVer {
	param([string]$Value)

	# 元数据不参与优先级；区分预发布标记，避免将 rc 误当作同号正式版。
	$number = '(?:0|[1-9][0-9]*)'
	$prerelease = "(?:$number|[0-9a-zA-Z-]*[a-zA-Z-][0-9a-zA-Z-]*)"
	if ($Value -cnotmatch "^(?<core>$number\.$number\.$number)(?<pre>-$prerelease(?:\.$prerelease)*)?(?:\+[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*)?$") { return }
	$core = $null
	if ([version]::TryParse($Matches.core, [ref]$core)) {
		return [pscustomobject]@{ Core = $core; Pre = $Matches.pre; Text = $Value }
	}
}

function Test-MfKitDeclaration {
	param([string]$Declaration, $Resolved)

	# 只对可直接判定的常见声明给出布尔结果；catalog、别名及组合范围交由目标项目解析。
	if ($Declaration -ceq $Resolved.Text) { return $true }
	if ($Declaration -eq '*' -and -not $Resolved.Pre) { return $true }
	if ($Declaration -notmatch '^(?<op>\^|~|>=|<=|>|<|=)?\s*(?<value>\S+)$') { return }
	$op = $Matches.op
	$base = Get-MfKitSemVer $Matches.value
	if (-not $base -or $base.Pre -or $Resolved.Pre) { return }
	$version = $Resolved.Core
	$boundary = $base.Core
	switch ($op) {
		'>' { return $version -gt $boundary }
		'<' { return $version -lt $boundary }
		'>=' { return $version -ge $boundary }
		'<=' { return $version -le $boundary }
		'~' { return $version -ge $boundary -and $version.Major -eq $boundary.Major -and $version.Minor -eq $boundary.Minor }
		'^' {
			if ($boundary.Major -gt 0) { return $version -ge $boundary -and $version.Major -eq $boundary.Major }
			if ($boundary.Minor -gt 0) { return $version -ge $boundary -and $version.Major -eq 0 -and $version.Minor -eq $boundary.Minor }
			return $version -eq $boundary
		}
		default { return $version -eq $boundary }
	}
}

function Invoke-MfKitChecks {
	param($Findings, [string]$ProjectPath, $Package)

	$rule = @{ Findings = $Findings; RuleId = 'MF-DEP-004' }
	$packageName = '@fxft/aura-web-kit'
	$section = @('optionalDependencies', 'dependencies', 'devDependencies', 'peerDependencies') |
		Where-Object { $Package.$_ -and $Package.$_.PSObject.Properties[$packageName] } | Select-Object -First 1
	$declared = if ($section) { [string]$Package.$section.$packageName } else { '' }
	if (-not $declared) {
		Add-MfFinding @rule -Severity 'error' -Message '缺少 @fxft/aura-web-kit 直接依赖声明。' -File 'package.json'
	}
	$lock = Get-MfKitLock $ProjectPath $section
	$lockFile = if ($lock) { Get-MfRelativePath $ProjectPath $lock.File } else { 'pnpm-lock.yaml' }
	$resolved = Get-MfKitSemVer $lock.Version
	if (-not $lock.Specifier -or -not $resolved) {
		Add-MfFinding @rule -Severity 'manual' -Message "未取得当前项目 importer 的完整锁定声明和解析版本（$($lock.Importer)）。" -File $lockFile
	}
	if ($declared -and $lock.Specifier -and $declared -cne $lock.Specifier) {
		Add-MfFinding @rule -Severity 'error' -Message "依赖声明与 importer specifier 不一致：$declared / $($lock.Specifier)" -File $lockFile
	}
	if ($declared -and $resolved) {
		$matchesDeclaration = Test-MfKitDeclaration $declared $resolved
		if ($null -eq $matchesDeclaration) {
			Add-MfFinding @rule -Severity 'manual' -Message "请用项目包管理器核对声明 $declared 与锁定版本 $($resolved.Text) 的解析关系。" -File $lockFile
		} elseif (-not $matchesDeclaration) {
			Add-MfFinding @rule -Severity 'error' -Message "锁定版本 $($resolved.Text) 不满足声明 $declared。" -File $lockFile
		}
	}

	# 没有当前项目已安装包时，声明和锁定版本都不能作为实际安装证据。
	$installedFile = 'node_modules/@fxft/aura-web-kit/package.json'
	$packagePath = Join-Path $ProjectPath $installedFile
	try {
		$installed = Get-Content -LiteralPath $packagePath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
	} catch { $installed = $null }
	if ($installed.name -cne $packageName) {
		Add-MfFinding @rule -Severity 'manual' -Message '目标项目安装包身份未核实，请核对此项目实际解析的包路径、版本与公开入口。' -File $installedFile
		return
	}
	$actual = Get-MfKitSemVer $installed.version
	if (-not $actual) {
		Add-MfFinding @rule -Severity 'manual' -Message "无法解析实际安装版本：$($installed.version)" -File $installedFile
	} else {
		$minimum = [version]'1.12.1'
		if ($actual.Core -lt $minimum -or ($actual.Core -eq $minimum -and $actual.Pre)) {
			Add-MfFinding @rule -Severity 'error' -Message "web-kit 实际安装版本 $($actual.Text) 低于最低版本 $minimum。" -File $installedFile
		}
		if ($resolved -and $resolved.Text -cne $actual.Text) {
			Add-MfFinding @rule -Severity 'error' -Message "当前 importer 锁定版本 $($resolved.Text) 与实际安装版本 $($actual.Text) 不一致。" -File $installedFile
		} elseif (-not $resolved -and $declared -and $false -eq (Test-MfKitDeclaration $declared $actual)) {
			Add-MfFinding @rule -Severity 'error' -Message "实际安装版本 $($actual.Text) 不满足声明 $declared。" -File $installedFile
		}
	}

	# 只核验综合端的关键入口。条件映射、通配映射或隐式类型解析需要按实际加载条件补证。
	$packageRoot = Split-Path -Parent $packagePath
	foreach ($entry in @('./federation', './federation/config', './browser/assets', './vite', './postcss')) {
		$property = if ($installed.exports) { $installed.exports.PSObject.Properties[$entry] }
		if (-not $property) {
			$patterns = @($installed.exports.PSObject.Properties | Where-Object { $_ -and $_.Name.Contains('*') -and $entry -clike $_.Name })
			if ($patterns.Count) {
				Add-MfFinding @rule -Severity 'manual' -Message "请按安装包 exports 通配映射核验入口 $entry。" -File $installedFile
			} else {
				Add-MfFinding @rule -Severity 'error' -Message "已安装 web-kit 缺少显式公开入口：$entry" -File $installedFile
			}
			continue
		}
		$mapping = $property.Value
		if ($null -eq $mapping -or ($mapping -is [pscustomobject] -and @($mapping.PSObject.Properties).Count -eq 0)) {
			Add-MfFinding @rule -Severity 'error' -Message "已安装 web-kit 的公开入口 $entry 没有可加载的导出目标。" -File $installedFile
			continue
		}
		$runtime = if ($mapping -is [string]) { $mapping } elseif ($mapping.import) { $mapping.import } else { $mapping.default }
		$needsResolution = $false
		foreach ($target in @($runtime, $mapping.types)) {
			if ($target -isnot [string] -or $target -notmatch '^\./' -or $target -match '(^|/)\.\.(/|$)|\\') {
				$needsResolution = $true
				continue
			}
			if (-not (Test-Path -LiteralPath (Join-Path $packageRoot $target) -PathType Leaf)) {
				Add-MfFinding @rule -Severity 'error' -Message "安装包公开入口 $entry 指向缺失的文件：$target" -File $installedFile
			}
		}
		if ($needsResolution) {
			Add-MfFinding @rule -Severity 'manual' -Message "请核对 $entry 在项目使用条件下的实现与类型解析。" -File $installedFile
		}
	}
	return $installed
}
