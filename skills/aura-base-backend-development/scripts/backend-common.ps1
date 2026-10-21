# Shared implementation for the two scoped backend tools; no external modules.
function Get-BackendScope([string]$ProjectPath,[string[]]$ModulePath) {
  $root=(Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path
  if(-not (Test-Path -LiteralPath $root -PathType Container)){throw '项目根必须是目录'}
  if(-not $ModulePath.Count){throw '至少指定一个模块范围'}
  $files=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $skipped=[Collections.Generic.List[string]]::new()
  $prefix=$root.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
  foreach($module in $ModulePath){
    if([string]::IsNullOrWhiteSpace($module) -or [IO.Path]::IsPathRooted($module)){throw '模块必须是非空项目相对目录'}
    $target=[IO.Path]::GetFullPath((Join-Path $root $module))
    if($target -ne $root -and -not $target.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw '模块超出项目根'}
    if(-not (Test-Path -LiteralPath $target -PathType Container)){throw "模块目录不存在：$module"}
    $cursor=$target
    while($cursor -and $cursor.Length -ge $root.Length){
      if((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw '模块包含重解析点，不沿链接读取'}
      $cursor=[IO.Path]::GetDirectoryName($cursor)
    }
    $pending=[Collections.Generic.Stack[string]]::new();$pending.Push($target)
    while($pending.Count){
      $dir=$pending.Pop()
      foreach($item in Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop){
        if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){$skipped.Add([IO.Path]::GetRelativePath($root,$item.FullName));continue}
        $relative=[IO.Path]::GetRelativePath($root,$item.FullName).Replace('\','/')
        if($item.PSIsContainer){
          if($item.Name -in @('.git','target','build','node_modules','.idea','.gradle','out')){continue}
          $pending.Push($item.FullName)
        }else{$null=$files.Add($item.FullName)}
      }
    }
  }
  return @{root=$root;files=@($files | Sort-Object);skipped=@($skipped.ToArray());modules=$ModulePath}
}
function Get-BackendMask([string]$Text) {
  $chars=$Text.ToCharArray()
  foreach($m in [regex]::Matches($Text,'(?s)/\*.*?\*/|//[^\r\n]*|""".*?"""|"(?:\\.|[^"\\])*"|''(?:\\.|[^''\\])*''')){
    for($i=$m.Index;$i -lt $m.Index+$m.Length;$i++){if($chars[$i] -notin @("`r","`n")){$chars[$i]=' '}}
  }
  return -join $chars
}
function Get-BackendLine([string]$Text,[int]$Index){return 1+[regex]::Matches($Text.Substring(0,$Index),"`n").Count}
function Invoke-BackendApiInventory($Scope) {
  if($Scope.skipped.Count){return @{status='partial';routes=@();unresolved=@(@{reason='范围含重解析点，未执行递归接口盘点；请指定不含链接的源码目录'})}}
  $engine=(Get-Process -Id $PID).Path
  $start=[Diagnostics.ProcessStartInfo]::new($engine)
  $start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
  # Encode shell literals so spaces and apostrophes in project paths remain data.
  $quote={param($value) "'"+([string]$value).Replace("'","''")+"'"}
  $moduleArgs=($Scope.modules | ForEach-Object {& $quote $_}) -join ','
  $command='& '+(& $quote (Join-Path $PSScriptRoot 'inventory-api-contracts.ps1'))+' -ProjectPath '+(& $quote $Scope.root)+' -ModulePath @('+ $moduleArgs +') -Json; exit $LASTEXITCODE'
  foreach($arg in @('-NoProfile','-EncodedCommand',[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command)))){$start.ArgumentList.Add($arg)}
  $proc=[Diagnostics.Process]::Start($start)
  $stdout=$proc.StandardOutput.ReadToEndAsync();$stderr=$proc.StandardError.ReadToEndAsync();$proc.WaitForExit()
  $body=$stdout.GetAwaiter().GetResult();$errorText=$stderr.GetAwaiter().GetResult();$code=$proc.ExitCode;$proc.Dispose()
  if($code -notin @(0,2)){throw "接口盘点失败：$errorText $body"}
  return ($body | ConvertFrom-Json -AsHashtable)
}
function Write-BackendResult($Result,[string]$OutputPath,[bool]$Json,[string]$Summary){
  $serialized=$Result | ConvertTo-Json -Depth 22
  if($OutputPath){[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath),$serialized,[Text.UTF8Encoding]::new($false))}
  if($Json){$serialized}else{$Summary}
}
