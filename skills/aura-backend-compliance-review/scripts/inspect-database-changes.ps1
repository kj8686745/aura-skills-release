#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$ProjectPath,
  [Parameter(Mandatory)][string[]]$FilePath,
  [ValidateSet('Unknown','MySQL','PostgreSQL')][string]$Dialect='Unknown',
  [string]$OutputPath,
  [switch]$Json
)
$ErrorActionPreference='Stop'
$utf8=[Text.UTF8Encoding]::new($false)
$findings=[Collections.Generic.List[object]]::new()
$unresolved=[Collections.Generic.List[object]]::new()
$scanned=[Collections.Generic.List[object]]::new()

function In-Project([string]$Root,[string]$Relative){
  if([IO.Path]::IsPathRooted($Relative)){throw 'FilePath 必须使用项目相对路径'}
  $full=[IO.Path]::GetFullPath((Join-Path $Root $Relative))
  if(-not $full.StartsWith($Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw '路径超出项目范围'}
  $cursor=$full
  while($cursor.Length -gt $Root.Length){
    if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw '不读取重解析点目标'}
    $cursor=[IO.Path]::GetDirectoryName($cursor)
  }
  $full
}

# 保留换行的词法掩码：注释不参与扫描，字符串不参与关键字判断。
# comments 仍保留字符串，供 MyBatis ${} 字符串替换线索使用。
function Sql-Masks([string]$Text){
  $comments=$Text.ToCharArray();$code=$Text.ToCharArray();$i=0
  while($i -lt $Text.Length){
    $start=$i;$end=$i;$kind=''
    if($i+1 -lt $Text.Length -and $Text.Substring($i,2) -eq '--' -and ($Dialect -ne 'MySQL' -or $i+2 -ge $Text.Length -or [char]::IsWhiteSpace($Text[$i+2]) -or [char]::IsControl($Text[$i+2]))){
      $end=$Text.IndexOf("`n",$i);if($end -lt 0){$end=$Text.Length};$kind='comment'
    }elseif($Text[$i] -eq '#' -and $Dialect -eq 'MySQL' -and ($i+1 -ge $Text.Length -or $Text[$i+1] -ne '{')){
      $end=$Text.IndexOf("`n",$i);if($end -lt 0){$end=$Text.Length};$kind='comment'
    }elseif($i+1 -lt $Text.Length -and $Text.Substring($i,2) -eq '/*'){
      $end=$i+2;$depth=1
      while($end -lt $Text.Length -and $depth -gt 0){
        if($end+1 -lt $Text.Length -and $Text.Substring($end,2) -eq '/*'){$depth++;$end+=2}
        elseif($end+1 -lt $Text.Length -and $Text.Substring($end,2) -eq '*/'){$depth--;$end+=2}
        else{$end++}
      };$kind='comment'
    }elseif($Text[$i] -eq [char]39 -or $Text[$i] -eq [char]34 -or $Text[$i] -eq [char]96){
      $quote=$Text[$i];$end=$i+1
      $escapeString=$Dialect -eq 'MySQL' -or ($Dialect -eq 'PostgreSQL' -and $quote -eq [char]39 -and $i -gt 0 -and $Text[$i-1] -in @('e','E') -and ($i -lt 2 -or $Text[$i-2] -notmatch '[A-Za-z0-9_$]'))
      while($end -lt $Text.Length){
        if($Text[$end] -eq $quote){if($end+1 -lt $Text.Length -and $Text[$end+1] -eq $quote){$end+=2;continue};$end++;break}
        if($Text[$end] -eq [char]92 -and $escapeString){$end+=2}else{$end++}
      };$end=[Math]::Min($end,$Text.Length);$kind='literal'
    }elseif($Text[$i] -eq '$' -and $Dialect -eq 'PostgreSQL'){
      $tag=[regex]::Match($Text.Substring($i),'^\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$')
      if($tag.Success){$closing=$Text.IndexOf($tag.Value,$i+$tag.Length,[StringComparison]::Ordinal);$end=if($closing -lt 0){$Text.Length}else{$closing+$tag.Length};$kind='literal'}
    }
    if($kind){
      for($j=$start;$j -lt $end;$j++){if($Text[$j] -notin @([char]10,[char]13)){$code[$j]=' ';if($kind -eq 'comment'){$comments[$j]=' '}}}
      $i=$end
    }else{$i++}
  }
  @{comments=(-join $comments);code=(-join $code)}
}
function Candidate($Path,$Line,$Id,$Code,$Message){
  $findings.Add([ordered]@{path=$Path;line=$Line;ruleId=$Id;code=$Code;status='candidate';message=$Message})
}
function Inspect-Sql([string]$Text,[string]$Path,[int]$Line,[bool]$Mapper,[bool]$Dynamic){
  $mask=Sql-Masks $Text;$code=$mask.code
  if($Dialect -eq 'MySQL' -and $Text -match '/\*!'){$unresolved.Add(@{path=$Path;line=$Line;reason='MySQL版本条件执行注释需按服务器版本核对，不当作普通注释证明无风险'})}
  if($Mapper -and $mask.comments -match '\$\{[^}]+\}'){
    Candidate $Path $Line 'AURA-BASE-DATA-016' 'text-substitution' '存在 MyBatis 字符串替换；核对后端白名单，不自动认定输入可控或违规'
  }
  if($code -match '(?is)\bSELECT\s+(?:DISTINCT\s+)?(?:[A-Za-z_]\w*\.)?\*'){
    Candidate $Path $Line 'AURA-BASE-DATA-002' 'select-star' '返回全列；核对查询模型、字段边界和真实用途，COUNT(*)不属于此命中'
  }
  if($code -match '(?i)\bLIMIT\b|\bFETCH\s+(?:FIRST|NEXT)\b'){
    if($code -notmatch '(?i)\bORDER\s+BY\b'){Candidate $Path $Line 'AURA-BASE-DATA-003' 'pagination-order' '分页片段未见排序；核对完整SQL、稳定唯一排序与插件行为'}
    if($code -match '(?i)\bJOIN\b'){Candidate $Path $Line 'AURA-BASE-DATA-003' 'join-pagination' '关联与分页同时出现；核对主记录/明细分页单位、count和去重语义'}
  }
  if($code -match '(?i)^\s*(?:UPDATE\b|DELETE\s+FROM\b)' -and $code -notmatch '(?i)\bWHERE\b' -and -not $Dynamic){
    Candidate $Path $Line 'AURA-BASE-DATA-016' 'unbounded-write' '写语句未见WHERE；核对批次、可信数据范围和执行规模'
  }
  if($code -match '(?is)\bDROP\s+(?:TABLE|COLUMN|SCHEMA|DATABASE)\b|\bTRUNCATE\b|\bALTER\s+TABLE\b.*\b(?:DROP|RENAME|MODIFY|TYPE)\b'){
    Candidate $Path $Line 'AURA-BASE-DATA-014' 'destructive-ddl' '删除、重命名或类型变更线索；核对消费者并存、锁/重写、数据校验和恢复路径'
  }
  if($code -match '(?is)\bALTER\s+TABLE\b.*\b(?:NOT\s+NULL|UNIQUE)\b|\bCREATE\s+UNIQUE\s+INDEX\b'){
    Candidate $Path $Line 'AURA-BASE-DATA-015' 'constraint-change' '约束收紧线索；核对空值、重复数据、并存写入和方言支持'
  }
  if($code -match '(?is)\bEXPLAIN\b.*\bANALYZE\b'){
    Candidate $Path $Line 'AURA-BASE-DATA-016' 'explain-executes' 'EXPLAIN ANALYZE会执行目标语句；核对环境、授权和副作用'
  }
  if($code -match '(?i)^\s*(?:DO\b|CREATE\s+(?:OR\s+REPLACE\s+)?(?:FUNCTION|PROCEDURE)\b)'){
    $unresolved.Add(@{path=$Path;line=$Line;reason='过程体不作SQL语义解析，需按方言人工核对'})
  }
}

