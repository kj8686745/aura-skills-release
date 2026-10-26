#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [string]$ModulePath = '.',
    [switch]$IncludeProjectEntry,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectPath).Path
$module = [IO.Path]::GetFullPath((Join-Path $root $ModulePath))
$prefix = $root.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
if (-not $module.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and $module -ne $root) { throw 'ModulePath 超出项目根目录' }
if (-not (Test-Path -LiteralPath $module -PathType Container)) { throw 'ModulePath 不存在' }

$issues = [Collections.Generic.List[object]]::new()
function Add-Issue([string]$Level, [string]$Code, [string]$Path, [string]$Message) {
    $issues.Add([pscustomobject]@{ level = $Level; code = $Code; path = $Path; message = $Message })
}
function Test-Relative([string]$Base, [string]$Relative) {
    Test-Path -LiteralPath (Join-Path $Base $Relative)
}

$buildFiles = @('pom.xml', 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'settings.gradle.kts') | Where-Object { Test-Relative $module $_ }
if (-not $buildFiles.Count) { Add-Issue 'error' 'missing_build_entry' '' '未找到 Maven 或 Gradle 构建入口' }
if (-not (Test-Relative $module 'src/main/java')) { Add-Issue 'error' 'missing_java_source_root' 'src/main/java' '缺少后端 Java 源码根目录' }
if (-not (Test-Relative $module 'src/main/resources')) { Add-Issue 'incomplete' 'missing_resource_root' 'src/main/resources' '缺少后端资源目录；若项目不需要资源需人工说明' }
if (-not (Test-Relative $module 'README.md')) { Add-Issue 'incomplete' 'missing_module_readme' 'README.md' '缺少模块 README' } else {
    $moduleReadme = Get-Content -LiteralPath (Join-Path $module 'README.md') -Raw -Encoding UTF8
    if ($moduleReadme -match '待补充|TODO|TBD') { Add-Issue 'incomplete' 'incomplete_module_readme' 'README.md' '模块 README 仍为占位内容' }
    foreach ($requiredText in @('构建', '启动', '配置')) { if ($moduleReadme -notmatch [regex]::Escape($requiredText)) { Add-Issue 'incomplete' 'module_readme_missing_topic' 'README.md' "模块 README 缺少：$requiredText" } }
}
$javaFiles = if (Test-Relative $module 'src/main/java') { @(Get-ChildItem -LiteralPath (Join-Path $module 'src/main/java') -Recurse -File -Filter '*.java') } else { @() }
if ($javaFiles.Count -eq 0) {
    Add-Issue 'error' 'missing_java_source' 'src/main/java' '后端源码根目录没有 Java 源文件'
} else {
    $startupFiles = @($javaFiles | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -match '(?s)static\s+void\s+main\s*\(|SpringApplication\.run\s*\(' })
    if ($startupFiles.Count -eq 0) { Add-Issue 'incomplete' 'missing_startup_entry' 'src/main/java' '未识别到 main 或 SpringApplication.run 启动入口' }
}
$configFiles = if (Test-Relative $module 'src/main/resources') { @(Get-ChildItem -LiteralPath (Join-Path $module 'src/main/resources') -Recurse -File -Include 'application*.yml','application*.yaml','application*.properties','bootstrap*.yml','bootstrap*.yaml','bootstrap*.properties') } else { @() }
if ($configFiles.Count -eq 0) { Add-Issue 'incomplete' 'missing_runtime_config' 'src/main/resources' '未识别到 application/bootstrap 配置入口' }
$buildText = ($buildFiles | ForEach-Object { Get-Content -LiteralPath (Join-Path $module $_) -Raw -Encoding UTF8 }) -join "`n"
if ($buildText -match 'spring-boot-starter-web') {
    if ($buildText -notmatch 'spring-boot-starter-actuator') { Add-Issue 'incomplete' 'missing_web_health_dependency' 'pom.xml/build.gradle' 'Web 项目缺少 Actuator 健康检查依赖' }
    $configText = ($configFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"
    if ($configText -notmatch 'management:|management\.') { Add-Issue 'incomplete' 'missing_web_health_config' 'src/main/resources' 'Web 项目缺少健康检查配置' }
}
if ($buildFiles -contains 'build.gradle' -or $buildFiles -contains 'build.gradle.kts') {
    if ($buildText -notmatch 'mavenCentral\(\)') { Add-Issue 'incomplete' 'missing_gradle_repository' 'build.gradle' 'Gradle 构建缺少 mavenCentral 仓库配置' }
}
if ($IncludeProjectEntry) {
    if (-not (Test-Relative $root 'README.md')) { Add-Issue 'incomplete' 'missing_project_readme' 'README.md' '缺少项目根 README' } elseif ((Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw -Encoding UTF8) -match '待补充|TODO|TBD') { Add-Issue 'incomplete' 'incomplete_project_readme' 'README.md' '项目根 README 仍为占位内容' }
    if (-not (Test-Relative $root 'docs/README.md')) { Add-Issue 'incomplete' 'missing_project_docs_entry' 'docs/README.md' '缺少项目根 docs 入口' } elseif ((Get-Content -LiteralPath (Join-Path $root 'docs/README.md') -Raw -Encoding UTF8) -match '待补充|TODO|TBD') { Add-Issue 'incomplete' 'incomplete_project_docs_entry' 'docs/README.md' '项目 docs 入口仍为占位内容' }
}
$generatedDirectoryPattern = '(^|/)(target|build|out|\.gradle|node_modules)(/|$)'
$emptyDirs = @(Get-ChildItem -LiteralPath $module -Directory -Recurse -Force | Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0 } | ForEach-Object { [IO.Path]::GetRelativePath($root, $_.FullName).Replace('\','/') } | Where-Object { $_ -notmatch $generatedDirectoryPattern })
foreach ($dir in $emptyDirs) { Add-Issue 'incomplete' 'empty_directory' $dir '发现空目录，不应为未来功能预建目录' }

$status = if (@($issues | Where-Object level -eq 'error').Count) { 'failed' } elseif (@($issues | Where-Object level -eq 'incomplete').Count) { 'partial' } else { 'passed' }
$result = [ordered]@{
    schemaVersion = 1
    status = $status
    projectRoot = $root
    modulePath = $ModulePath
    buildFiles = @($buildFiles)
    sourceRoot = Test-Relative $module 'src/main/java'
    resourceRoot = Test-Relative $module 'src/main/resources'
    javaFileCount = $javaFiles.Count
    startupEntryCount = @($startupFiles).Count
    configurationFileCount = $configFiles.Count
    issues = @($issues)
    limitations = @('只检查后端工程入口、目录和文档位置；不执行构建、启动、数据库连接或联调。', '缺少资源目录可能是项目事实，也可能是初始化缺口，需人工确认。')
}
$result | ConvertTo-Json -Depth 8
if ($status -eq 'failed') { exit 1 }
if ($status -eq 'partial') { exit 2 }
exit 0
