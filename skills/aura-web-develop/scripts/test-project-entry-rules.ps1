# 回归 1.2.0 业务入口和浏览器/构建边界，测试夹具不接触业务项目。
$ErrorActionPreference = 'Stop'
$checker = Join-Path $PSScriptRoot 'check-project-rules.ps1'
$powerShellExe = (Get-Process -Id $PID).Path
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('aura-entry-rules-' + [guid]::NewGuid().ToString('N'))
$encoding = [Text.UTF8Encoding]::new($false)
New-Item -ItemType Directory -Path (Join-Path $testRoot 'src') -Force | Out-Null
try {
  $cases = @(
    @{ Name = '项目实例'; Code = "import { useMessage } from '/@/config/aura/index'; useMessage().success('ok');"; Exit = 0 },
    @{ Name = '公共表单'; Code = "import { useForm } from '@fxft/aura-web-kit/hooks/form'; const form = useForm();"; Exit = 0 },
    @{ Name = '旧消息入口'; Code = "import { useMessage } from '/@/hooks/message'; useMessage().success('ok');"; Exit = 1 },
    @{ Name = '旧请求入口'; Code = "import request from '/@/utils/request';"; Exit = 1 },
    @{ Name = '旧表单入口'; Code = "import { useForm } from '/@/hooks/form';"; Exit = 1 },
    @{ Name = '构建入口进入浏览器'; Code = "import { auraOptimizeDeps } from '@fxft/aura-web-kit/vite';"; Exit = 1 },
    @{ Name = '动态构建入口进入浏览器'; Code = "const build = import('@fxft/aura-web-kit/postcss');"; Exit = 1 }
  )
  foreach ($case in $cases) {
    [IO.File]::WriteAllText((Join-Path $testRoot 'src/example.ts'), $case.Code, $encoding)
    $output = & $powerShellExe -NoProfile -File $checker -ProjectPath $testRoot 2>&1
    if ($LASTEXITCODE -ne $case.Exit) { throw "$($case.Name) 退出码错误：$LASTEXITCODE；$output" }
  }
  Write-Host "✓ 1.2.0 项目入口回归通过：$($cases.Count) 个场景。" -ForegroundColor Green
} finally {
  $resolved = [IO.Path]::GetFullPath($testRoot)
  $tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
  if ($resolved.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolved)) {
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}
