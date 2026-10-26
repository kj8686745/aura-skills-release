#requires -Version 7.0
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$skillRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$prepare = Join-Path $skillRoot 'scripts/prepare-backend-project.ps1'
$check = Join-Path $skillRoot 'scripts/check-backend-project-init.ps1'
$mvn = (Get-Command mvn.cmd -ErrorAction SilentlyContinue).Source
if (-not $mvn) { $mvn = (Get-Command mvn -ErrorAction SilentlyContinue).Source }
if (-not $mvn) { throw '未找到 Maven，无法执行启动验证' }
$root = Join-Path ([IO.Path]::GetTempPath()) ('aura-backend-startup-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
try {
    $null = & pwsh -NoProfile -File $prepare -ProjectPath $root -ModulePath service -BuildSystem Maven -PackageName com.example.service -JavaVersion 17 -FrameworkVersion 3.5.3 -IncludeProjectEntry -Mode Apply
    if ($LASTEXITCODE -ne 0) { throw '初始化脚本 Apply 失败' }
    $checkOutput = & pwsh -NoProfile -File $check -ProjectPath $root -ModulePath service -IncludeProjectEntry | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or $checkOutput.status -ne 'passed') { throw '初始化静态检查未通过' }
    & $mvn -q -f (Join-Path $root 'service/pom.xml') -DskipTests package
    if ($LASTEXITCODE -ne 0) { throw 'Maven package 失败' }
    $jar = Get-ChildItem -LiteralPath (Join-Path $root 'service/target') -File -Filter '*.jar' | Where-Object Name -notmatch 'original' | Select-Object -First 1
    if ($null -eq $jar) { throw '未生成可启动 jar' }
    $stdout = Join-Path $root 'startup.out'; $stderr = Join-Path $root 'startup.err'
    $process = Start-Process -FilePath 'java' -ArgumentList @('-jar', $jar.FullName, '--server.port=0') -WorkingDirectory $jar.DirectoryName -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $deadline = (Get-Date).AddSeconds(30); $started = $false
    while ((Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 500; if ($process.HasExited) { break }; if ((Get-Content $stdout -Raw -ErrorAction SilentlyContinue) -match 'Started\s+\w+Application') { $started = $true; break } }
    if ((Get-Content $stdout -Raw -ErrorAction SilentlyContinue) -match 'Started\s+\w+Application') { $started = $true }
    if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
    if (-not $started) { throw 'Spring Boot 启动探针未观察到 Started 日志' }
    Write-Output 'PASS backend startup probe'
}
finally { if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force } }
