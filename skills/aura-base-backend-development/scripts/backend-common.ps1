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
    if(Test-Path -LiteralPath $target -PathType Leaf){throw "ModulePath 只接收目录，不接收文件：$module；请指定该文件所属的项目相对目录，再筛选文件结果"}
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
function Invoke-BackendApiInventory($Scope,[ValidateSet('Auto','Required')][string]$ApiMode='Auto') {
  if($Scope.skipped.Count){return @{status='partial';routes=@();unresolved=@(@{reason='范围含重解析点，未执行递归接口盘点；请指定不含链接的源码目录'})}}
  if($ApiMode -eq 'Auto'){
    $httpHint=$false
    foreach($file in $Scope.files){
      $rel=[IO.Path]::GetRelativePath($Scope.root,$file).Replace('\','/')
      if($rel -notlike '*.java' -or $rel -match '(^|/)src/test/'){continue}
      $mask=Get-BackendMask ([IO.File]::ReadAllText($file))
      if($mask -match '@[\w.]*?(?:Controller|Mapping|Get|Post|Put|Delete|Patch|Http|Api)\b|\b(?:RouterFunction|RouterFunctions|RequestMapping|GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)\b'){$httpHint=$true;break}
    }
    if(-not $httpHint){return @{status='not-triggered';routes=@();unresolved=@();limitations=@('当前范围未识别到 HTTP 入口线索，未运行接口盘点；不证明没有动态、继承或自定义入口。任务涉及 HTTP 时显式使用 -ApiMode Required。')}}
  }
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
function Get-BackendReviewFocus($Scope){
  $patterns=[ordered]@{
    '共享资源'='\b(?:ConcurrentHashMap|HashMap|ExecutorService|Executors|ThreadPoolExecutor|Atomic\w*|Lock)\b|@PreDestroy\b|\bsynchronized\b'
    '外部调用'='\b\w*(?:Client|Adapter|ToolProvider|Sdk|SDK)\b|@FeignClient\b'
    '异常与失败'='\b(?:catch|throw|onErrorComplete|onErrorResume)\b'
    'HTTP契约'='@[\w.]*(?:Controller|Mapping)\b|\bRouterFunction\b'
  }
  $paths=@{};foreach($key in @('依赖与构建')+@($patterns.Keys)){$paths[$key]=[Collections.Generic.List[string]]::new()}
  foreach($file in $Scope.files){
    $rel=[IO.Path]::GetRelativePath($Scope.root,$file).Replace('\','/')
    if([IO.Path]::GetFileName($file) -in @('pom.xml','build.gradle','build.gradle.kts')){$paths['依赖与构建'].Add($rel)}
    if($rel -notlike '*.java' -or $rel -match '(^|/)src/test/'){continue}
    $mask=Get-BackendMask ([IO.File]::ReadAllText($file))
    foreach($key in $patterns.Keys){if($mask -match $patterns[$key]){$paths[$key].Add($rel)}}
  }
  foreach($key in @('依赖与构建')+@($patterns.Keys)){
    if($paths[$key].Count){@{route=$key;pathCount=$paths[$key].Count;samplePaths=@($paths[$key] | Select-Object -First 3);status='hint-only';review='与本次实际差异相交后，从任务路由读取命中正文和正反例；路径或符号不代表规则适用、已读或通过。'}}
  }
}
function Write-BackendResult($Result,[string]$OutputPath,[bool]$Json,[string]$Summary){
  $serialized=$Result | ConvertTo-Json -Depth 22
  if($OutputPath){[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath),$serialized,[Text.UTF8Encoding]::new($false))}
  if($Json){$serialized}else{$Summary}
}
