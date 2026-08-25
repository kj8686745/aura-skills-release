param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

function Read-TextFile {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return '' }
  return Get-Content -Raw -Encoding UTF8 $Path
}

function Write-Check {
  param(
    [string]$Level,
    [string]$Message
  )
  Write-Output "[$Level] $Message"
}

$failed = $false

Write-Output '# qiankun 静态验证'
Write-Output "ProjectRoot: $ProjectRoot"
Write-Output ''

$packagePath = Join-Path $ProjectRoot 'package.json'
$vitePath = Join-Path $ProjectRoot 'vite.config.ts'
$mainPath = Join-Path $ProjectRoot 'src/main.ts'
$routerPath = Join-Path $ProjectRoot 'src/router/index.ts'

if (Test-Path $packagePath) {
  $pkgText = Read-TextFile $packagePath
  $pkg = $pkgText | ConvertFrom-Json

  foreach ($scriptName in 'dev:qiankun','build:qiankun','preview:qiankun') {
    if ($pkg.scripts.PSObject.Properties.Name -contains $scriptName) {
      Write-Check 'OK' "package.json scripts.$scriptName"
    } else {
      Write-Check 'MISS' "package.json 缺少 scripts.$scriptName"
      $failed = $true
    }
  }

  $depNames = @()
  if ($pkg.dependencies) { $depNames += $pkg.dependencies.PSObject.Properties.Name }
  if ($pkg.devDependencies) { $depNames += $pkg.devDependencies.PSObject.Properties.Name }
  if ($depNames -contains 'vite-plugin-qiankun') {
    Write-Check 'OK' '已安装 vite-plugin-qiankun'
  } else {
    Write-Check 'MISS' '缺少 vite-plugin-qiankun 依赖'
    $failed = $true
  }
} else {
  Write-Check 'MISS' '缺少 package.json'
  $failed = $true
}

Write-Output ''
Write-Output '## vite.config.ts'
$viteText = Read-TextFile $vitePath
if ($viteText) {
  $checks = @(
    @{ Pattern = 'vite-plugin-qiankun'; Message = '引入 vite-plugin-qiankun' },
    @{ Pattern = 'VITE_QIANKUN_MODE'; Message = '读取 VITE_QIANKUN_MODE' },
    @{ Pattern = 'VITE_QIANKUN_PUBLIC_PATH'; Message = '读取 VITE_QIANKUN_PUBLIC_PATH' },
    @{ Pattern = 'Access-Control-Allow-Origin'; Message = '配置跨域响应头' }
  )
  foreach ($check in $checks) {
    if ($viteText.Contains($check.Pattern)) {
      Write-Check 'OK' $check.Message
    } else {
      Write-Check 'MISS' $check.Message
      $failed = $true
    }
  }

  if ($viteText -match 'base\s*:' -and $viteText -match 'isQiankun') {
    Write-Check 'OK' 'base 根据 qiankun 模式适配'
  } else {
    Write-Check 'MISS' 'base 未体现 qiankun 模式适配'
    $failed = $true
  }
} else {
  Write-Check 'MISS' '缺少 vite.config.ts'
  $failed = $true
}

Write-Output ''
Write-Output '## src/main.ts'
$mainText = Read-TextFile $mainPath
if ($mainText) {
  $checks = @(
    @{ Pattern = 'renderWithQiankun'; Message = '使用 renderWithQiankun' },
    @{ Pattern = 'qiankunWindow'; Message = '使用 qiankunWindow 判断运行环境' },
    @{ Pattern = 'bootstrap'; Message = '声明 bootstrap 生命周期' },
    @{ Pattern = 'mount'; Message = '声明 mount 生命周期' },
    @{ Pattern = 'unmount'; Message = '声明 unmount 生命周期' },
    @{ Pattern = "container?.querySelector?.('#app')"; Message = '挂载到底座 container 内 #app' },
    @{ Pattern = 'foundation-dev-web'; Message = '保留 foundation-dev-web 根类' },
    @{ Pattern = 'createAppRouter(getRouterBase(props))'; Message = '路由 base 使用 qiankun props 适配' }
  )
  foreach ($check in $checks) {
    if ($mainText.Contains($check.Pattern)) {
      Write-Check 'OK' $check.Message
    } else {
      Write-Check 'MISS' $check.Message
      $failed = $true
    }
  }
} else {
  Write-Check 'MISS' '缺少 src/main.ts'
  $failed = $true
}

Write-Output ''
Write-Output '## src/router/index.ts'
$routerText = Read-TextFile $routerPath
if ($routerText) {
  if ($routerText -match 'createAppRouter\s*=\s*\(base') {
    Write-Check 'OK' '导出 createAppRouter(base)'
  } else {
    Write-Check 'MISS' '缺少 createAppRouter(base)'
    $failed = $true
  }

  if ($routerText.Contains('createWebHistory(base)')) {
    Write-Check 'OK' 'createWebHistory 使用 base'
  } else {
    Write-Check 'MISS' 'createWebHistory 未使用 base'
    $failed = $true
  }
} else {
  Write-Check 'MISS' '缺少 src/router/index.ts'
  $failed = $true
}

if ($failed) {
  Write-Output ''
  Write-Output '[FAIL] qiankun 静态验证存在缺失项'
  exit 1
}

Write-Output ''
Write-Output '[PASS] qiankun 静态验证通过'
