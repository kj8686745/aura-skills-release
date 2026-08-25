# 技能结构、编码、脚本语法和规范快照校验

[CmdletBinding()]
param(
	[string]$SkillPath = (Join-Path $PSScriptRoot '..'),
	[string]$SourceStandardsPath = ''
)

$ErrorActionPreference = 'Stop'
$errors = [System.Collections.Generic.List[string]]::new()
$resolvedSkillPath = (Resolve-Path -LiteralPath $SkillPath).Path
$requiredFiles = @(
	'VERSION',
	'SKILL.md',
	'agents/openai.yaml',
	'references/integrated-rule-matrix.md',
	'checklists/integrated-validation.md',
	'knowledge/PIGX前端开发规范/模块联邦开发技术规范.md',
	'scripts/check-module-federation.ps1',
	'scripts/lib/common.ps1',
	'scripts/lib/project-type.ps1',
	'scripts/rules/Integrated.ps1',
	'scripts/test-check-module-federation.ps1'
)

foreach ($relativePath in $requiredFiles) {
	if (-not (Test-Path -LiteralPath (Join-Path $resolvedSkillPath $relativePath) -PathType Leaf)) {
		[void]$errors.Add("缺少必要文件：$relativePath")
	}
}

$versionPath = Join-Path $resolvedSkillPath 'VERSION'
$skillFile = Join-Path $resolvedSkillPath 'SKILL.md'
$version = if (Test-Path -LiteralPath $versionPath) { (Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8).Trim() } else { '' }
if ($version -notmatch '^\d+\.\d+\.\d+$') { [void]$errors.Add('VERSION 必须使用语义化版本号。') }

if (Test-Path -LiteralPath $skillFile) {
	$skillContent = Get-Content -LiteralPath $skillFile -Raw -Encoding UTF8
	$frontmatter = [regex]::Match($skillContent, '\A---\r?\n(?<body>.*?)\r?\n---', 'Singleline')
	if (-not $frontmatter.Success) {
		[void]$errors.Add('SKILL.md frontmatter 格式错误。')
	} else {
		foreach ($line in ($frontmatter.Groups['body'].Value -split '\r?\n')) {
			if ($line.Trim() -and $line -notmatch '^(name|description):') {
				[void]$errors.Add("SKILL.md frontmatter 只允许 name 和 description：$line")
			}
		}
	}
	if ($skillContent -notmatch '(?m)^name:\s*aura-pigx-module-federation-check\s*$') { [void]$errors.Add('SKILL.md name 不正确。') }
	if ($skillContent -notmatch '(?m)^description:\s*\S.+$') { [void]$errors.Add('SKILL.md description 不能为空。') }
	if ($skillContent -match '\[TODO|TODO: Complete') { [void]$errors.Add('SKILL.md 仍包含初始化 TODO。') }
	if ($version -and -not $skillContent.Contains("当前版本：``$version``")) { [void]$errors.Add('SKILL.md 展示版本与 VERSION 不一致。') }
	if ($skillContent -match '(?m)^name:\s*(pigx-nexus|pigxNexus)\s*$') { [void]$errors.Add('技能名禁止使用模板项目占位名称。') }
}

$openAiPath = Join-Path $resolvedSkillPath 'agents\openai.yaml'
if (Test-Path -LiteralPath $openAiPath) {
	$openAiContent = Get-Content -LiteralPath $openAiPath -Raw -Encoding UTF8
	if (-not $openAiContent.Contains('$aura-pigx-module-federation-check')) { [void]$errors.Add('agents/openai.yaml 默认提示未显式引用技能名。') }
}

$textFiles = Get-ChildItem -LiteralPath $resolvedSkillPath -Recurse -File |
	Where-Object { $_.Extension -in @('.md', '.ps1', '.yaml', '.yml', '.txt') -or $_.Name -eq 'VERSION' }
foreach ($file in $textFiles) {
	$bytes = [System.IO.File]::ReadAllBytes($file.FullName)
	if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
		[void]$errors.Add("文件包含 UTF-8 BOM：$($file.FullName.Substring($resolvedSkillPath.Length + 1))")
	}
}

$scriptFiles = Get-ChildItem -LiteralPath (Join-Path $resolvedSkillPath 'scripts') -Recurse -File -Filter '*.ps1'
foreach ($file in $scriptFiles) {
	$tokens = $null
	$parseErrors = $null
	[System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
	foreach ($parseError in $parseErrors) {
		[void]$errors.Add("PowerShell 语法错误：$($file.Name):$($parseError.Extent.StartLineNumber) $($parseError.Message)")
	}
}

if ($SourceStandardsPath) {
	$sourceFile = Join-Path (Resolve-Path -LiteralPath $SourceStandardsPath).Path '模块联邦开发技术规范.md'
	$targetFile = Join-Path $resolvedSkillPath 'knowledge\PIGX前端开发规范\模块联邦开发技术规范.md'
	if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
		[void]$errors.Add("源规范不存在：$sourceFile")
	} elseif ((Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash) {
		[void]$errors.Add('模块联邦规范快照与源目录不一致。')
	}
}

foreach ($item in $errors) { Write-Host "✗ $item" -ForegroundColor Red }
if ($errors.Count -gt 0) {
	Write-Host "技能校验失败：共 $($errors.Count) 项。" -ForegroundColor Red
	exit 1
}

Write-Host "✓ aura-pigx-module-federation-check $version 技能校验通过。" -ForegroundColor Green
