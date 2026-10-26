#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,
    [string]$ModulePath = '.',
    [ValidateSet('Maven', 'Gradle')]
    [string]$BuildSystem = 'Maven',
    [Parameter(Mandatory = $true)]
    [string]$PackageName,
    [string]$JavaVersion,
    [string]$FrameworkVersion,
    [string]$ProjectVersion = '1.0.0',
    [switch]$IncludeWeb,
    [switch]$IncludeProjectEntry,
    [ValidateSet('Plan', 'Apply')]
    [string]$Mode = 'Plan'
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($ProjectPath)
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    if ($Mode -eq 'Apply') {
        New-Item -ItemType Directory -Path $root -Force | Out-Null
    } else {
        $parent = Split-Path -Parent $root
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { throw 'Plan 的项目根父目录不存在' }
    }
}
$module = [IO.Path]::GetFullPath((Join-Path $root $ModulePath))
$prefix = $root.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
if (-not $module.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and $module -ne $root) { throw 'ModulePath 超出项目根目录' }
if (-not (Test-Path -LiteralPath $module -PathType Container) -and $Mode -eq 'Apply') { New-Item -ItemType Directory -Path $module -Force | Out-Null }
if ($PackageName -notmatch '^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$') { throw 'PackageName 必须是完整 Java 包名' }
if ($ProjectVersion -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') { throw 'ProjectVersion 格式无效' }

$moduleName = [IO.Path]::GetFileName($module)
if ([string]::IsNullOrWhiteSpace($moduleName) -or $moduleName -eq '.') { $moduleName = 'backend-service' }
$artifactId = ($moduleName.ToLowerInvariant() -replace '[^a-z0-9-]+', '-') -replace '^-|-$', ''
if (-not $artifactId) { $artifactId = 'backend-service' }
$className = (($moduleName -split '[-_ ]+' | ForEach-Object { if ($_) { $_.Substring(0,1).ToUpperInvariant() + $_.Substring(1) } }) -join '') + 'Application'
$packagePath = $PackageName.Replace('.', [IO.Path]::DirectorySeparatorChar)

$files = [ordered]@{}
if ($BuildSystem -eq 'Maven') {
    $files['pom.xml'] = @"
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>$FrameworkVersion</version>
    <relativePath/>
  </parent>
  <groupId>$PackageName</groupId>
  <artifactId>$artifactId</artifactId>
  <version>$ProjectVersion</version>
  <properties>
    <java.version>$JavaVersion</java.version>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter</artifactId>
    </dependency>
$(if ($IncludeWeb) {
"    <dependency>`n      <groupId>org.springframework.boot</groupId>`n      <artifactId>spring-boot-starter-web</artifactId>`n    </dependency>"
"    <dependency>`n      <groupId>org.springframework.boot</groupId>`n      <artifactId>spring-boot-starter-actuator</artifactId>`n    </dependency>"
})
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
"@
} else {
    $files['settings.gradle'] = "rootProject.name = '$artifactId'`n"
    $files['build.gradle'] = @"
plugins {
    id 'java'
    id 'org.springframework.boot' version '$FrameworkVersion'
}

group = '$PackageName'
version = '$ProjectVersion'

java { toolchain { languageVersion = JavaLanguageVersion.of($JavaVersion) } }

repositories { mavenCentral() }

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter'
$(if ($IncludeWeb) { "    implementation 'org.springframework.boot:spring-boot-starter-web'`n    implementation 'org.springframework.boot:spring-boot-starter-actuator'" })
}
"@
}
$files["src/main/java/$packagePath/$className.java"] = @"
package $PackageName;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class $className {
    public static void main(String[] args) {
        SpringApplication.run($className.class, args);
    }
}
"@
$files['src/main/resources/application.yml'] = if ($IncludeWeb) {
"# 敏感值使用外部配置。`nspring:`n  application:`n    name: $artifactId`nmanagement:`n  endpoints:`n    web:`n      exposure:`n        include: health`n  endpoint:`n    health:`n      probes:`n        enabled: true`n"
} else {
"# 仅保留项目配置入口；敏感值使用外部配置。`n"
}
$files['README.md'] = @"
# $moduleName

