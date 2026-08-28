# 技能结构与规范校验脚本

param(
  [string]$SkillPath = "$PSScriptRoot\..",
  [string]$SourceStandardsPath = ""
)

$ErrorActionPreference = "Stop"
$errors = @()
$warnings = @()
$resolvedSkillPath = (Resolve-Path -LiteralPath $SkillPath).Path

$required = @(
  "VERSION",
  "SKILL.md",
  "USAGE.md",
  "agents\openai.yaml",
  "references\frontend-design-workflow.md",
  "references\skill-dependency-workflow.md",
  "references\codex-browser-review-workflow.md",
  "knowledge\PIGX前端开发规范\README.md",
  "knowledge\PIGX前端开发规范\PIGX前端开发总览.md",
  "knowledge\PIGX前端开发规范\工程与代码生成规范.md",
  "knowledge\PIGX前端开发规范\路由与菜单规范.md",
  "knowledge\PIGX前端开发规范\模块联邦开发技术规范.md",
  "knowledge\PIGX前端开发规范\样式布局与静态资源规范.md",
  "knowledge\PIGX前端开发规范\组件复用与公司基础组件库规范.md",
  "knowledge\PIGX前端开发规范\开发检查清单.md",
  "knowledge\PIGX前端开发规范\公司组件库下载说明\.npmrc.example",
  "references\message-feedback-guidelines.md",
  "references\code-comment-guidelines.md",
  "references\admin-menu-permission-workflow.md",
  "recipes\hooks-standards.md",
  "checklists\pre-development.md",
  "checklists\implementation.md",
  "checklists\validation.md",
  "scripts\check-project-rules.ps1"
)

Write-Host "=== aura-pigx-web-develop 技能校验 ===" -ForegroundColor Cyan

foreach ($relativePath in $required) {
  $fullPath = Join-Path $resolvedSkillPath $relativePath
  if (-not (Test-Path -LiteralPath $fullPath)) {
    $errors += "缺少必要文件：$relativePath"
  }
}

$skillFile = Join-Path $resolvedSkillPath "SKILL.md"
$versionFile = Join-Path $resolvedSkillPath "VERSION"
$version = ""
$versionMarker = ""

if (Test-Path -LiteralPath $versionFile) {
  $version = (Get-Content -LiteralPath $versionFile -Raw -Encoding UTF8).Trim()
  $versionMarker = '当前版本：`' + $version + '`'
  if ($version -notmatch "^\d+\.\d+\.\d+$") {
    $errors += "VERSION 必须使用语义化版本号，例如 1.1.0"
  }
}

if (Test-Path -LiteralPath $skillFile) {
  $skillContent = Get-Content -LiteralPath $skillFile -Raw -Encoding UTF8

  if ($skillContent -notmatch "(?m)^name:\s*aura-pigx-web-develop\s*$") {
    $errors += "SKILL.md 缺少正确的 name"
  }

  if ($skillContent -notmatch "(?m)^description:\s*.+$") {
    $errors += "SKILL.md 缺少 description"
  }

  if ($skillContent -notmatch "knowledge/PIGX前端开发规范/README\.md") {
    $errors += "SKILL.md 未引用最新版 PIGX 规范入口"
  }

  if ($version -and -not $skillContent.Contains($versionMarker)) {
    $errors += "SKILL.md 展示版本与 VERSION 不一致"
  }

  $requiredMessageImport = "import { useMessage, useMessageBox } from '/@/hooks/message';"
  if (-not $skillContent.Contains($requiredMessageImport)) {
    $errors += "SKILL.md 未声明统一消息 Hook 的精确导入方式"
  }

  foreach ($keyword in @('el-table--fit', 'filterable', 'admin-menu-permission-workflow.md', 'aura-pigx-module-federation-check', 'v-auth', '用户明确指定', '首次调用提示', 'fmap-2d', 'fxft-video', 'frontend-design', '外部技能依赖预检', '明确授权不得执行安装', 'Codex 内置浏览器', 'browser:control-in-app-browser', '原型', '待决策', '左侧强调条')) {
    if (-not $skillContent.Contains($keyword)) {
      $errors += "SKILL.md 缺少关键规则：$keyword"
    }
  }

	foreach ($keyword in @('/@/hooks/form', 'clearFormValidate', 'resetForm')) {
		if (-not $skillContent.Contains($keyword)) {
			$errors += "SKILL.md 缺少表单 Hook 硬约束：$keyword"
		}
	}

  $frontmatterMatch = [regex]::Match($skillContent, "\A---\r?\n(?<body>.*?)\r?\n---", "Singleline")
  if (-not $frontmatterMatch.Success) {
    $errors += "SKILL.md YAML frontmatter 格式错误"
  } else {
    $frontmatterLines = $frontmatterMatch.Groups["body"].Value -split "\r?\n"
    foreach ($line in $frontmatterLines) {
      if ($line.Trim() -and $line -notmatch "^(name|description):") {
        $errors += "SKILL.md frontmatter 只允许 name 和 description：$line"
      }
    }
  }
}

