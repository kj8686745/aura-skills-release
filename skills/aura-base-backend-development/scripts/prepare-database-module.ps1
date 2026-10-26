#requires -Version 7.0
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ProjectPath,
 [string]$ModulePath='.',
 [Parameter(Mandatory)][string]$PackageName,
 [Parameter(Mandatory)][string]$EntityName,
 [Parameter(Mandatory)][string]$TableName,
 [Parameter(Mandatory)][string]$FieldJson,
 [string]$QueryJson,
 [string]$CacheJson,
 [ValidateSet('Standalone','AuraBaseEntity')][string]$EntityMode='Standalone',
 [string]$MigrationVersion='V1',
 [ValidateSet('Plan','Apply')][string]$Mode='Plan'
)
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['*:ErrorAction']='Stop'
$root=[IO.Path]::GetFullPath($ProjectPath)
if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'ProjectPath 必须是已有项目目录'}
function Assert-Safe([string]$Path) {
 $cursor=$Path
 while($cursor){
  if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw "不支持重解析点路径：$cursor"}
  $cursor=[IO.Path]::GetDirectoryName($cursor)
 }
}
$module=[IO.Path]::GetFullPath((Join-Path $root $ModulePath))
$migrationRoot=[IO.Path]::GetFullPath((Join-Path $module 'src/main/resources/db/migration'))
$keywords=@('class','interface','public','private','protected','static','final','new','return','this','true','false','null')
if($PackageName-cnotmatch'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$'){throw 'PackageName 非法'}
if($EntityName-cnotmatch'^[A-Z][A-Za-z0-9]*$'-or$EntityName-cin$keywords){throw 'EntityName 非法'}
if($TableName-cnotmatch'^[a-z][a-z0-9_]*$'){throw 'TableName 非法'}
$fields=@((Get-Content -LiteralPath $FieldJson -Raw -Encoding UTF8)|ConvertFrom-Json)
if(!$fields.Count){throw '字段清单为空'}
$types=@('Long','Integer','String','Boolean','BigDecimal','LocalDate','LocalDateTime','Instant')
$sqlPattern='^(BIGINT|INT|INTEGER|SMALLINT|TINYINT|BOOLEAN|BOOL|DATE|TEXT|LONGTEXT|JSON|DATETIME(\([0-6]\))?|TIMESTAMP(\([0-6]\))?|(VARCHAR|CHAR)\([1-9][0-9]*\)|DECIMAL\([1-9][0-9]*,[0-9]+\))( UNSIGNED)?$'
$columnSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$javaSet=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function To-JavaName([string]$Name) {
 $parts=$Name -split '_'
 return $parts[0]+(($parts|Select-Object -Skip 1|ForEach-Object { if($_){$_.Substring(0,1).ToUpperInvariant()+$_.Substring(1)} }) -join '')
}
$normalized=foreach($field in $fields) {
 if($field.name-isnot[string]-or$field.name-cnotmatch'^[a-z][a-z0-9_]*$'){throw "字段名无效：$($field.name)"}
 if(!$columnSet.Add($field.name)){throw "数据库字段重复：$($field.name)"}
 if($field.javaType-cnotin$types){throw "不支持的 Java 类型：$($field.javaType)"}
 if($field.sqlType-isnot[string]-or$field.sqlType-cnotmatch$sqlPattern){throw "不支持的 SQL 类型：$($field.sqlType)"}
 if($field.nullable-isnot[bool]){throw "nullable 必须是布尔值：$($field.name)"}
 $javaName=if($field.PSObject.Properties.Name-ccontains'javaName'){$field.javaName}else{To-JavaName $field.name}
 if($javaName-isnot[string]-or$javaName-cnotmatch'^[a-z][A-Za-z0-9]*$'-or$javaName-cin$keywords){throw "Java 字段名无效：$javaName"}
 if(!$javaSet.Add($javaName)){throw "Java 字段名重复：$javaName"}
 if($field.primaryKey-and$field.nullable){throw '主键不能允许 NULL'}
 [pscustomobject]@{name=$field.name;javaName=$javaName;javaType=$field.javaType;sqlType=$field.sqlType;nullable=$field.nullable;primaryKey=($field.primaryKey-eq$true);autoIncrement=($field.autoIncrement-eq$true)}
}
$fields=@($normalized)
if(@($fields|Where-Object primaryKey).Count-ne 1){throw '字段清单必须有且只有一个主键'}
$queries = @()
$queryNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
if ($QueryJson) {
 $rawQueries = @(Get-Content -LiteralPath $QueryJson -Raw -Encoding UTF8 | ConvertFrom-Json)
 foreach ($query in $rawQueries) {
  if ($query.name -isnot [string] -or $query.name -cnotmatch '^[a-z][A-Za-z0-9]*$' -or $query.name -cin $keywords) { throw "查询方法名非法：$($query.name)" }
  if (-not $queryNames.Add($query.name)) { throw "查询方法名重复：$($query.name)" }
  if ($query.PSObject.Properties.Name -ccontains 'conditions') {
   if ($query.PSObject.Properties.Name -ccontains 'field') { throw 'conditions 和 field 不能同时使用' }
   $conditions = @($query.conditions)
  } elseif ($query.PSObject.Properties.Name -ccontains 'field') {
   $legacyCondition = [ordered]@{field=$query.field}
   if ($query.PSObject.Properties.Name -ccontains 'parameterName') { $legacyCondition.parameterName = $query.parameterName }
   $conditions = @([pscustomobject]$legacyCondition)
  } else { throw "查询必须提供 conditions 或 field：$($query.name)" }
  if (-not $conditions.Count) { throw "查询条件不能为空：$($query.name)" }
  $conditionNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $parameterNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $normalizedConditions = foreach ($condition in $conditions) {
   if ($condition.field -isnot [string] -or $condition.field -cnotmatch '^[a-z][a-z0-9_]*$') { throw "查询字段非法：$($condition.field)" }
   $queryField = @($fields | Where-Object { $_.name -ceq $condition.field })
   if ($queryField.Count -ne 1) { throw "查询字段不存在：$($condition.field)" }
   if (-not $conditionNames.Add($condition.field)) { throw "查询条件字段重复：$($condition.field)" }
   $parameterName = if ($condition.PSObject.Properties.Name -ccontains 'parameterName') { $condition.parameterName } else { $queryField[0].javaName }
   if ($parameterName -isnot [string] -or $parameterName -cnotmatch '^[a-z][A-Za-z0-9]*$' -or $parameterName -cin $keywords) { throw "查询参数名非法：$parameterName" }
   if (-not $parameterNames.Add($parameterName)) { throw "查询参数名重复：$parameterName" }
   [pscustomobject]@{field=$condition.field; parameterName=$parameterName; javaType=$queryField[0].javaType}
  }
  $primaryKey = ($fields | Where-Object primaryKey).name
  $orderBy = if ($query.PSObject.Properties.Name -ccontains 'orderBy') { $query.orderBy } else { $primaryKey }
  if ($orderBy -cnotin @($fields.name)) { throw "查询排序字段不存在：$orderBy" }
  $direction = if ($query.PSObject.Properties.Name -ccontains 'direction') { $query.direction } else { 'ASC' }
  if ($direction -cnotin @('ASC','DESC')) { throw '查询排序方向只能是 ASC 或 DESC' }
  if ($query.PSObject.Properties.Name -ccontains 'limit' -and $query.limit -isnot [bool]) { throw '查询 limit 必须是布尔值' }
  if ($query.limit -and $parameterNames.Contains('limit')) { throw 'limit 参数与查询条件参数冲突' }
  $maxRows = if ($query.PSObject.Properties.Name -ccontains 'maxRows') { $query.maxRows } else { 200 }
  if (($maxRows -isnot [int] -and $maxRows -isnot [long]) -or $maxRows -lt 1 -or $maxRows -gt 1000) { throw 'maxRows 必须是 1～1000 的整数' }
  $queries += [pscustomobject]@{name=$query.name;conditions=@($normalizedConditions);orderBy=$orderBy;direction=$direction;limit=($query.limit -eq $true);maxRows=$maxRows;primaryKey=$primaryKey}
 }
}
$scopeChecks = @()
if ($CacheJson) {
 if (-not $queries.Count) { throw '缓存范围核对需要 QueryJson' }
 $cacheContracts = @(Get-Content -LiteralPath $CacheJson -Raw -Encoding UTF8 | ConvertFrom-Json)
 foreach ($cache in $cacheContracts) {
  if ($cache.enabled -isnot [bool]) { throw '缓存 enabled 必须明确为布尔值' }
  if (-not $cache.enabled) { continue }
  if ($cache.category -cne 'query') { throw '此范围核对仅支持 query 缓存；其他状态不能冒充查询缓存' }
  $linked = @($queries | Where-Object { $_.name -ceq $cache.queryName })
  if ($linked.Count -ne 1) { throw "缓存缺少有效 queryName：$($cache.name)" }
  if ($cache.scopeFields -isnot [array] -or -not $cache.scopeFields.Count) { throw "缓存必须明确 scopeFields 数据库列数组：$($cache.name)" }
  foreach ($scopeField in $cache.scopeFields) {
   if ($scopeField -isnot [string] -or $scopeField -cnotin @($linked[0].conditions.field)) { throw "缓存范围字段未进入查询条件：$scopeField" }
  }
  $scopeChecks += [pscustomobject]@{cache=$cache.name;query=$cache.queryName;fields=@($cache.scopeFields);status='declared_conditions_matched'}
 }
}
$inherited=@{id='Long';createBy='String';updateBy='String';createTime='LocalDateTime';updateTime='LocalDateTime';delFlag='Long'}
if($EntityMode-eq'AuraBaseEntity'){
 foreach($name in $inherited.Keys){$found=@($fields|Where-Object{$_.javaName-ceq$name});if($found.Count-ne 1-or$found[0].javaType-cne$inherited[$name]){throw "AuraBaseEntity 缺少字段：$name"}}
 $idField=$fields|Where-Object{$_.javaName-ceq'id'}
 if(!$idField.primaryKey-or$idField.autoIncrement){throw 'AuraBaseEntity 模式要求 id 使用非自增分配策略'}
}
$templateRoot=Join-Path (Split-Path $PSScriptRoot -Parent) 'references/templates/database'
function Read-Template([string]$Name){Get-Content -LiteralPath (Join-Path $templateRoot $Name) -Raw -Encoding UTF8}
$imports=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal);$null=$imports.Add('com.baomidou.mybatisplus.annotation.TableName');$classSuffix=''
if($EntityMode-eq'AuraBaseEntity'){$null=$imports.Add('net.fxft.aura.common.data.model.BaseEntity');$classSuffix=' extends BaseEntity'}
$typeImports=@{BigDecimal='java.math.BigDecimal';LocalDate='java.time.LocalDate';LocalDateTime='java.time.LocalDateTime';Instant='java.time.Instant'};$fieldLines=@();$accessors=@();$sqlLines=@();$nl=[Environment]::NewLine
foreach($field in $fields){
 if($EntityMode-ne'AuraBaseEntity'-or-not$inherited.ContainsKey($field.javaName)){
  $null=$imports.Add('com.baomidou.mybatisplus.annotation.TableField');if($typeImports.ContainsKey($field.javaType)){$null=$imports.Add($typeImports[$field.javaType])}
  $annotation='    @TableField("'+$field.name+'")';if($field.primaryKey){$null=$imports.Add('com.baomidou.mybatisplus.annotation.TableId');$null=$imports.Add('com.baomidou.mybatisplus.annotation.IdType');$idType=if($field.autoIncrement){'AUTO'}else{'INPUT'};$annotation='    @TableId(value = "'+$field.name+'", type = IdType.'+$idType+')'}
  $fieldLines+=($annotation+$nl+'    private '+$field.javaType+' '+$field.javaName+';');$suffixName=$field.javaName.Substring(0,1).ToUpperInvariant()+$field.javaName.Substring(1);$accessors+=('    public '+$field.javaType+' get'+$suffixName+'() {'+$nl+'        return '+$field.javaName+';'+$nl+'    }'+$nl+$nl+'    public void set'+$suffixName+'('+$field.javaType+' '+$field.javaName+') {'+$nl+'        this.'+$field.javaName+' = '+$field.javaName+';'+$nl+'    }')
 }
 $notNull=if(!$field.nullable){' NOT NULL'}else{''};$primary=if($field.primaryKey){' PRIMARY KEY'}else{''};$auto=if($field.autoIncrement){' AUTO_INCREMENT'}else{''};$sqlLines+=('    '+$field.name+' '+$field.sqlType+$notNull+$auto+$primary)
}
$entity=(Read-Template 'Entity.java.tpl').Replace('{{PACKAGE}}',$PackageName).Replace('{{IMPORTS}}',($imports|Sort-Object|ForEach-Object{'import '+$_+';'})-join$nl).Replace('{{TABLE_NAME}}',$TableName).Replace('{{ENTITY_NAME}}',$EntityName).Replace('{{CLASS_SUFFIX}}',$classSuffix).Replace('{{FIELDS}}',$fieldLines-join($nl+$nl)).Replace('{{ACCESSORS}}',$accessors-join($nl+$nl))
$mapperImports = @(); $mapperMethods = @()
if ($queries.Count) {
 $mapperImports = @('import java.util.List;', 'import org.apache.ibatis.annotations.Param;', 'import org.apache.ibatis.annotations.Select;')
 $selectColumns = ($fields | ForEach-Object { '`'+$_.name+'` AS `'+$_.javaName+'`' }) -join ', '
 foreach ($query in $queries) {
  $params = @(); $where = @()
  foreach ($condition in $query.conditions) {
   if ($typeImports.ContainsKey($condition.javaType)) { $mapperImports += 'import '+$typeImports[$condition.javaType]+';' }
   $where += '`'+$condition.field+'` = #{'+$condition.parameterName+'}'
   $params += '@Param("'+$condition.parameterName+'") '+$condition.javaType+' '+$condition.parameterName
  }
  $order = ' ORDER BY `'+$query.orderBy+'` '+$query.direction
  if ($query.orderBy -cne $query.primaryKey) { $order += ', `'+$query.primaryKey+'` '+$query.direction }
  $limit = ' LIMIT '+$query.maxRows
  if ($query.limit) {
   $params += '@Param("limit") Integer limit'
   $limit = ' LIMIT #{limit}'
   $mapperMethods += '    // Caller must validate limit in 1..'+$query.maxRows+' before invocation.'
  }
  $sql = 'SELECT '+$selectColumns+' FROM `'+$TableName+'` WHERE '+($where -join ' AND ')+$order+$limit
  $mapperMethods += '    @Select("'+$sql.Replace('"','\"')+'")'+$nl+'    List<'+$EntityName+'> '+$query.name+'('+($params -join ', ')+');'
 }
 $mapperImports = @($mapperImports | Sort-Object -Unique)
}
$mapper=(Read-Template 'Mapper.java.tpl').Replace('{{PACKAGE}}',$PackageName).Replace('{{ENTITY_NAME}}',$EntityName).Replace('{{MAPPER_BASE_TYPE}}','com.baomidou.mybatisplus.core.mapper.BaseMapper').Replace('{{MAPPER_BASE_NAME}}','BaseMapper').Replace('{{MAPPER_IMPORTS}}',($mapperImports-join$nl)).Replace('{{MAPPER_METHODS}}',($mapperMethods-join($nl+$nl)))
$migration=(Read-Template 'migration.sql.tpl').Replace('{{TABLE_NAME}}',$TableName).Replace('{{COLUMN_DEFINITIONS}}',$sqlLines-join(','+$nl))
$files=[ordered]@{}
$files[[IO.Path]::GetFullPath((Join-Path $module ('src/main/java/'+$PackageName.Replace('.','/')+'/entity/'+$EntityName+'.java')))]=$entity
$files[[IO.Path]::GetFullPath((Join-Path $module ('src/main/java/'+$PackageName.Replace('.','/')+'/mapper/'+$EntityName+'Mapper.java')))]=$mapper
$files[[IO.Path]::GetFullPath((Join-Path $migrationRoot ($MigrationVersion+'__create_'+$TableName+'.sql')))]=$migration
function Ensure-SafeOutput([string]$p){
 $pre=$root.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
 if(-not$p.StartsWith($pre,[StringComparison]::OrdinalIgnoreCase)){throw '生成路径超出项目根目录'}
 Assert-Safe $p
}
$planned=[Collections.Generic.List[object]]::new();$existing=[Collections.Generic.List[string]]::new();$conflicts=[Collections.Generic.List[string]]::new()
foreach($entry in $files.GetEnumerator()){
 Ensure-SafeOutput $entry.Key;$relative=[IO.Path]::GetRelativePath($root,$entry.Key).Replace('\','/')
 if(Test-Path -LiteralPath $entry.Key){$existing.Add($relative);$isSame=(Test-Path -LiteralPath $entry.Key -PathType Leaf) -and ([IO.File]::ReadAllText($entry.Key).Replace([Environment]::NewLine,$nl) -ceq $entry.Value.Replace([Environment]::NewLine,$nl));if(-not $isSame){$conflicts.Add($relative)}}else{$planned.Add([pscustomobject]@{path=$relative;action='create'})}
}
$status=if($conflicts.Count){'blocked'}elseif(!$planned.Count){'unchanged'}elseif($Mode-eq'Apply'){'applied'}else{'ready'}
if($Mode-eq'Apply'-and !$conflicts.Count){
 foreach($entry in $files.GetEnumerator()){
  if(Test-Path -LiteralPath $entry.Key){continue}
   $null=New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($entry.Key)) -Force
  $stream=[IO.File]::Open($entry.Key,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$bytes=[Text.UTF8Encoding]::new($false).GetBytes($entry.Value);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
 }
}
[ordered]@{schemaVersion=2;status=$status;mode=$Mode;projectRoot=$root;modulePath=$ModulePath;entity=$EntityName;entityMode=$EntityMode;table=$TableName;fieldCount=$fields.Count;queryCount=$queries.Count;cacheScopeChecks=@($scopeChecks);filesToCreate=@($planned);existingFiles=@($existing);conflictingFiles=@($conflicts);limitations=@('只生成 Entity、Mapper 和迁移 SQL；不执行 SQL、不修改依赖。','AuraBaseEntity 仅在项目已核实当前公共实体契约时使用；事务、租户/组织、索引和复杂 SQL 不由本脚本推断。')}|ConvertTo-Json -Depth 8
if($conflicts.Count){exit 2}
