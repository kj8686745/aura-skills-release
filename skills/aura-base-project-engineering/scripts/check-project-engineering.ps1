#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$ProjectPath,
  [string[]]$ModulePath=@('.'),
  [switch]$IncludeProjectEntry,
  [string]$OutputPath,
  [switch]$Json
)
$ErrorActionPreference='Stop'
$issues=[Collections.Generic.List[object]]::new();$builds=[Collections.Generic.List[object]]::new()
$documents=[Collections.Generic.List[string]]::new();$configs=[Collections.Generic.List[string]]::new()
$files=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$directories=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$excluded=@('.git','.idea','.gradle','.codex','.agents','target','build','out','dist','node_modules')
function Add-Issue($Level,$Rule,$Path,$Line,$Code,$Message){$issues.Add(@{level=$Level;ruleId=$Rule;path=$Path;line=$Line;code=$Code;message=$Message})}
function Relative($Path){[IO.Path]::GetRelativePath($script:root,$Path).Replace('\','/')}
function In-Project([string]$Relative,[string]$Base=$script:root){
  if([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative)){throw '需要非空项目相对路径'}
  $target=[IO.Path]::GetFullPath((Join-Path $Base $Relative))
  if($target -ne $script:root -and -not $target.StartsWith($script:prefix,[StringComparison]::OrdinalIgnoreCase)){throw '路径超出项目根，未读取目标'}
  $cursor=$target
  while($cursor -and $cursor.Length -ge $script:root.Length){
    if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw '路径含重解析点，未读取目标'}
    $cursor=[IO.Path]::GetDirectoryName($cursor)
  }
  return $target
}
function Get-ChildText($Node,$Name){$child=@($Node.ChildNodes | Where-Object LocalName -eq $Name | Select-Object -First 1);if($child.Count){$child[0].InnerText}else{$null}}
function Test-ModuleReference($BuildPath,$Value,$RequiredFile){
  $rel=Relative $BuildPath
  if($Value -match '\$\{|[?*]') {Add-Issue incomplete 'AURA-BASE-BUILD-001' $rel 0 'dynamic_module' '模块表达式无法静态展开，需核对实际构建输入';return}
  try{$target=In-Project $Value ([IO.Path]::GetDirectoryName($BuildPath))}catch{Add-Issue incomplete 'AURA-BASE-DEP-003' $rel 0 'module_out_of_scope' $_.Exception.Message;return}
  if(-not (Test-Path -LiteralPath (Join-Path $target $RequiredFile) -PathType Leaf)){
    Add-Issue error 'AURA-BASE-BUILD-001' $rel 0 'missing_module_build' "已声明模块缺少构建入口：$Value/$RequiredFile"
  }
}
function Check-Document($Path){
  $rel=Relative $Path;$documents.Add($rel)
  $text=[IO.File]::ReadAllText($Path)
  # Keep line offsets but exclude fenced/inline examples and comments from link checks.
  $mask=[regex]::Replace($text,'(?ms)^\s*(`{3,}|~{3,})[^\r\n]*\r?\n.*?^\s*\1\s*$|<!--.*?-->|`[^`\r\n]+`',{param($m) [regex]::Replace($m.Value,'[^\r\n]',' ')})
  foreach($match in [regex]::Matches($mask,'\[[^\]\r\n]+\]\((?<href><[^>\r\n]+>|[^\s)]+)(?:\s+"[^"\r\n]*")?\)')){
    $href=$match.Groups['href'].Value.Trim('<','>');$line=1+[regex]::Matches($mask.Substring(0,$match.Index),"`n").Count
    if($href -match '^(?:https?://|mailto:|tel:|data:|//)'){continue}
    if($href -match '^[A-Za-z]:|^file:'){Add-Issue candidate 'AURA-BASE-DOC-008' $rel $line 'machine_path' '文档链接含本机绝对路径，核对是否应改为项目相对引用';continue}
    if($href -match '[()]|^/|\$\{'){Add-Issue incomplete 'AURA-BASE-DOC-008' $rel $line 'unsupported_link' '链接需要项目/生成器上下文或含复杂语法，未按失效处理';continue}
    if($href -match '^[A-Za-z][A-Za-z0-9+.-]*:'){Add-Issue incomplete 'AURA-BASE-DOC-008' $rel $line 'custom_scheme' '未校验自定义协议链接';continue}
    $parts=$href.Split('#',2);$pathPart=[Uri]::UnescapeDataString($parts[0])
    try{$target=if($pathPart){In-Project $pathPart ([IO.Path]::GetDirectoryName($Path))}else{$Path}}catch{Add-Issue incomplete 'AURA-BASE-DOC-008' $rel $line 'link_out_of_scope' $_.Exception.Message;continue}
    if(-not (Test-Path -LiteralPath $target)) {Add-Issue error 'AURA-BASE-DOC-008' $rel $line 'missing_link' "相对链接目标不存在：$href";continue}
    if($parts.Count -gt 1 -and $parts[1]){
      Add-Issue incomplete 'AURA-BASE-DOC-008' $rel $line 'anchor_unchecked' '目标路径存在，章节锚点需按文档渲染器复核'
    }
  }
  if($mask -match '(?m)^\s*\[[^\]]+\]:|\[[^\]\r\n]+\]\[[^\]\r\n]*\]'){
    Add-Issue incomplete 'AURA-BASE-DOC-008' $rel 0 'reference_links_unchecked' '存在引用式 Markdown 链接，未解析，不将未检查链接视为有效'
  }
}
try{
  $script:root=(Resolve-Path -LiteralPath $ProjectPath).Path
  if(-not (Test-Path -LiteralPath $root -PathType Container)){throw '项目根必须是目录'}
  $script:prefix=$root.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
  if(-not $ModulePath.Count){throw '至少指定一个模块目录'}
  $scopeRoots=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach($module in $ModulePath){
    $target=In-Project $module
    if(-not (Test-Path -LiteralPath $target -PathType Container)){throw "模块目录不存在：$module"}
    $null=$scopeRoots.Add($target)
    $pending=[Collections.Generic.Stack[string]]::new();$pending.Push($target)
    while($pending.Count){
      $dir=$pending.Pop();$null=$directories.Add($dir)
      foreach($item in Get-ChildItem -LiteralPath $dir -Force){
        if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){Add-Issue incomplete '' (Relative $item.FullName) 0 'reparse_skipped' '未沿重解析点扫描';continue}
        if($item.PSIsContainer){if($item.Name -notin $excluded){$pending.Push($item.FullName)}}else{$null=$files.Add($item.FullName)}
      }
    }
  }
  $checkRoot=$IncludeProjectEntry -or $scopeRoots.Contains($root)
  if($checkRoot){
    foreach($entry in @(@{path='README.md';rule='AURA-BASE-DOC-001'},@{path='docs/README.md';rule='AURA-BASE-DOC-002'})){
      $path=In-Project $entry.path
      if(Test-Path -LiteralPath $path -PathType Leaf){$null=$files.Add($path)}else{Add-Issue error $entry.rule $entry.path 0 'missing_project_entry' '缺少已纳入检查范围的项目入口'}
    }
    foreach($name in @('pom.xml','package.json','settings.gradle','settings.gradle.kts','build.gradle','build.gradle.kts','pnpm-workspace.yaml','pnpm-workspace.yml')){
      $path=In-Project $name
      if(Test-Path -LiteralPath $path -PathType Leaf){$null=$files.Add($path)}
    }
  }
  foreach($dir in $directories){
    if(-not @(Get-ChildItem -LiteralPath $dir -Force).Count){Add-Issue candidate 'AURA-BASE-STRUCT-004' (Relative $dir) 0 'empty_directory' '空目录需核对真实职责或框架扩展依据，不自动删除'}
    if([IO.Path]::GetFileName($dir) -eq 'docs' -and $dir -ne (Join-Path $root 'docs')){
      $docPrefix=$dir.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
      $hasDocs=@($files | Where-Object { $_.StartsWith($docPrefix,[StringComparison]::OrdinalIgnoreCase) -and $_ -like '*.md' }).Count
      if($hasDocs -and -not (Test-Path -LiteralPath (Join-Path $dir 'README.md') -PathType Leaf)){Add-Issue error 'AURA-BASE-DOC-003' (Relative $dir) 0 'missing_module_doc_entry' '模块已有独立文档但缺 docs/README.md 入口'}
    }
  }
  foreach($file in ($files | Sort-Object)){
    $name=[IO.Path]::GetFileName($file);$rel=Relative $file
    if($name -eq 'pom.xml'){
      try{
        $settings=[Xml.XmlReaderSettings]::new();$settings.DtdProcessing=[Xml.DtdProcessing]::Prohibit;$settings.XmlResolver=$null
        $reader=[Xml.XmlReader]::Create($file,$settings)
        try{$xml=[Xml.XmlDocument]::new();$xml.XmlResolver=$null;$xml.Load($reader)}finally{$reader.Dispose()}
        if($xml.DocumentElement.LocalName -ne 'project'){throw '不是 Maven project 根元素'}
        $moduleNode=@($xml.DocumentElement.ChildNodes | Where-Object LocalName -eq 'modules')
        $modules=@(foreach($node in $moduleNode){$node.ChildNodes | Where-Object LocalName -eq 'module' | ForEach-Object InnerText})
        $builds.Add(@{path=$rel;kind='maven';artifact=Get-ChildText $xml.DocumentElement 'artifactId';version=Get-ChildText $xml.DocumentElement 'version';modules=$modules})
        foreach($value in $modules){Test-ModuleReference $file $value 'pom.xml'}
        if(@($xml.GetElementsByTagName('profile')).Count){Add-Issue incomplete 'AURA-BASE-BUILD-001' $rel 0 'maven_profiles' '未计算 profile 激活及继承结果，按实际命令核对'}
      }catch{Add-Issue error 'AURA-BASE-BUILD-002' $rel 0 'invalid_maven_xml' 'Maven XML 无法解析或包含禁用的外部实体'}
    }elseif($name -eq 'package.json'){
      try{
        $package=[IO.File]::ReadAllText($file) | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        if($package -isnot [Collections.IDictionary]){throw 'package.json 根必须为对象'}
        $workspaces=if($package.workspaces -is [Collections.IDictionary]){@($package.workspaces.packages)}else{@($package.workspaces)}
        $workspaces=@($workspaces | Where-Object {$_ -is [string]})
        $builds.Add(@{path=$rel;kind='node';name=$package.name;packageManager=$package.packageManager;scriptNames=@($(if($package.scripts){$package.scripts.Keys}) | Sort-Object);workspaces=$workspaces})
        foreach($value in $workspaces){Test-ModuleReference $file $value 'package.json'}
      }catch{Add-Issue error 'AURA-BASE-BUILD-002' $rel 0 'invalid_package_json' 'package.json 无法解析，未执行其中脚本'}
    }elseif($name -in @('settings.gradle','settings.gradle.kts','build.gradle','build.gradle.kts','pnpm-workspace.yaml','pnpm-workspace.yml')){
      $builds.Add(@{path=$rel;kind='declarative-or-dsl'})
      Add-Issue incomplete 'AURA-BASE-BUILD-001' $rel 0 'build_dsl_unchecked' '仅识别构建入口，未执行或解释 DSL/workspace YAML'
    }
    if($name -match '^(application|bootstrap).*(\.ya?ml|\.properties)$|^\.env(?:\..*)?$'){$configs.Add($rel)}
    if($name -like '*.md'){Check-Document $file}
  }
  $errors=@($issues | Where-Object level -eq error).Count;$review=@($issues | Where-Object level -ne error).Count
  $result=[ordered]@{schemaVersion=1;status=$(if($errors){'failed'}elseif($review){'needs-review'}else{'scan-complete'});project=$root;scope=@{modules=$ModulePath;projectEntry=$checkRoot;exclusions=$excluded};builds=@($builds.ToArray());documents=@($documents.ToArray());configurationFiles=@($configs.ToArray());summary=@{errors=$errors;review=$review};issues=@($issues.ToArray());limitations=@('仅静态路径、可解析构建声明和直接 Markdown 链接；不检查文档充分性、模板匹配、依赖树、所有循环依赖或运行行为。','配置只列路径；不联网、不执行构建、安装或 package scripts。范围内没有构建声明不代表项目没有构建入口，父工程需按任务另行读取。')}
  $code=if($errors){1}elseif($review){2}else{0}
}catch{$result=@{schemaVersion=1;status='failed';summary=@{errors=1;review=0};issues=@(@{code='input_or_execution_error';message=$_.Exception.Message})};$code=1}
$body=$result | ConvertTo-Json -Depth 14
if($OutputPath){[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath),$body,[Text.UTF8Encoding]::new($false))}
if($Json){$body}else{"工程检查：$($result.status)，确定错误=$($result.summary.errors)，待复核=$($result.summary.review)"}
exit $code