$readmeFile = Join-Path $resolvedSkillPath "README.md"
if ($version -and (Test-Path -LiteralPath $readmeFile)) {
  $readmeContent = Get-Content -LiteralPath $readmeFile -Raw -Encoding UTF8
  if (-not $readmeContent.Contains($versionMarker)) {
    $errors += "README.md 展示版本与 VERSION 不一致"
  }
}

$markdownFiles = Get-ChildItem -LiteralPath $resolvedSkillPath -Recurse -File -Filter "*.md" |
  Where-Object { $_.FullName -notmatch "[\\/]\.planning[\\/]" }

foreach ($file in $markdownFiles) {
  $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $errors += "文件包含 UTF-8 BOM：$($file.FullName.Substring($resolvedSkillPath.Length + 1))"
  }
}

$codeGuidePaths = @(
  (Join-Path $resolvedSkillPath "templates"),
  (Join-Path $resolvedSkillPath "recipes")
)

foreach ($guidePath in $codeGuidePaths) {
  if (-not (Test-Path -LiteralPath $guidePath)) {
    continue
  }

  $guideFiles = Get-ChildItem -LiteralPath $guidePath -Recurse -File -Filter "*.md"
  foreach ($file in $guideFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($content -match 'from\s+[''"]@/') {
      $errors += "$($file.Name) 使用了错误的 @/ 别名"
    }
    if ($content -match 'import\s*\{[^}]*\b(ElMessage|ElMessageBox|MessageBox)\b[^}]*\}\s*from\s*[''"]element-plus[''"]') {
      $errors += "$($file.Name) 的代码示例直接导入 Element Plus 消息 API"
    }
  }
}

$usageFile = Join-Path $resolvedSkillPath "USAGE.md"
if (Test-Path -LiteralPath $usageFile) {
  $usageContent = Get-Content -LiteralPath $usageFile -Raw -Encoding UTF8
  foreach ($keyword in @('$aura-pigx-web-develop', '示例提示词', '@fxft/ui-plus')) {
    if (-not $usageContent.Contains($keyword)) { $errors += "USAGE.md 缺少关键说明：$keyword" }
  }
}

$openAiFile = Join-Path $resolvedSkillPath "agents\openai.yaml"
if ((Test-Path -LiteralPath $openAiFile) -and -not ((Get-Content -LiteralPath $openAiFile -Raw -Encoding UTF8).Contains('$aura-pigx-web-develop'))) {
  $errors += "agents/openai.yaml 默认提示未引用技能名"
}

$queryTemplate = Join-Path $resolvedSkillPath "templates\query-table-page.md"
if ((Test-Path -LiteralPath $queryTemplate) -and -not ((Get-Content -LiteralPath $queryTemplate -Raw -Encoding UTF8).Contains('el-table--fit'))) {
  $errors += "查询表格模板未声明 el-table--fit 规则"
}

$dialogTemplate = Join-Path $resolvedSkillPath "templates\dialog-form.md"
if ((Test-Path -LiteralPath $dialogTemplate) -and -not ((Get-Content -LiteralPath $dialogTemplate -Raw -Encoding UTF8).Contains('filterable'))) {
  $errors += "弹窗表单模板未声明 el-select filterable 规则"
}

$designGuide = Join-Path $resolvedSkillPath "references\frontend-design-workflow.md"
if (Test-Path -LiteralPath $designGuide) {
  $designContent = Get-Content -LiteralPath $designGuide -Raw -Encoding UTF8
  foreach ($keyword in @('$frontend-design', '视觉令牌', 'reduced-motion', '纯后端', '左侧强调条约束', '选中状态', '模板化重复')) {
    if (-not $designContent.Contains($keyword)) { $errors += "frontend-design 协作参考缺少关键内容：$keyword" }
  }
}

$skillDependencyGuide = Join-Path $resolvedSkillPath "references\skill-dependency-workflow.md"
if (Test-Path -LiteralPath $skillDependencyGuide) {
  $dependencyContent = Get-Content -LiteralPath $skillDependencyGuide -Raw -Encoding UTF8
  foreach ($keyword in @('可用技能列表', '是否授权我安装', '不得静默安装', '必需技能', 'vueuse-functions')) {
    if (-not $dependencyContent.Contains($keyword)) { $errors += "外部技能依赖流程缺少关键内容：$keyword" }
  }
}

$browserReviewGuide = Join-Path $resolvedSkillPath "references\codex-browser-review-workflow.md"
if (Test-Path -LiteralPath $browserReviewGuide) {
  $browserReviewContent = Get-Content -LiteralPath $browserReviewGuide -Raw -Encoding UTF8
  foreach ($keyword in @('Codex 内置浏览器', 'browser:control-in-app-browser', '用户明确意见', '待决策', '不得声称走查通过')) {
    if (-not $browserReviewContent.Contains($keyword)) { $errors += "Codex 内置浏览器走查参考缺少关键内容：$keyword" }
  }
}

