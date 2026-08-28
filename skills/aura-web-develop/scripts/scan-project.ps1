# PIGX 项目画像扫描脚本

param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath
)

$ErrorActionPreference = "Stop"
$resolvedProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path
$packageFile = Join-Path $resolvedProjectPath "package.json"
$sourceRoot = Join-Path $resolvedProjectPath "src"

if (-not (Test-Path -LiteralPath $packageFile)) {
  throw "未找到 package.json：$resolvedProjectPath"
}

if (-not (Test-Path -LiteralPath $sourceRoot)) {
  throw "未找到 src 目录：$resolvedProjectPath"
}

Write-Host "=== PIGX 项目扫描 ===" -ForegroundColor Cyan

$pkg = Get-Content -LiteralPath $packageFile -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host "`n[运行环境]"
Write-Host "  packageManager: $($pkg.packageManager)"
Write-Host "  engines.node: $($pkg.engines.node)"

Write-Host "`n[关键依赖]"
@(
  "vue",
  "vite",
  "element-plus",
  "pinia",
  "vue-router",
  "vue-i18n",
  "tailwindcss",
  "@module-federation/vite",
  "@module-federation/enhanced"
) | ForEach-Object {
  $dependencyName = $_
  $version = $pkg.dependencies.$dependencyName
  if (-not $version) {
    $version = $pkg.devDependencies.$dependencyName
  }
  if ($version) {
    Write-Host "  $dependencyName : $version"
  }
}

foreach ($section in @(
  @{ Name = "API 模块"; Path = "src\api"; Filter = "*.ts"; Recurse = $true },
  @{ Name = "Hooks"; Path = "src\hooks"; Filter = "*.ts"; Recurse = $false },
  @{ Name = "业务页面"; Path = "src\views"; Filter = "*.vue"; Recurse = $true }
)) {
  Write-Host "`n[$($section.Name)]"
  $sectionPath = Join-Path $resolvedProjectPath $section.Path
  if (-not (Test-Path -LiteralPath $sectionPath)) {
    Write-Host "  未找到目录"
    continue
  }

  Get-ChildItem -LiteralPath $sectionPath -File -Filter $section.Filter -Recurse:$section.Recurse |
    ForEach-Object {
      Write-Host "  $($_.FullName.Substring($resolvedProjectPath.Length + 1))"
    }
}

Write-Host "`n扫描完成。请继续读取最新版正式规范和真实类型定义。" -ForegroundColor Green
