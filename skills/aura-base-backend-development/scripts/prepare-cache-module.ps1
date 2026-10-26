#requires -Version 7.0
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ProjectPath,
 [string]$ModulePath='.',
 [Parameter(Mandatory)][string]$PackageName,
 [Parameter(Mandatory)][string]$CacheClass,
 [Parameter(Mandatory)][string]$CacheJson,
 [ValidateSet('Plan','Apply')][string]$Mode='Plan'
)
$ErrorActionPreference='Stop';$root=[IO.Path]::GetFullPath($ProjectPath)
if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'ProjectPath 必须是已有目录'}
if($PackageName-cnotmatch'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$'){throw 'PackageName 非法'}
if($CacheClass-cnotmatch'^[A-Z][A-Za-z0-9]*$'){throw 'CacheClass 非法'}
$items=@((Get-Content -LiteralPath $CacheJson -Raw -Encoding UTF8)|ConvertFrom-Json);if(!$items.Count){throw '缓存契约不能为空'}
$names=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase);$lines=@();$docs=@()
foreach($item in $items){
 if($item.PSObject.Properties.Name -cnotcontains 'enabled' -or $item.enabled -isnot [bool]){throw "enabled 必须明确为布尔值：$($item.name)"};if(-not $item.enabled){throw "缓存未通过收益准入：$($item.name)"}
 if($item.category -cnotin @('query','projection','state','auth','temporary','coordination')){throw "缓存 category 非法：$($item.name)"}
 if($item.category -eq 'query' -and ($item.PSObject.Properties.Name -cnotcontains 'queryName' -or [string]::IsNullOrWhiteSpace([string]$item.queryName))){throw "query 缓存必须声明 queryName：$($item.name)"}
 if($item.category -eq 'query' -and ($item.PSObject.Properties.Name -cnotcontains 'scopeFields' -or $item.scopeFields -isnot [array] -or !$item.scopeFields.Count)){throw "query 缓存必须声明 scopeFields：$($item.name)"}
 if($item.name-isnot[string]-or$item.name-cnotmatch'^[A-Z][A-Z0-9_]*$'){throw "缓存名称非法：$($item.name)"};if(!$names.Add($item.name)){throw "缓存名称重复：$($item.name)"}
 if($item.keyPrefix-isnot[string]-or$item.keyPrefix.Trim().Length-lt 3-or$item.keyPrefix-notmatch':$'){throw "keyPrefix 必须是稳定前缀并以冒号结束：$($item.name)"}
 if($item.ttlSeconds -as [int] -le 0 -or [string]$item.ttlSeconds -notmatch '^[0-9]+$'){throw "ttlSeconds 必须是正整数：$($item.name)"}
 foreach($required in @('scope','source','sourceCost','benefit','measure','staleness','refreshMode','onMiss','onFailure','invalidation')){if($item.PSObject.Properties.Name-cnotcontains$required-or[string]::IsNullOrWhiteSpace([string]$item.$required)){throw "缓存契约缺少 $required：$($item.name)"}}
 if($item.refreshMode -cnotin @('on-demand','event','scheduled','hybrid')){throw "refreshMode 非法：$($item.name)"}
 $safePrefix=$item.keyPrefix.Replace('"','\"');$lines+="    public static final String $($item.name) = `"$safePrefix`";";$lines+="    public static final long $($item.name)_TTL_SECONDS = $($item.ttlSeconds)L;";$docs+="    // category=$($item.category); scope=$($item.scope); source=$($item.source); cost=$($item.sourceCost); benefit=$($item.benefit); measure=$($item.measure); stale=$($item.staleness); refresh=$($item.refreshMode); miss=$($item.onMiss); failure=$($item.onFailure); invalidation=$($item.invalidation)"
}
$rel="src/main/java/$($PackageName.Replace('.','/'))/cache/$CacheClass.java";$target=[IO.Path]::GetFullPath((Join-Path (Join-Path $root $ModulePath) $rel));$pre=$root.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar;if(-not$target.StartsWith($pre,[StringComparison]::OrdinalIgnoreCase)){throw '输出路径超出项目根目录'}
$body="package $PackageName.cache;`n`n/** Generated cache contract constants. Business read-through and invalidation remain manual. */`npublic final class $CacheClass {`n    private $CacheClass() {}`n`n$($docs -join "`n")`n$($lines -join "`n")`n}`n";$existing=@();$planned=@();$conflict=@();$relative=[IO.Path]::GetRelativePath($root,$target).Replace('\','/')
if(Test-Path -LiteralPath $target){$existing+=$relative;if([IO.File]::ReadAllText($target)-cne$body){$conflict+=$relative}}else{$planned+=[pscustomobject]@{path=$relative;action='create'}}
$status=if($conflict.Count){'blocked'}elseif(!$planned.Count){'unchanged'}elseif($Mode-eq'Apply'){'applied'}else{'ready'}
if($Mode-eq'Apply'-and !$conflict.Count-and$planned.Count){New-Item -ItemType Directory -Path([IO.Path]::GetDirectoryName($target))-Force|Out-Null;[IO.File]::WriteAllText($target,$body,[Text.UTF8Encoding]::new($false))}
[ordered]@{schemaVersion=1;status=$status;mode=$Mode;projectRoot=$root;modulePath=$ModulePath;cacheClass=$CacheClass;contractCount=$items.Count;filesToCreate=@($planned);existingFiles=@($existing);conflictingFiles=@($conflict);limitations=@('只生成缓存契约常量；不实现读取、回源、写入、失效或事务时序。')}|ConvertTo-Json -Depth 8
if($conflict.Count){exit 2}
