#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectPath,
    [string]$ModulePath = '.',
    [string]$OutputPath,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($ProjectPath)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { Write-Error 'ProjectPath 必须是已有目录'; exit 1 }
$module = [IO.Path]::GetFullPath((Join-Path $root $ModulePath))
$prefix = $root.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
if ($module -ne $root -and -not $module.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { Write-Error 'ModulePath 超出项目根目录'; exit 1 }
if (-not (Test-Path -LiteralPath $module -PathType Container)) { Write-Error 'ModulePath 必须是已有目录'; exit 1 }

function Rel([string]$Path) { [IO.Path]::GetRelativePath($root, $Path).Replace('\','/') }
function Clean-Code([string]$Text) {
    ($Text -replace '(?s)/\*.*?\*/','' -replace '(?m)//.*$','')
}
function Add-Finding([string]$RuleId, [string]$Level, [string]$Path, [string]$Message, [string]$Review) {
    $findings.Add([pscustomobject]@{ruleId=$RuleId;level=$Level;path=$Path;message=$Message;review=$Review})
}

$findings = [Collections.Generic.List[object]]::new()
$javaFiles = @(Get-ChildItem -LiteralPath $module -Recurse -File -Filter '*.java')
$entityFiles = @()
foreach ($file in $javaFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $code = Clean-Code $text
    $tableMatch = [regex]::Match($code, '@TableName\s*\(\s*(?:value\s*=\s*)?["'']([^"'']+)["'']')
    if (-not $tableMatch.Success) { continue }
    $classMatch = [regex]::Match($code, '\bclass\s+([A-Z][A-Za-z0-9_]*)\b')
    if (-not $classMatch.Success) { continue }
    $entity = [pscustomobject]@{file=$file;code=$code;className=$classMatch.Groups[1].Value;table=$tableMatch.Groups[1].Value}
    $entityFiles += $entity
    $mapperHit = $javaFiles | Where-Object {
        $m = Clean-Code (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8)
        $m -match "BaseMapper\s*<\s*$([regex]::Escape($entity.className))\s*>" -or $_.BaseName -eq ($entity.className + 'Mapper')
    } | Select-Object -First 1
    if (-not $mapperHit) { Add-Finding 'AURA-BASE-DATA-017-MAPPER' 'candidate' (Rel $file.FullName) "Entity $($entity.className) 未找到同模块 Mapper/Repository 证据" '确认项目是否使用其他公开数据访问入口；不能仅凭文件名判定违规' }
    $fieldMatches = [regex]::Matches($code, '(?m)(?<annotation>@TableField\s*\([^\)]*\)\s*)?private\s+[A-Za-z0-9_<>?, .]+\s+(?<name>[a-z][A-Za-z0-9_]*)\s*;')
    foreach ($fieldMatch in $fieldMatches) {
        $name = $fieldMatch.Groups['name'].Value
        if ($name -match '_' -and -not $fieldMatch.Groups['annotation'].Success) { Add-Finding 'AURA-BASE-DATA-017-NAMING' 'candidate' (Rel $file.FullName) "Java 字段 $name 含下划线且未看到 @TableField 映射" '确认是否由全局驼峰映射配置承担；需要保留明确列契约时补注解' }
    }
}

$migrationFiles = @(Get-ChildItem -LiteralPath $module -Recurse -File | Where-Object { $_.FullName -match '[\\/]db[\\/]migration[\\/].+\.(sql|xml)$' })
foreach ($entity in $entityFiles) {
    $migrationHit = $migrationFiles | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8) -match "(?i)\b$([regex]::Escape($entity.table))\b" } | Select-Object -First 1
    if (-not $migrationHit) { Add-Finding 'AURA-BASE-DATA-017-MIGRATION' 'candidate' (Rel $entity.file.FullName) "Entity $($entity.className) 对应表 $($entity.table) 未找到迁移脚本证据" '确认项目是否使用其他迁移目录或外部数据库版本库；不要仅凭缺少本地文件判定违规' }
}

$serviceFiles = @($javaFiles | Where-Object { $_.FullName -match '[\\/](service|application|usecase|use-case)[\\/]' })
foreach ($file in $serviceFiles) {
    $code = Clean-Code (Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8)
    if ($code -match '\b(JdbcTemplate|NamedParameterJdbcTemplate|DataSource|getConnection|createStatement)\b' -or $code -match '@(Select|Insert|Update|Delete)\b') {
        Add-Finding 'AURA-BASE-DATA-001' 'candidate' (Rel $file.FullName) 'Service/Application 文件出现直接数据库连接或 SQL 映射线索' '确认是否为受控数据访问适配器；Service 不应直接承担 SQL 和连接管理'
    }
}

$result = [ordered]@{
    schemaVersion = 1
    status = if ($findings.Count) { 'review_required' } else { 'no_deterministic_findings' }
    projectRoot = $root
    modulePath = $ModulePath
    scanned = [ordered]@{javaFiles=$javaFiles.Count;entityFiles=$entityFiles.Count;migrationFiles=$migrationFiles.Count;serviceFiles=$serviceFiles.Count}
    findings = @($findings)
    limitations = @('只检查静态文件和可识别的命名/调用线索；不证明事务、租户、索引、权限或迁移运行结果。','继承 Mapper、动态 SQL、外部迁移库和框架生成代码可能无法静态识别，必须人工核对。')
}
$jsonText = $result | ConvertTo-Json -Depth 8
if ($OutputPath) { [IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath), $jsonText, [Text.UTF8Encoding]::new($false)) }
if ($Json -or -not $OutputPath) { $jsonText }
if ($findings.Count) { exit 2 }
