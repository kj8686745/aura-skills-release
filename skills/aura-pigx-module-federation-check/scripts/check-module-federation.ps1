# PIGX 模块联邦项目类型识别与综合端审计入口

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)][string]$ProjectPath,
	[ValidateSet('Auto', 'Integrated', 'Provider', 'Consumer')][string]$ProjectType = 'Auto',
	[string[]]$ComponentPath = @(),
	[string]$ManifestPath = '',
	[switch]$Json
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\project-type.ps1')

function Write-MfReport {
	param(
		[Parameter(Mandatory = $true)]$Report,
		[switch]$AsJson
	)

	if ($AsJson) {
		$Report | ConvertTo-Json -Depth 8
		return
	}

	Write-Host '=== PIGX 模块联邦检查 ===' -ForegroundColor Cyan
	Write-Host "项目：$($Report.projectPath)"
	Write-Host "类型：$($Report.projectType)"
	Write-Host "状态：$($Report.status)"
	Write-Host '识别证据：'
	foreach ($item in $Report.evidence) { Write-Host "  - $item" }

	if ($Report.message) { Write-Host "`n$($Report.message)" -ForegroundColor Yellow }
	if ($Report.findings.Count -gt 0) {
		Write-Host "`n检查结果："
		foreach ($finding in $Report.findings) {
			$location = if ($finding.file) {
				if ($finding.line -gt 0) { "$($finding.file):$($finding.line)" } else { $finding.file }
			} else { '项目级' }
			$color = switch ($finding.severity) {
				'error' { 'Red' }
				'warning' { 'Yellow' }
				'manual' { 'DarkYellow' }
				default { 'Green' }
			}
			Write-Host "[$($finding.severity.ToUpper())] $($finding.ruleId) $location" -ForegroundColor $color
			Write-Host "  $($finding.message)"
			if ($finding.suggestion) { Write-Host "  建议：$($finding.suggestion)" }
		}
	}

	Write-Host "`n汇总：错误 $($Report.summary.error)，警告 $($Report.summary.warning)，人工确认 $($Report.summary.manual)，通过 $($Report.summary.pass)"
}

function New-MfReport {
	param(
		[string]$ResolvedProjectPath,
		[string]$DetectedType,
		[string[]]$Evidence,
		[string]$Status,
		[string]$Message,
		[object[]]$Findings = @()
	)

	$allFindings = @($Findings)
	[pscustomobject][ordered]@{
		projectPath = $ResolvedProjectPath
		projectType = $DetectedType
		status = $Status
		evidence = @($Evidence)
		message = $Message
		findings = $allFindings
		summary = [pscustomobject][ordered]@{
			error = @($allFindings | Where-Object severity -eq 'error').Count
			warning = @($allFindings | Where-Object severity -eq 'warning').Count
			manual = @($allFindings | Where-Object severity -eq 'manual').Count
			pass = @($allFindings | Where-Object severity -eq 'pass').Count
		}
	}
}

try {
	$resolvedProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
	$packagePath = Join-Path $resolvedProjectPath 'package.json'
	if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf)) {
		throw "项目中不存在 package.json：$resolvedProjectPath"
	}

	$typeResult = Get-MfProjectType -ProjectPath $resolvedProjectPath -RequestedType $ProjectType
	$detectedType = $typeResult.Type
	$evidence = @($typeResult.Evidence)

	if ($detectedType -eq 'Unknown') {
		$report = New-MfReport -ResolvedProjectPath $resolvedProjectPath -DetectedType $detectedType -Evidence $evidence `
			-Status 'Unrecognized' -Message '无法唯一识别项目端类型，未执行任何合规检查。'
		Write-MfReport -Report $report -AsJson:$Json
		exit 2
	}

	$handlerPath = Join-Path $PSScriptRoot "rules\$detectedType.ps1"
	$handlerName = "Invoke-$detectedType`Checks"
	if (-not (Test-Path -LiteralPath $handlerPath -PathType Leaf)) {
		$displayType = if ($detectedType -eq 'Provider') { '生产端' } elseif ($detectedType -eq 'Consumer') { '消费端' } else { $detectedType }
		$report = New-MfReport -ResolvedProjectPath $resolvedProjectPath -DetectedType $detectedType -Evidence $evidence `
			-Status 'Unsupported' -Message "已识别为$displayType；首版只支持 PIGX 综合端，已停止且未执行合规检查。"
		Write-MfReport -Report $report -AsJson:$Json
		exit 3
	}

	. $handlerPath
	$handler = Get-Command -Name $handlerName -CommandType Function -ErrorAction SilentlyContinue
	if (-not $handler) { throw "规则处理器未定义函数：$handlerName" }

	$findings = @(& $handlerName -ProjectPath $resolvedProjectPath -ComponentPath $ComponentPath -ManifestPath $ManifestPath)
	$errorCount = @($findings | Where-Object severity -eq 'error').Count
	if ($errorCount -eq 0) {
		$findings += New-MfFinding -RuleId 'MF-SUMMARY-001' -Severity 'pass' -Message 'PIGX 综合端静态合规检查未发现确定错误。' `
			-Suggestion '继续完成构建、独立运行和宿主加载验证。'
	}
	$status = if ($errorCount -gt 0) { 'Failed' } else { 'Passed' }
	$message = if ($errorCount -gt 0) { '综合端存在确定违规。' } else { '综合端静态检查通过。' }
	$report = New-MfReport -ResolvedProjectPath $resolvedProjectPath -DetectedType $detectedType -Evidence $evidence `
		-Status $status -Message $message -Findings $findings
	Write-MfReport -Report $report -AsJson:$Json
	if ($errorCount -gt 0) { exit 1 }
	exit 0
} catch {
	$failure = New-MfFinding -RuleId 'MF-TYPE-001' -Severity 'error' -Message $_.Exception.Message `
		-Suggestion '确认项目路径、JSON、脚本文件和读取权限后重试。'
	$report = New-MfReport -ResolvedProjectPath $ProjectPath -DetectedType 'Unknown' -Evidence @() -Status 'Error' `
		-Message '检查器无法启动或完成。' -Findings @($failure)
	Write-MfReport -Report $report -AsJson:$Json
	exit 2
}
