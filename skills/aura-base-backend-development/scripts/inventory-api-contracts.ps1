#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$ProjectPath,
  [string[]]$ModulePath = @('.'),
  [string]$OutputPath,
  [switch]$Json
)
$ErrorActionPreference = 'Stop'
$routes = [Collections.Generic.List[object]]::new()
$unresolved = [Collections.Generic.List[object]]::new()
$filesChecked = [Collections.Generic.List[string]]::new()

function Add-Unresolved($Path, $Line, $Reason) { $unresolved.Add(@{path=$Path;line=$Line;reason=$Reason}) }
function Mask-Java([string]$Text) {
  # Preserve offsets/newlines while masking comments and literals, including text blocks.
  $chars = $Text.ToCharArray()
  $pattern = '(?s)/\*.*?\*/|//[^\r\n]*|""".*?"""|"(?:\\.|[^"\\])*"|''(?:\\.|[^''\\])*'''
  foreach ($m in [regex]::Matches($Text,$pattern)) {
    for($i=$m.Index;$i -lt $m.Index+$m.Length;$i++){if($chars[$i] -notin @("`r","`n")){$chars[$i]=' '}}
  }
  return -join $chars
}
function Find-Close([string]$Mask,[int]$Start,[char]$Open,[char]$Close) {
  $depth=0
  for($i=$Start;$i -lt $Mask.Length;$i++) {
    if($Mask[$i] -eq $Open){$depth++} elseif($Mask[$i] -eq $Close){$depth--;if($depth -eq 0){return $i}}
  }
  return -1
}
function Split-JavaList([string]$Text) {
  $mask=Mask-Java $Text;$paren=0;$brace=0;$angle=0;$square=0;$start=0;$result=[Collections.Generic.List[string]]::new()
  for($i=0;$i -lt $mask.Length;$i++) {
    switch($mask[$i]) {
      '(' {$paren++} ')' {$paren--} '{' {$brace++} '}' {$brace--}
      '<' {$angle++} '>' {$angle--} '[' {$square++} ']' {$square--}
      ',' {if($paren -eq 0 -and $brace -eq 0 -and $angle -eq 0 -and $square -eq 0){$result.Add($Text.Substring($start,$i-$start).Trim());$start=$i+1}}
    }
  }
  if($Text.Substring($start).Trim()){$result.Add($Text.Substring($start).Trim())}
  return $result.ToArray()
}
function Read-Annotation($Text,$Mask,[int]$At) {
  $name=[regex]::Match($Mask.Substring($At),'^@(?<name>[\w.$]+)')
  if(-not $name.Success){return $null}
  $end=$At+$name.Length
  while($end -lt $Mask.Length -and [char]::IsWhiteSpace($Mask[$end])){$end++}
  $args=''
  if($end -lt $Mask.Length -and $Mask[$end] -eq '(') {
    $close=Find-Close $Mask $end '(' ')'
    if($close -lt 0){return $null}
    $args=$Text.Substring($end+1,$close-$end-1);$end=$close+1
  }
  $values=@{}
  foreach($part in @(Split-JavaList $args)) {
    if($part -match '^\s*(\w+)\s*=([\s\S]*)$'){$values[$Matches[1]]=$Matches[2].Trim()}else{$values['value']=$part}
  }
  return @{name=($name.Groups['name'].Value -split '\.')[-1];values=$values;start=$At;end=$end}
}
function Read-Strings([string]$Value) {
  $value=$Value.Trim()
  if($value.StartsWith('{') -and $value.EndsWith('}')){$value=$value.Substring(1,$value.Length-2)}
  $items=@(Split-JavaList $value);$result=[Collections.Generic.List[string]]::new()
  foreach($item in $items) {
    if($item -notmatch '^"((?:\\.|[^"\\])*)"$'){return @{ok=$false;values=@()}}
    try{$result.Add([regex]::Unescape($Matches[1]))}catch{return @{ok=$false;values=@()}}
  }
  return @{ok=$true;values=@($result.ToArray())}
}
function Read-Paths($Annotation) {
  if(-not $Annotation){return @{ok=$true;values=@('')}}
  $values=$Annotation.values
  if($values.ContainsKey('path')){return Read-Strings $values.path}
  if($values.ContainsKey('value')){return Read-Strings $values.value}
  return @{ok=$true;values=@('')}
}
function Get-MemberStart($Mask,$Body,[int]$At) {
  $depth=1;$paren=0;$start=$Body+1
  for($i=$Body+1;$i -lt $At;$i++) {
    switch($Mask[$i]) {
      '(' {$paren++} ')' {$paren--} '{' {$depth++}
      '}' {$depth--;if($depth -eq 1 -and $paren -eq 0){$start=$i+1}}
      ';' {if($depth -eq 1 -and $paren -eq 0){$start=$i+1}}
    }
  }
  return $start
}
function Read-Parameters($Text) {
  $result=[Collections.Generic.List[object]]::new()
  foreach($part in @(Split-JavaList $Text)) {
    $mask=Mask-Java $part;$annotations=[Collections.Generic.List[object]]::new();$clean=$part
    foreach($m in [regex]::Matches($mask,'@[\w.$]+')) {
      $a=Read-Annotation $part $mask $m.Index
      if($a){$annotations.Add($a)}
    }
    foreach($a in ($annotations | Sort-Object start -Descending)){$clean=$clean.Remove($a.start,$a.end-$a.start)}
    $clean=$clean -replace '\bfinal\s+',''
    $match=[regex]::Match($clean.Trim(),'^(?<type>[\s\S]+?)\s+(?<name>\w+)$')
    if(-not $match.Success){$result.Add(@{location='unresolved';declaration=$part});continue}
    $name=$match.Groups['name'].Value;$location='unresolved';$wireName=$name;$required=$null
    foreach($a in $annotations) {
      $kind=@{PathVariable='path';RequestParam='query';RequestHeader='header';RequestBody='body';ModelAttribute='query-model';RequestPart='part'}[$a.name]
      if(-not $kind){continue};$location=$kind
      $required=if($a.values.ContainsKey('required')){$a.values.required -ne 'false'}else{$true}
      foreach($key in @('name','value')){if($a.values[$key]){$literal=Read-Strings $a.values[$key];if($literal.ok -and $literal.values.Count -eq 1){$wireName=$literal.values[0]}else{$location='unresolved'};break}}
      if($a.values.ContainsKey('defaultValue')){$required=$false}
    }
    $result.Add(@{name=$name;type=($match.Groups['type'].Value -replace '\s+',' ');location=$location;wireName=$wireName;required=$required})
  }
  return $result.ToArray()
}
try {
  $root=(Resolve-Path -LiteralPath $ProjectPath).Path
  $roots=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach($module in $ModulePath) {
    $path=[IO.Path]::GetFullPath((Join-Path $root $module))
    if($path -ne $root -and -not $path.StartsWith($root.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw '模块路径超出项目根'}
    if(-not (Test-Path -LiteralPath $path -PathType Container)){throw "模块目录不存在：$module"}
    $null=$roots.Add($path)
  }
  $files=@($roots | ForEach-Object {Get-ChildItem -LiteralPath $_ -Recurse -File -Filter '*.java'} |
    Where-Object {$_.FullName -notmatch '[\\/](target|build|\.git|node_modules)[\\/]|[\\/]src[\\/]test[\\/]'} | Sort-Object FullName -Unique)
  foreach($file in $files) {
    $relative=[IO.Path]::GetRelativePath($root,$file.FullName).Replace('\','/');$filesChecked.Add($relative)
    if($file.Attributes -band [IO.FileAttributes]::ReparsePoint){Add-Unresolved $relative 0 '跳过重解析点';continue}
    $text=[IO.File]::ReadAllText($file.FullName);$mask=Mask-Java $text
    $mappings=@([regex]::Matches($mask,'@(?:[\w$]+\.)*(?:RequestMapping|GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping)\b'))
    if(-not $mappings.Count){
      if($mask -match '@(?:RestController|Controller)\b'){Add-Unresolved $relative 0 '控制器未找到直接映射；需核对继承或自定义注解'}
      continue
    }
    $classes=@([regex]::Matches($mask,'\b(?<kind>class|interface|record)\s+(?<name>\w+)(?<tail>[^\{;]*)\{'))
    if($classes.Count -ne 1){Add-Unresolved $relative 0 '多个或无法识别的类型声明，需核对嵌套类及继承';continue}
    $class=$classes[0];$body=$class.Index+$class.Length-1;$classEnd=Find-Close $mask $body '{' '}'
    if($classEnd -lt 0){Add-Unresolved $relative 0 '无法定位类型结束';continue}
    $prefix=$mask.Substring(0,$class.Index)
    if($prefix -notmatch '@(?:[\w$]+\.)*(?:RestController|Controller)\b'){Add-Unresolved $relative 0 '映射类型不是直接标注的控制器，需核对实际注册'}
    if($class.Groups['kind'].Value -eq 'interface' -or $class.Groups['tail'].Value -match '\b(extends|implements)\b') {Add-Unresolved $relative 0 '存在接口或继承关系；只盘点当前文件直接声明，不证明继承契约完整'}
    $classMaps=@($mappings | Where-Object Index -lt $class.Index)
    if($classMaps.Count -gt 1){Add-Unresolved $relative 0 '类型有多个映射注解';continue}
    $base=if($classMaps.Count){Read-Annotation $text $mask $classMaps[0].Index}else{$null}
    $basePaths=Read-Paths $base
    if(-not $basePaths.ok){Add-Unresolved $relative 0 '类型路径使用常量、拼接或占位符，需人工解析';continue}
    if($base -and @($base.values.Keys | Where-Object {$_ -notin @('path','value')}).Count){Add-Unresolved $relative 0 '类型映射包含 method/headers/params/媒体约束，需与方法映射共同核对'}
    foreach($method in [regex]::Matches($mask.Substring($body+1,$classEnd-$body-1),'\bpublic\s+(?:[\w.$<>,?\[\]]+\s+)+(?<name>\w+)\s*\(')) {
      $at=$body+1+$method.Index;$start=Get-MemberStart $mask $body $at
      $annotations=$mask.Substring($start,$at-$start)
      if($annotations -match '@' -and $annotations -notmatch '@(?:[\w$]+\.)*(?:RequestMapping|GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping)\b'){
        Add-Unresolved $relative (1+[regex]::Matches($text.Substring(0,$at),"`n").Count) "公开方法 $($method.Groups['name'].Value) 只有其他注解，需核对组合映射或非接口用途"
      }
    }
    foreach($map in ($mappings | Where-Object {$_.Index -gt $body -and $_.Index -lt $classEnd})) {
      $line=1+([regex]::Matches($text.Substring(0,$map.Index),"`n")).Count
      $annotation=Read-Annotation $text $mask $map.Index
      if(-not $annotation){Add-Unresolved $relative $line '映射注解无法解析';continue}
      $cursor=$annotation.end
      while($cursor -lt $mask.Length) {
        while($cursor -lt $mask.Length -and [char]::IsWhiteSpace($mask[$cursor])){$cursor++}
        if($mask[$cursor] -ne '@'){break};$next=Read-Annotation $text $mask $cursor
        if(-not $next){break};$cursor=$next.end
      }
      $sig=[regex]::Match($mask.Substring($cursor),'^(?:(?:public|protected|private|static|final|abstract|default|synchronized)\s+)*(?<return>[\w.$<>,?\[\]\s]+?)\s+(?<name>[A-Za-z_$]\w*)\s*\(')
      if(-not $sig.Success){Add-Unresolved $relative $line '无法关联到直接方法声明';continue}
      $paramStart=$cursor+$sig.Length-1;$paramEnd=Find-Close $mask $paramStart '(' ')'
      if($paramEnd -lt 0){Add-Unresolved $relative $line '方法参数未闭合';continue}
      $paths=Read-Paths $annotation
      if(-not $paths.ok -or @($paths.values | Where-Object {$_ -match '\$\{|#\{'}).Count){Add-Unresolved $relative $line '方法路径不是可静态确定的字符串';continue}
      $methods=if($annotation.name -ne 'RequestMapping'){@($annotation.name.Replace('Mapping','').ToUpperInvariant())}else{@([regex]::Matches([string]$annotation.values.method,'RequestMethod\.(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|TRACE)') | ForEach-Object {$_.Groups[1].Value})}
      if(-not $methods.Count){$methods=@('ANY');Add-Unresolved $relative $line 'RequestMapping 未限定可静态识别的 HTTP 方法'}
      $memberStart=Get-MemberStart $mask $body $map.Index
      $platform=$null;$constraints=@{}
      foreach($aMatch in [regex]::Matches($mask.Substring($memberStart,$cursor-$memberStart),'@[\w.$]+')) {
        $a=Read-Annotation $text $mask ($memberStart+$aMatch.Index)
        if($a -and $a.name -eq 'PlatfomApi'){$platform=@{};foreach($key in @('code','version','name','requestPath')){$raw=$a.values[$key];$literal=if($raw){Read-Strings $raw}else{$null};$platform[$key]=if($literal -and $literal.ok -and $literal.values.Count -eq 1){$literal.values[0]}else{$null};$platform["${key}Expression"]=$raw}}
      }
      foreach($key in @('params','headers','consumes','produces')){if($annotation.values.ContainsKey($key)){$constraints[$key]=$annotation.values[$key];Add-Unresolved $relative $line "映射包含 $key 约束，需核对与相同方法路径的关系"}}
      $parameters=@(Read-Parameters ($text.Substring($paramStart+1,$paramEnd-$paramStart-1)))
      if(@($parameters | Where-Object location -eq 'unresolved').Count){Add-Unresolved $relative $line '存在未明确参数绑定位置，需核对 DTO、隐式参数或框架解析器'}
      foreach($basePath in $basePaths.values){foreach($methodPath in $paths.values){foreach($method in $methods){
        $path='/'+(($basePath.Trim('/')+'/'+$methodPath.Trim('/')).Trim('/'))
        if($path -match '\$\{|#\{'){Add-Unresolved $relative $line '类型路径含动态占位符';continue}
        $routes.Add(@{controller=$class.Groups['name'].Value;handler=$sig.Groups['name'].Value;method=$method;path=$path;returnType=($sig.Groups['return'].Value.Trim() -replace '\s+',' ');parameters=$parameters;platformApi=$platform;constraints=$constraints;source=$relative;line=$line})
      }}}
    }
  }
  if(-not $filesChecked.Count){Add-Unresolved '' 0 '指定范围没有 Java 源码'}
  if(-not $routes.Count){Add-Unresolved '' 0 '未盘点到静态 HTTP 映射，不能推断模块无接口'}
  $result=[ordered]@{schemaVersion=1;status=$(if($unresolved.Count){'partial'}else{'complete'});project=$root;modules=$ModulePath;exclusions=@('target','build','.git','node_modules','src/test');files=@($filesChecked.ToArray());routes=@($routes.ToArray());unresolved=@($unresolved.ToArray());limitations=@('仅解析 Java 文件直接声明的 Spring MVC 常用映射；不解析继承、自定义组合注解、运行时网关改写或 DTO 内部字段。')}
  $exit=if($unresolved.Count){2}else{0}
} catch {
  $result=@{schemaVersion=1;status='failed';routes=@($routes.ToArray());unresolved=@(@{reason=$_.Exception.Message});limitations=@('盘点失败，不证明范围完整。')};$exit=1
}
$serialized=$result | ConvertTo-Json -Depth 14
if($OutputPath){[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath),$serialized,[Text.UTF8Encoding]::new($false))}
if($Json){$serialized}else{Write-Output "接口盘点：$($result.status)，接口=$(@($result.routes).Count)，未解析=$(@($result.unresolved).Count)"}
exit $exit
