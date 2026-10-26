#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$ProjectPath,
  [Parameter(Mandatory)][string]$PlanPath,
  [string]$OutputPath,
  [switch]$Apply,
  [switch]$Json
)

$ErrorActionPreference='Stop'
$utf8=[Text.UTF8Encoding]::new($false)
function Resolve-Project([string]$Path){
  $resolved=(Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
  if(-not(Test-Path -LiteralPath $resolved -PathType Container)){throw 'ProjectPath 必须是目录'}
  return $resolved.TrimEnd([char[]]'\/')
}
function Resolve-InProject([string]$Root,[string]$Relative){
  if([IO.Path]::IsPathRooted($Relative)){throw '注释计划路径必须是项目相对路径'}
  $target=[IO.Path]::GetFullPath((Join-Path $Root $Relative))
  $prefix=$Root+[IO.Path]::DirectorySeparatorChar
  if(-not $target.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw '注释计划路径超出项目根目录'}
  $cursor=$target
  while($cursor.Length -gt $Root.Length){
    if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw '目标路径包含重解析点'}
    $cursor=[IO.Path]::GetDirectoryName($cursor)
  }
  return $target
}
function Write-Result($Result,[string]$Path){
  if($Path){
    $parent=[IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Path))
    if(-not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force | Out-Null}
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($Path),($Result|ConvertTo-Json -Depth 10),$utf8)
  }
  if($Json){$Result|ConvertTo-Json -Depth 10}else{"注释计划：$($Result.status)，应用=$($Result.applied)，跳过=$($Result.skipped)，错误=$($Result.errors)"}
}
try{
  $root=Resolve-Project $ProjectPath
  $planFull=(Resolve-Path -LiteralPath $PlanPath -ErrorAction Stop).Path
  $plan=Get-Content -LiteralPath $planFull -Raw -Encoding UTF8 | ConvertFrom-Json
  $items=@($plan.items)
  if(-not $items.Count){throw '注释计划缺少 items'}
  if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([IO.Path]::GetDirectoryName($planFull)) '注释增强结果.json'}
  $OutputPath=Resolve-InProject $root ([IO.Path]::GetRelativePath($root,[IO.Path]::GetFullPath($OutputPath)))
  if($OutputPath -eq $planFull -or [IO.Path]::GetExtension($OutputPath) -ne '.json'){throw '输出必须为不同于计划的项目内 JSON 文件'}
  $results=[Collections.Generic.List[object]]::new();$applied=0;$skipped=0;$errors=0
  foreach($item in $items){
    try{
      $relative=[string]$item.path;$anchor=[string]$item.anchor;$comment=[string]$item.comment
      if([string]::IsNullOrWhiteSpace($relative)-or [string]::IsNullOrWhiteSpace($anchor)-or [string]::IsNullOrWhiteSpace($comment)){throw 'path、anchor、comment 均不能为空'}
      $file=Resolve-InProject $root $relative
      if([IO.Path]::GetExtension($file) -ne '.java'){throw '仅支持 Java 源文件'}
      if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw '目标源文件不存在'}
      $comment=$comment.Replace("`r`n","`n")
      $isBlock=$comment -match '\A\s*/\*\*(?:(?!\*/)[\s\S])*\*/\s*\z'
      $isLine=@($comment -split "`n" | Where-Object {$_ -notmatch '^\s*//[^\r\n]*$'}).Count -eq 0
      if(-not $isBlock -and -not $isLine){throw 'comment 必须只包含单段 JavaDoc 或连续行注释'}
      if($comment -match '\\u+[0-9a-fA-F]{4}'){throw '注释中不接受 Java Unicode 转义'}
      $text=[IO.File]::ReadAllText($file)
      $hits=[regex]::Matches($text,[regex]::Escape($anchor)).Count
      if($hits -ne 1){throw "anchor 命中次数为 $hits，要求恰好 1 次"}
      $index=$text.IndexOf($anchor,[StringComparison]::Ordinal);$before=$text.Substring(0,$index)
      if($index -gt 0 -and $text[$index-1] -ne "`n"){throw 'anchor 必须从完整源代码行开始'}
      $existingPrefix=$before
      if($isBlock){$existingPrefix=[regex]::Replace($before,'(?m)(?:^[ \t]*@[^\r\n]+\r?\n)+[ \t]*\z','')}
      if($existingPrefix -match '(?s)/\*\*(?:(?!\*/)[\s\S])*\*/\s*\z|//[^\r\n]*\s*\z'){
        $results.Add([ordered]@{path=$relative;status='skipped';reason='anchor 前已有注释；不覆盖原注释'});$skipped++;continue
      }
      if($isBlock -and $before -match '(?m)^\s*@[^\r\n]+\r?\n\s*\z'){throw 'JavaDoc 的 anchor 必须包含首个注解，不能插在注解和方法之间'}
      $newline=if($text.Contains("`r`n")){"`r`n"}else{"`n"};$insert=$comment.TrimEnd("`r","`n").Replace("`n",$newline)+$newline
      if($Apply){$updated=$text.Substring(0,$index)+$insert+$text.Substring($index);[IO.File]::WriteAllText($file,$updated,$utf8);$status='applied';$applied++}else{$status='planned'}
      $results.Add([ordered]@{path=$relative;status=$status;anchor=$anchor})
    }catch{$results.Add([ordered]@{path=[string]$item.path;status='error';reason=$_.Exception.Message});$errors++}
  }
  $result=[ordered]@{schemaVersion=1;status=$(if($errors){'failed'}elseif($Apply){'applied'}else{'planned'});apply=$Apply.IsPresent;projectRoot=$root;planPath=$planFull;applied=$applied;skipped=$skipped;errors=$errors;items=@($results.ToArray());limitations=@('只按计划中的精确 anchor 写入注释；不自动重写已有注释。','注释内容必须由 Agent 基于实际代码和任务语义生成；脚本只负责安全写回和结果记录。')}
  Write-Result $result $OutputPath
  if($errors){exit 1}
  exit 0
}catch{$result=[ordered]@{schemaVersion=1;status='failed';errorType=$_.Exception.GetType().Name;message=$_.Exception.Message};Write-Result $result $OutputPath;exit 1}
