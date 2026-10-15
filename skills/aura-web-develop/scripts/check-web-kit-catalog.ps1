# 对照目标项目已安装的发布包校验能力清单，不读取私服凭据或安装依赖。
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$PackagePath,
  [string]$CatalogPath = (Join-Path $PSScriptRoot '../knowledge/PIGX前端开发规范/aura-web-kit能力清单与接入规范.md')
)

$ErrorActionPreference = 'Stop'
$packageRoot = (Resolve-Path -LiteralPath $PackagePath).Path
$package = Get-Content -LiteralPath (Join-Path $packageRoot 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$catalog = Get-Content -LiteralPath $CatalogPath -Raw -Encoding UTF8
$errors = [System.Collections.Generic.List[string]]::new()
if ($package.name -ne '@fxft/aura-web-kit') { throw 'PackagePath 必须指向已安装的 @fxft/aura-web-kit 包目录。' }
if (-not $catalog.Contains('@fxft/aura-web-kit@' + $package.version)) {
  [void]$errors.Add("清单基线与实际安装版本不一致：$($package.version)")
}
$documented = @([regex]::Matches($catalog, '(?m)^\| `(?<entry>/[^`]+)` \|') | ForEach-Object { '.' + $_.Groups['entry'].Value })
$exports = @($package.exports.PSObject.Properties.Name)
foreach ($entry in $exports) {
  if ($documented -notcontains $entry) { [void]$errors.Add("清单漏项：$entry") }
  $declaration = $package.exports.PSObject.Properties[$entry].Value.types
  if (-not $declaration -or -not (Test-Path -LiteralPath (Join-Path $packageRoot $declaration) -PathType Leaf)) {
    [void]$errors.Add("公开入口缺少声明文件：$entry")
  }
}
foreach ($entry in $documented) {
  if ($exports -notcontains $entry) { [void]$errors.Add("清单包含非公开入口：$entry") }
}
foreach ($group in ($documented | Group-Object | Where-Object Count -gt 1)) {
  [void]$errors.Add("清单重复入口：$($group.Name)")
}
if ($errors.Count) {
  $errors | ForEach-Object { Write-Host "✗ $_" -ForegroundColor Red }
  exit 1
}
Write-Host "✓ web-kit $($package.version)：$($exports.Count) 个公开入口与清单一致，声明文件均存在。" -ForegroundColor Green
