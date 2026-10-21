#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ProjectPath,[string[]]$ModulePath=@('.'),[string]$OutputPath,[switch]$Json)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'backend-common.ps1')
$unresolved=[Collections.Generic.List[object]]::new()
$builds=[Collections.Generic.List[object]]::new()
$sources=[Collections.Generic.List[object]]::new()
$config=[Collections.Generic.List[string]]::new();$docs=[Collections.Generic.List[string]]::new();$tests=[Collections.Generic.List[string]]::new()
function Get-XmlChild($Node,$Name){$child=@($Node.ChildNodes | Where-Object LocalName -eq $Name | Select-Object -First 1);if($child.Count){return $child[0].InnerText};return $null}
try{
  $scope=Get-BackendScope $ProjectPath $ModulePath
  foreach($file in $scope.files){
    $rel=[IO.Path]::GetRelativePath($scope.root,$file).Replace('\','/');$name=[IO.Path]::GetFileName($file)
    if($name -eq 'pom.xml'){
      try{
        $settings=[Xml.XmlReaderSettings]::new();$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null
        $reader=[Xml.XmlReader]::Create($file,$settings)
        try{$xml=[Xml.XmlDocument]::new();$xml.XmlResolver=$null;$xml.Load($reader)}finally{$reader.Dispose()}
        $deps=@(foreach($dep in $xml.GetElementsByTagName('dependency')){@{group=Get-XmlChild $dep 'groupId';artifact=Get-XmlChild $dep 'artifactId';version=Get-XmlChild $dep 'version';scope=Get-XmlChild $dep 'scope'}})
        $parent=@($xml.DocumentElement.ChildNodes | Where-Object LocalName -eq 'parent' | Select-Object -First 1)
        $builds.Add(@{path=$rel;kind='maven';artifact=Get-XmlChild $xml.DocumentElement 'artifactId';version=Get-XmlChild $xml.DocumentElement 'version';parent=$(if($parent.Count){@{group=Get-XmlChild $parent[0] 'groupId';artifact=Get-XmlChild $parent[0] 'artifactId';version=Get-XmlChild $parent[0] 'version'}}else{$null});declaredModules=@($xml.GetElementsByTagName('module') | ForEach-Object InnerText);dependencies=$deps})
      }catch{$unresolved.Add(@{path=$rel;reason='Maven XML 无法解析，不读取或执行外部实体'})}
    }elseif($name -in @('build.gradle','build.gradle.kts','settings.gradle','settings.gradle.kts')){
      $text=[IO.File]::ReadAllText($file)
      $deps=@([regex]::Matches($text,'(?m)\b(?:implementation|api|compileOnly|runtimeOnly|testImplementation)\s*(?:\(\s*)?["''](?<group>[\w.-]+):(?<artifact>[\w.-]+):(?<version>[^"''\s]+)["'']') | ForEach-Object {@{group=$_.Groups['group'].Value;artifact=$_.Groups['artifact'].Value;version=$_.Groups['version'].Value}})
      $builds.Add(@{path=$rel;kind='gradle';dependencies=$deps})
      $unresolved.Add(@{path=$rel;reason='仅提取字面依赖；Gradle DSL、插件和版本目录需核对，不执行构建'})
    }
    if($rel -match '(?i)(^|/)src/test/'){$tests.Add($rel);continue}
    if($name -match '^(application|bootstrap).*(\.ya?ml|\.properties)$'){$config.Add($rel)}
    if($rel -match '(?i)(^|/)docs/.*\.md$' -or $name -eq 'README.md'){$docs.Add($rel)}
    if($name -notlike '*.java'){continue}
    $text=[IO.File]::ReadAllText($file);$mask=Get-BackendMask $text
    foreach($type in [regex]::Matches($mask,'\b(?:class|interface|record|enum)\s+(?<name>\w+)')){
      $kind=if($mask -match '@(?:[\w.]+\.)?(RestController|Controller)\b'){'controller'}elseif($mask -match '@(?:[\w.]+\.)?Service\b'){'service'}elseif($mask -match '\b(BaseMapper|Repository|Mapper)\b'){'data-access'}elseif($mask -match '@(?:TableName|Entity)\b'){'entity'}else{'model-or-support'}
      $sources.Add(@{path=$rel;line=Get-BackendLine $text $type.Index;type=$type.Groups['name'].Value;role=$kind;supertypeExpression=([regex]::Match($mask.Substring($type.Index),'\b(?:extends|implements)\s+([^\{]+)').Groups[1].Value.Trim());applicationEntry=($mask -match '@SpringBootApplication\b')})
    }
  }
  if(-not $builds.Count){$unresolved.Add(@{path='';reason='范围内无 Maven/Gradle 构建声明；需核对父工程，不自动扩大扫描范围'})}
  if(-not $sources.Count){$unresolved.Add(@{path='';reason='未找到生产 Java 类型，不证明模块无后端实现'})}
  $api=Invoke-BackendApiInventory $scope
  foreach($issue in $api.unresolved){$unresolved.Add($issue)}
  foreach($path in $scope.skipped){$unresolved.Add(@{path=$path;reason='跳过重解析点'})}
  $result=[ordered]@{schemaVersion=1;status=$(if($unresolved.Count){'partial'}else{'complete'});project=$scope.root;modules=$ModulePath;builds=@($builds.ToArray());sources=@($sources.ToArray());configurationFiles=@($config.ToArray());documentation=@($docs.ToArray());testFiles=@($tests.ToArray());api=$api;unresolved=@($unresolved.ToArray());limitations=@('依赖为声明而非已解析依赖树；类型角色为静态线索；不输出配置值，不执行构建或访问服务。','只处理指定目录；父 POM、调用方、DTO 字段、网关改写与能力生效需继续核对。')}
  $code=if($unresolved.Count){2}else{0}
}catch{$result=@{schemaVersion=1;status='failed';unresolved=@(@{reason=$_.Exception.Message})};$code=1}
Write-BackendResult $result $OutputPath $Json "后端盘点：$($result.status)，源码类型=$($sources.Count)，构建声明=$($builds.Count)，待核实=$(@($result.unresolved).Count)"
exit $code
