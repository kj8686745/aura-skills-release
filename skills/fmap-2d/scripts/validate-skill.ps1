# fmap-2d 技能结构校验脚本
# 用法：在 fmap-2d 目录下执行 .\scripts\validate-skill.ps1

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

function Test-FileMatches {
  param(
    [string]$RelativePath,
    [string]$Pattern,
    [string]$Description
  )

  $fullPath = Join-Path $Root $RelativePath
  if (-not (Test-Path $fullPath -PathType Leaf)) {
    $Errors.Add("无法检查格式，文件不存在：$RelativePath")
    return
  }

  $content = Get-Content -Path $fullPath -Raw -Encoding UTF8
  if ($content -notmatch $Pattern) {
    $Errors.Add("文件 $RelativePath 不满足格式要求：$Description")
  }
}

$requiredDirectories = @(
  "references",
  "templates",
  "checklists",
  "recipes",
  "scripts"
)

$requiredFiles = @(
  "SKILL.md",
  "README.md",
  "USAGE.md",
  "DESIGN.md",
  "references/project-profile.md",
  "references/ui-plus-installation.md",
  "references/map-component-guide.md",
  "references/map-business-rules.md",
  "templates/README.md",
  "templates/fxft-map-basic-page.md",
  "templates/fxft-map-points.md",
  "templates/fxft-map-track.md",
  "templates/fxft-map-heat.md",
  "templates/fxft-map-draw-geojson.md",
  "checklists/pre-development.md",
  "checklists/implementation.md",
  "checklists/validation.md",
  "recipes/install-and-resolver.md",
  "recipes/map-business-workflow.md",
  "recipes/map-data-normalization.md",
  "scripts/validate-skill.ps1"
)

foreach ($dir in $requiredDirectories) {
  Test-RequiredDirectory $dir
}

foreach ($file in $requiredFiles) {
  Test-RequiredFile $file
}

Test-FileContains "SKILL.md" "name: fmap-2d"
Test-FileMatches "SKILL.md" '(?m)^  version: "\d+\.\d+\.\d+"$' 'metadata.version 必须是语义化版本'
Test-FileContains "SKILL.md" "重要：先读哪些文件"
Test-FileContains "SKILL.md" "强制工作流"
Test-FileContains "SKILL.md" "当前项目硬性约束"
Test-FileContains "SKILL.md" "交付格式"
Test-FileContains "SKILL.md" "@fxft/ui-plus"
Test-FileContains "SKILL.md" "FxftMap"
Test-FileContains "SKILL.md" "不得自行引入"
Test-FileContains "references/ui-plus-installation.md" "FxftUiPlusResolver"
Test-FileContains "references/ui-plus-installation.md" "repository.fxft.online/repository/npm-public"
Test-FileContains "references/map-component-guide.md" "addPoint"
Test-FileContains "references/map-component-guide.md" "setPointLayerVisible"
Test-FileContains "references/map-component-guide.md" "setPointVisible"
Test-FileContains "references/map-component-guide.md" "updatePointSymbol"
Test-FileContains "references/map-component-guide.md" "forceRenderOnZooming"
Test-FileContains "references/map-component-guide.md" "animation: false"
Test-FileContains "references/map-component-guide.md" "playTrack"
Test-FileContains "references/map-component-guide.md" "setHeat"
Test-FileContains "references/map-component-guide.md" "renderGeoJSON"
Test-FileContains "references/map-component-guide.md" "setDrawSymbol"
Test-FileContains "references/map-component-guide.md" "initDraw"
Test-FileContains "templates/fxft-map-basic-page.md" "<FxftMap"
Test-FileContains "templates/fxft-map-points.md" "addPoint"
Test-FileContains "templates/fxft-map-track.md" "playTrack"
Test-FileContains "templates/fxft-map-heat.md" "setHeat"
Test-FileContains "templates/fxft-map-draw-geojson.md" "renderGeoJSON"
Test-FileContains "templates/fxft-map-draw-geojson.md" "setDrawSymbol"
Test-FileContains "templates/fxft-map-draw-geojson.md" "initDraw"
Test-FileContains "checklists/validation.md" "FxftUiPlusResolver"
Test-FileContains "recipes/map-data-normalization.md" "lon"
Test-FileContains "recipes/map-data-normalization.md" "lat"

if ($Errors.Count -gt 0) {
  Write-Host "fmap-2d 技能校验失败：" -ForegroundColor Red
  foreach ($item in $Errors) {
    Write-Host "- $item" -ForegroundColor Red
  }
  exit 1
}

Write-Host "fmap-2d 技能校验通过。" -ForegroundColor Green