## 作用

后端模块 $moduleName，职责需在接入业务前补充；当前仅生成工程启动骨架。

## 构建与启动

- 构建：$(if ($BuildSystem -eq 'Maven') { 'mvn -DskipTests package' } else { './gradlew build' })
- 启动：$(if ($BuildSystem -eq 'Maven') { 'java -jar target/' + $artifactId + '-' + $ProjectVersion + '.jar' } else { './gradlew bootRun' })
- 配置：`src/main/resources/application.yml`；敏感值不得写入仓库。

## 初始化基线

- 构建：$BuildSystem
- Java：$JavaVersion
- 框架版本：$FrameworkVersion
- 版本：$ProjectVersion
"@
if ($IncludeProjectEntry) {
    $files['__PROJECT__/README.md'] = "# 项目说明`n`n本项目包含后端模块 $ModulePath。构建：$(if ($BuildSystem -eq 'Maven') { 'mvn -f ' + $ModulePath + '/pom.xml -DskipTests package' } else { './gradlew build' })。`n"
    $files['__PROJECT__/docs/README.md'] = "# 文档入口`n`n按模块归档详细设计、接口和交付文档；后端模块：$ModulePath。`n"
}

$missing = @()
if ([string]::IsNullOrWhiteSpace($JavaVersion)) { $missing += 'JavaVersion' }
if ([string]::IsNullOrWhiteSpace($FrameworkVersion)) { $missing += 'FrameworkVersion' }
$planned = [Collections.Generic.List[object]]::new()
$existing = [Collections.Generic.List[string]]::new()
foreach ($entry in $files.GetEnumerator()) {
    $relative = $entry.Key
    $target = if ($relative.StartsWith('__PROJECT__/')) { Join-Path $root $relative.Substring(12) } else { Join-Path $module $relative }
    if (Test-Path -LiteralPath $target) { $existing.Add([IO.Path]::GetRelativePath($root, $target).Replace('\','/')); continue }
    $planned.Add([pscustomobject]@{ path = [IO.Path]::GetRelativePath($root, $target).Replace('\','/'); action = 'create' })
}

if ($Mode -eq 'Apply' -and $missing.Count) { throw ('Apply 需要明确版本参数：' + ($missing -join ', ')) }
if ($Mode -eq 'Apply') {
    foreach ($entry in $files.GetEnumerator()) {
        $relative = $entry.Key
        $target = if ($relative.StartsWith('__PROJECT__/')) { Join-Path $root $relative.Substring(12) } else { Join-Path $module $relative }
        if (Test-Path -LiteralPath $target) { continue }
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        [IO.File]::WriteAllText($target, [string]$entry.Value, [Text.UTF8Encoding]::new($false))
    }
}

$status = if ($Mode -eq 'Plan' -and $missing.Count) { 'needs-input' } elseif ($Mode -eq 'Apply') { 'applied' } else { 'ready' }
[ordered]@{
    schemaVersion = 1
    status = $status
    mode = $Mode
    projectRoot = $root
    modulePath = $ModulePath
    buildSystem = $BuildSystem
    packageName = $PackageName
    artifactId = $artifactId
    javaVersion = $JavaVersion
    frameworkVersion = $FrameworkVersion
    includeWeb = [bool]$IncludeWeb
    projectVersion = $ProjectVersion
    filesToCreate = @($planned)
    existingFiles = @($existing)
    missingDecisions = @($missing)
    limitations = @('脚本只生成最小工程入口，不生成业务 Controller、Service、Mapper、DTO 或能力专用目录。', '脚本不解析或猜测 BOM、公司模板、依赖坐标和真实能力版本；Apply 前必须提供真实版本。', '生成后必须运行 check-backend-project-init.ps1，并另行执行项目构建、启动和研发自测。')
} | ConvertTo-Json -Depth 8
