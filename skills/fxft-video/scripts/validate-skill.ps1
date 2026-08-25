# fxft-video 技能结构校验脚本
# 用法：在 fxft-video 目录下执行 .\scripts\validate-skill.ps1

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Errors = New-Object System.Collections.Generic.List[string]

function Test-RequiredFile {
  param([string]$RelativePath)

  $fullPath = Join-Path $Root $RelativePath
  if (-not (Test-Path $fullPath -PathType Leaf)) {
    $Errors.Add("缺少必要文件：$RelativePath")
  }
}

function Test-RequiredDirectory {
  param([string]$RelativePath)

  $fullPath = Join-Path $Root $RelativePath
  if (-not (Test-Path $fullPath -PathType Container)) {
    $Errors.Add("缺少必要目录：$RelativePath")
  }
}

function Test-FileContains {
  param(
    [string]$RelativePath,
    [string]$Keyword
  )

  $fullPath = Join-Path $Root $RelativePath
  if (-not (Test-Path $fullPath -PathType Leaf)) {
    $Errors.Add("无法检查关键字，文件不存在：$RelativePath")
    return
  }

  $content = Get-Content -Path $fullPath -Raw -Encoding UTF8
  if ($content -notlike "*$Keyword*") {
    $Errors.Add("文件 $RelativePath 缺少关键字：$Keyword")
  }
}

$requiredDirectories = @(
  "references",
  "templates",
  "checklists",
  "recipes",
  "scripts"
  ,"agents"
)

$requiredFiles = @(
  "SKILL.md",
  "README.md",
  "USAGE.md",
  "agents/openai.yaml",
  "DESIGN.md",
  "references/project-profile.md",
  "references/ui-plus-installation.md",
  "references/video-component-guide.md",
  "references/video-business-rules.md",
  "templates/README.md",
  "templates/fxft-video-basic-page.md",
  "templates/fxft-video-ptz-page.md",
  "templates/fxft-video-playback-page.md",
  "templates/fxft-multi-video-basic-page.md",
  "templates/fxft-multi-video-draggable-page.md",
  "templates/fxft-multi-video-playback-page.md",
  "checklists/pre-development.md",
  "checklists/implementation.md",
  "checklists/validation.md",
  "recipes/install-and-resolver.md",
  "recipes/video-business-workflow.md",
  "recipes/single-video-integration.md",
  "recipes/multi-video-integration.md",
  "recipes/playback-and-state-handling.md",
  "scripts/validate-skill.ps1"
)

foreach ($dir in $requiredDirectories) {
  Test-RequiredDirectory $dir
}

foreach ($file in $requiredFiles) {
  Test-RequiredFile $file
}

