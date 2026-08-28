function New-MfFinding {
	param(
		[Parameter(Mandatory = $true)][string]$RuleId,
		[Parameter(Mandatory = $true)][ValidateSet('error', 'warning', 'manual', 'pass')][string]$Severity,
		[Parameter(Mandatory = $true)][string]$Message,
		[string]$Suggestion = '',
		[string]$File = '',
		[int]$Line = 0
	)

	[pscustomobject][ordered]@{
		ruleId = $RuleId
		severity = $Severity
		file = $File
		line = $Line
		message = $Message
		suggestion = $Suggestion
	}
}

function Add-MfFinding {
	param(
		[Parameter(Mandatory = $true)]$Findings,
		[Parameter(Mandatory = $true)][string]$RuleId,
		[Parameter(Mandatory = $true)][ValidateSet('error', 'warning', 'manual', 'pass')][string]$Severity,
		[Parameter(Mandatory = $true)][string]$Message,
		[string]$Suggestion = '',
		[string]$File = '',
		[int]$Line = 0
	)

	[void]$Findings.Add((New-MfFinding -RuleId $RuleId -Severity $Severity -Message $Message -Suggestion $Suggestion -File $File -Line $Line))
}

function Get-MfRelativePath {
	param(
		[Parameter(Mandatory = $true)][string]$ProjectPath,
		[Parameter(Mandatory = $true)][string]$FilePath
	)

	$projectPrefix = $ProjectPath.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
	if ($FilePath.StartsWith($projectPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
		return $FilePath.Substring($projectPrefix.Length).Replace('\', '/')
	}

	return $FilePath.Replace('\', '/')
}

function Get-MfLineNumber {
	param(
		[Parameter(Mandatory = $true)][string]$Content,
		[Parameter(Mandatory = $true)][int]$Index
	)

	if ($Index -le 0) { return 1 }
	return ([regex]::Matches($Content.Substring(0, $Index), "`n").Count + 1)
}

function Get-MfProjectSourceFiles {
	param([Parameter(Mandatory = $true)][string]$ProjectPath)

	$sourceRoot = Join-Path $ProjectPath 'src'
	if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) { return @() }

	return @(
		Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
			Where-Object { $_.Extension -in @('.ts', '.tsx', '.js', '.jsx', '.mjs', '.mts', '.vue', '.css', '.scss') }
	)
}

function Get-MfProjectAuditFiles {
	param([Parameter(Mandatory = $true)][string]$ProjectPath)

	$files = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
	$rootNames = @('package.json', 'index.html', 'postcss.config.js', 'README.md')
	foreach ($name in $rootNames) {
		$path = Join-Path $ProjectPath $name
		if (Test-Path -LiteralPath $path -PathType Leaf) { [void]$files.Add((Get-Item -LiteralPath $path)) }
	}

	Get-ChildItem -LiteralPath $ProjectPath -File -Filter '.env*' -ErrorAction SilentlyContinue |
		ForEach-Object { [void]$files.Add($_) }
	Get-ChildItem -LiteralPath $ProjectPath -File -Filter 'vite.config.*' -ErrorAction SilentlyContinue |
		ForEach-Object { [void]$files.Add($_) }
	foreach ($file in (Get-MfProjectSourceFiles -ProjectPath $ProjectPath)) { [void]$files.Add($file) }

	return @($files | Sort-Object FullName -Unique)
}

function Get-MfPackageVersion {
	param(
		[Parameter(Mandatory = $true)]$Package,
		[Parameter(Mandatory = $true)][string]$Name
	)

	foreach ($sectionName in @('dependencies', 'devDependencies', 'peerDependencies')) {
		$section = $Package.PSObject.Properties[$sectionName]
		if (-not $section -or -not $section.Value) { continue }
		$property = $section.Value.PSObject.Properties[$Name]
		if ($property) { return [string]$property.Value }
	}

	return ''
}

function Get-MfFirstCapture {
	param(
		[string]$Content,
		[string]$Pattern,
		[string]$Group = 'value'
	)

	if (-not $Content) { return $null }
	$match = [regex]::Match($Content, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
	if (-not $match.Success) { return $null }

	[pscustomobject]@{
		Value = $match.Groups[$Group].Value
		Index = $match.Index
	}
}
