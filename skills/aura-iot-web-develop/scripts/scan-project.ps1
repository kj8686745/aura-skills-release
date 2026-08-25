param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

Write-Output "# aura-iot-devWeb-develop 项目扫描"
Write-Output "ProjectRoot: $ProjectRoot"
Write-Output ""

$paths = @(
  'package.json',
  'vite.config.ts',
  'postcss.config.js',
  'src/main.ts',
  'src/App.vue',
  'src/router/index.ts',
  'src/utils/request.ts',
  'src/hooks/table.ts',
  'src/hooks/echarts.ts',
  'src/hooks/message.ts',
  'src/hooks/form.ts'
)

foreach ($relative in $paths) {
  $path = Join-Path $ProjectRoot $relative
  if (Test-Path $path) {
    Write-Output "[OK] $relative"
  } else {
    Write-Output "[MISS] $relative"
  }
}

Write-Output ""
Write-Output "## dependency check"
$pkgPath = Join-Path $ProjectRoot 'package.json'
if (Test-Path $pkgPath) {
  $pkg = Get-Content -Raw -Encoding UTF8 $pkgPath | ConvertFrom-Json
  $deps = @{}
  foreach ($p in $pkg.dependencies.PSObject.Properties) { $deps[$p.Name] = $p.Value }
  foreach ($p in $pkg.devDependencies.PSObject.Properties) { $deps[$p.Name] = $p.Value }
  foreach ($name in '@vueuse/core','echarts','element-plus','pinia','vue-router','vite-plugin-qiankun') {
    if ($deps.ContainsKey($name)) {
      Write-Output "[OK] $name $($deps[$name])"
    } else {
      Write-Output "[MISS] $name"
    }
  }
}