$forbiddenBrowserPattern = '(?<!禁止使用)(?<!不得使用)(?<!不要使用)(?<!不使用)(?<!不能使用)(?<!不可使用)(?<!不再使用)/agent-browser'
foreach ($file in $markdownFiles) {
  $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  if ($content -match $forbiddenBrowserPattern) {
    $errors += "技能补充资料仍将 /agent-browser 作为调用方案：$($file.FullName.Substring($resolvedSkillPath.Length + 1))"
  }
}

$hooksGuide = Join-Path $resolvedSkillPath "recipes\hooks-standards.md"
if (Test-Path -LiteralPath $hooksGuide) {
	$hooksContent = Get-Content -LiteralPath $hooksGuide -Raw -Encoding UTF8
	foreach ($keyword in @('/@/hooks/form', 'clearFormValidate', 'resetForm', '所有业务表单必须使用')) {
		if (-not $hooksContent.Contains($keyword)) {
			$errors += "Hooks 规范缺少表单硬约束：$keyword"
		}
	}
}

$adminWorkflow = Join-Path $resolvedSkillPath "references\admin-menu-permission-workflow.md"
if (Test-Path -LiteralPath $adminWorkflow) {
  $adminContent = Get-Content -LiteralPath $adminWorkflow -Raw -Encoding UTF8
  foreach ($keyword in @('明确授权', 'Token', '运行时', 'v-auth', '真实页面菜单 ID', '精确查重', '重新查询', '用户明确指定', '相邻业务模块')) {
    if (-not $adminContent.Contains($keyword)) { $errors += "菜单权限参考缺少关键约束：$keyword" }
  }
}

$standardsRoot = Join-Path $resolvedSkillPath "knowledge\PIGX前端开发规范"
$standardFiles = Get-ChildItem -LiteralPath $standardsRoot -Recurse -File -Filter "*.md"
if ($standardFiles.Count -ne 20) {
	$errors += "最新版 PIGX 规范快照应包含 20 份 Markdown，当前为 $($standardFiles.Count) 份"
}

$npmrcExample = Join-Path $standardsRoot "公司组件库下载说明\.npmrc.example"
if (Test-Path -LiteralPath $npmrcExample) {
  $npmrcContent = Get-Content -LiteralPath $npmrcExample -Raw -Encoding UTF8
  if (-not $npmrcContent.Contains('${FXFT_NPM_AUTH}')) {
    $errors += ".npmrc.example 必须使用 FXFT_NPM_AUTH 环境变量占位符"
  }
  if ($npmrcContent -match "_auth=[A-Za-z0-9+/=]{12,}") {
    $errors += ".npmrc.example 禁止包含真实认证信息"
  }
}

if ($SourceStandardsPath) {
  $resolvedSourcePath = (Resolve-Path -LiteralPath $SourceStandardsPath).Path
  $sourceFiles = Get-ChildItem -LiteralPath $resolvedSourcePath -Recurse -File -Filter "*.md"

  foreach ($sourceFile in $sourceFiles) {
    $relativePath = $sourceFile.FullName.Substring($resolvedSourcePath.Length + 1)
    $targetFile = Join-Path $standardsRoot $relativePath

    if (-not (Test-Path -LiteralPath $targetFile)) {
      $errors += "规范快照缺少：$relativePath"
      continue
    }

    if ($relativePath -eq "公司组件库下载说明\README.md") {
      $targetContent = Get-Content -LiteralPath $targetFile -Raw -Encoding UTF8
      if ($targetContent -notmatch "\.npmrc\.example" -or $targetContent -match "_auth=[A-Za-z0-9+/=]{12,}") {
        $errors += "公司 UI 规范下载说明未正确使用脱敏 .npmrc.example"
      }
      continue
    }

    $sourceText = (Get-Content -LiteralPath $sourceFile.FullName -Raw -Encoding UTF8).Replace("`r`n", "`n").TrimEnd("`r", "`n")
    $targetText = (Get-Content -LiteralPath $targetFile -Raw -Encoding UTF8).Replace("`r`n", "`n").TrimEnd("`r", "`n")
    if ($sourceText -ne $targetText) {
      $errors += "规范快照与最新源文件不一致：$relativePath"
    }
  }
}

foreach ($warning in $warnings) {
  Write-Host "! $warning" -ForegroundColor Yellow
}

foreach ($errorItem in $errors) {
  Write-Host "✗ $errorItem" -ForegroundColor Red
}

if ($errors.Count -gt 0) {
  Write-Host "校验失败：共 $($errors.Count) 项错误" -ForegroundColor Red
  exit 1
}

Write-Host "✓ 校验通过" -ForegroundColor Green