try{
  $root=(Resolve-Path -LiteralPath $ProjectPath).Path.TrimEnd([char[]]'\/')
  if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'ProjectPath 必须是目录'}
  $paths=@($FilePath|ForEach-Object {In-Project $root $_}|Sort-Object -Unique)
  if(-not $paths.Count){throw '必须指定当前变更文件'}
  foreach($p in $paths){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw '指定文件不存在'}}
  $outputFull=$null
  if($OutputPath){$outRelative=if([IO.Path]::IsPathRooted($OutputPath)){[IO.Path]::GetRelativePath($root,$OutputPath)}else{$OutputPath};$outputFull=In-Project $root $outRelative;if($outputFull -in $paths -or [IO.Path]::GetExtension($outputFull) -ne '.json'){throw '输出必须是不同于输入的项目内JSON文件'}}
  foreach($p in $paths){
    $rel=[IO.Path]::GetRelativePath($root,$p).Replace('\','/');$text=[IO.File]::ReadAllText($p);$ext=[IO.Path]::GetExtension($p).ToLowerInvariant()
    $scanned.Add(@{path=$rel;sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($p))).ToLowerInvariant()})
    if($ext -eq '.sql'){
      $mask=Sql-Masks $text
      foreach($m in [regex]::Matches($mask.code,'[^;]+(?:;|$)')){
        if([string]::IsNullOrWhiteSpace($m.Value)){continue}
        $line=1+([regex]::Matches($text.Substring(0,$m.Index),"`n")).Count
        Inspect-Sql ($text.Substring($m.Index,$m.Length)) $rel $line $false $false
      }
    }elseif($ext -eq '.xml'){
      $settings=[Xml.XmlReaderSettings]::new();$settings.DtdProcessing=[Xml.DtdProcessing]::Ignore;$settings.XmlResolver=$null
      $reader=[Xml.XmlReader]::Create($p,$settings)
      try{$doc=[Xml.Linq.XDocument]::Load($reader,[Xml.Linq.LoadOptions]::SetLineInfo)}finally{$reader.Dispose()}
      if($doc.Root.Name.LocalName -ne 'mapper'){$unresolved.Add(@{path=$rel;reason='不是MyBatis mapper XML，未执行SQL候选检查'});continue}
      foreach($node in $doc.Root.Elements()|Where-Object {$_.Name.LocalName -in @('select','insert','update','delete','sql')}){
        $dynamic=@($node.Descendants()|Where-Object {$_.Name.LocalName -in @('include','if','choose','where','trim','foreach')}).Count -gt 0
        $line=([Xml.IXmlLineInfo]$node).LineNumber
        if($dynamic){$unresolved.Add(@{path=$rel;line=$line;reason='动态SQL/片段需核对展开结果、空集合和所有分支；不推断最终WHERE或租户条件'})}
        Inspect-Sql $node.Value $rel $line $true $dynamic
      }
    }else{$unresolved.Add(@{path=$rel;reason='仅支持SQL与MyBatis XML；Java注解SQL、查询构造器和其他迁移格式需人工核对'})}
  }
  $result=[ordered]@{schemaVersion=1;status=if($findings.Count -or $unresolved.Count){'review_required'}else{'no_deterministic_findings'};dialect=$Dialect;summary=@{files=$scanned.Count;candidates=$findings.Count;unresolved=$unresolved.Count};files=@($scanned.ToArray());findings=@($findings.ToArray());unresolved=@($unresolved.ToArray());limitations=@('只处理显式文件；不连接数据库、不执行SQL、不获取SDK或邻仓库。','候选不等于规范偏差；不判断索引最优、租户生效、实际分页、DDL锁范围和迁移可恢复性。','XML行号指SQL节点起始行；不展开include或动态分支，不构成完整SQL解析器；未命中不证明合规。')}
  if($outputFull){$null=[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputFull));[IO.File]::WriteAllText($outputFull,($result|ConvertTo-Json -Depth 8),$utf8)}
  if($Json -or -not $OutputPath){$result|ConvertTo-Json -Depth 8}else{"数据库变更候选：$($result.status)，文件=$($scanned.Count)，候选=$($findings.Count)，未解析=$($unresolved.Count)"}
  if($findings.Count -or $unresolved.Count){exit 2};exit 0
}catch{
  [ordered]@{schemaVersion=1;status='failed';errorType=$_.Exception.GetType().Name;message='输入、路径或文件解析失败；不输出文件正文及解析异常原文'}|ConvertTo-Json
  exit 1
}
