#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [string]$ModulePath = '.',
    [ValidateRange(1024, 65535)]
    [int]$Port = 18080
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectPath).Path
$module = [IO.Path]::GetFullPath((Join-Path $root $ModulePath))
$pom = Join-Path $module 'pom.xml'
if (-not (Test-Path -LiteralPath $pom -PathType Leaf)) { throw 'Web 启动探针当前只支持 Maven 项目且缺少 pom.xml' }
$mvn = (Get-Command mvn.cmd -ErrorAction SilentlyContinue).Source
if (-not $mvn) { $mvn = (Get-Command mvn -ErrorAction SilentlyContinue).Source }
if (-not $mvn) { throw '未找到 Maven，请先配置 PATH 或 MAVEN_HOME' }

& $mvn -q -f $pom -DskipTests package
if ($LASTEXITCODE -ne 0) { throw 'Maven package 失败' }
$jar = Get-ChildItem -LiteralPath (Join-Path $module 'target') -File -Filter '*.jar' | Where-Object Name -notmatch 'original' | Select-Object -First 1
if ($null -eq $jar) { throw '未生成可启动 jar' }
$stdout = Join-Path $module 'startup-probe.out'
$stderr = Join-Path $module 'startup-probe.err'
$process = $null
try {
    $process = Start-Process -FilePath 'java' -ArgumentList @('-jar', $jar.FullName, "--server.port=$Port") -WorkingDirectory $jar.DirectoryName -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $deadline = (Get-Date).AddSeconds(30)
    $started = $false
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if ($process.HasExited) { break }
        $text = Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue
        if ($text -match "Tomcat started on port $Port") { $started = $true; break }
    }
    if (-not $started) { throw "未观察到 Tomcat $Port 启动日志" }
    $health = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/actuator/health" -TimeoutSec 5
    $content = if ($health.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($health.Content) } else { [string]$health.Content }
    $json = $content | ConvertFrom-Json
    if ([int]$health.StatusCode -ne 200 -or $json.status -ne 'UP') { throw "Actuator health 未返回 UP：$content" }
    [ordered]@{ status = 'passed'; projectRoot = $root; modulePath = $ModulePath; port = $Port; jar = $jar.Name; healthStatus = $json.status } | ConvertTo-Json -Depth 5
}
finally {
    if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force }
}