Test-FileContains "SKILL.md" "name: fxft-video"
Test-FileContains "SKILL.md" "重要：先读哪些文件"
Test-FileContains "SKILL.md" "强制工作流"
Test-FileContains "SKILL.md" "当前项目硬性约束"
Test-FileContains "SKILL.md" "交付格式"
Test-FileContains "SKILL.md" "@fxft/ui-plus"
Test-FileContains "SKILL.md" "FxftVideoPlayer"
Test-FileContains "SKILL.md" "FxftMultiVideoPlayer"
Test-FileContains "SKILL.md" "不得绕过组件库"
Test-FileContains "SKILL.md" "PTZ"
Test-FileContains "SKILL.md" "拖拽换位"
Test-FileContains "SKILL.md" "首次调用提示"
Test-FileContains "SKILL.md" "1.0.36"
Test-FileContains "USAGE.md" '$fxft-video'
Test-FileContains "USAGE.md" "可复制提示词"
Test-FileContains "agents/openai.yaml" '$fxft-video'
Test-FileContains "references/ui-plus-installation.md" "FxftUiPlusResolver"
Test-FileContains "references/ui-plus-installation.md" "repository.fxft.online/repository/npm-public"
Test-FileContains "references/ui-plus-installation.md" "@fxft/ui-plus"
Test-FileContains "references/ui-plus-installation.md" "1.0.36"
Test-FileContains "references/video-component-guide.md" "playMode"
Test-FileContains "references/video-component-guide.md" "playVod"
Test-FileContains "references/video-component-guide.md" "ready"
Test-FileContains "references/video-component-guide.md" "error"
Test-FileContains "references/video-component-guide.md" "ptz"
Test-FileContains "references/video-component-guide.md" "playback-timestamp"
Test-FileContains "references/video-component-guide.md" "playWindow"
Test-FileContains "references/video-component-guide.md" "arrangeWindow"
Test-FileContains "references/video-component-guide.md" "setFullscreenMulti"
Test-FileContains "references/video-component-guide.md" "toggleSingleWindowContainerFullscreen"
Test-FileContains "references/video-component-guide.md" "uuid"
Test-FileContains "references/video-component-guide.md" "draggable"
Test-FileContains "references/video-component-guide.md" "不是公开 API"
Test-FileContains "references/video-component-guide.md" "多路组件未公开转发"
Test-FileContains "references/video-business-rules.md" "manualPlay"
Test-FileContains "references/video-business-rules.md" "visual order"
Test-FileContains "templates/fxft-video-basic-page.md" "<FxftVideoPlayer"
Test-FileContains "templates/fxft-video-basic-page.md" "@error"
Test-FileContains "templates/fxft-video-basic-page.md" "play-mode"
Test-FileContains "templates/fxft-video-ptz-page.md" "operateButtons"
Test-FileContains "templates/fxft-video-ptz-page.md" "@ptz"
Test-FileContains "templates/fxft-video-playback-page.md" "playback-timestamp"
Test-FileContains "templates/fxft-video-playback-page.md" "playback-seek"
Test-FileContains "templates/fxft-multi-video-basic-page.md" "<FxftMultiVideoPlayer"
Test-FileContains "templates/fxft-multi-video-basic-page.md" "videos"
Test-FileContains "templates/fxft-multi-video-basic-page.md" "split"
Test-FileContains "templates/fxft-multi-video-draggable-page.md" "draggable"
Test-FileContains "templates/fxft-multi-video-draggable-page.md" "drop"
Test-FileContains "templates/fxft-multi-video-draggable-page.md" "uuid"
Test-FileContains "templates/fxft-multi-video-playback-page.md" "playback-timestamp"
Test-FileContains "templates/fxft-multi-video-playback-page.md" "playWindow"
Test-FileContains "templates/fxft-multi-video-playback-page.md" "status-change"
Test-FileContains "checklists/validation.md" "FxftUiPlusResolver"
Test-FileContains "checklists/validation.md" "FxftVideoPlayer"
Test-FileContains "checklists/validation.md" "FxftMultiVideoPlayer"
Test-FileContains "checklists/validation.md" "拖拽换位"
Test-FileContains "checklists/validation.md" "录像"
Test-FileContains "checklists/validation.md" "全屏"
Test-FileContains "checklists/validation.md" "控制台无新增错误"

Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object {
  $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $Errors.Add("文件包含 UTF-8 BOM：$($_.FullName.Substring($Root.Length + 1))")
  }
}

Get-ChildItem -LiteralPath (Join-Path $Root 'scripts') -File -Filter '*.ps1' | ForEach-Object {
  $tokens = $null; $parseErrors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
  foreach ($parseError in $parseErrors) { $Errors.Add("PowerShell 语法错误：$($_.Name):$($parseError.Extent.StartLineNumber) $($parseError.Message)") }
}

if ($Errors.Count -gt 0) {
  Write-Host "fxft-video 技能校验失败：" -ForegroundColor Red
  foreach ($item in $Errors) {
    Write-Host "- $item" -ForegroundColor Red
  }
  exit 1
}

Write-Host "fxft-video 技能校验通过。" -ForegroundColor Green
