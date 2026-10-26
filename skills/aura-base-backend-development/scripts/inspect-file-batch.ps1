#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectPath,
    [Parameter(Mandatory)][string[]]$FilePath,
    [string]$OutputPath,
    [ValidateRange(1024,16777216)][int]$MaxSourceBytes = 2097152,
    [switch]$Json
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'backend-common.ps1')
$files=[Collections.Generic.List[object]]::new()
$signals=[Collections.Generic.List[object]]::new()
$candidates=[Collections.Generic.List[object]]::new()
$unknown=[Collections.Generic.List[object]]::new()
$writeTarget=$null
try {
    $root=(Resolve-Path -LiteralPath $ProjectPath).Path
    if(-not (Test-Path -LiteralPath $root -PathType Container)){throw '项目根必须为目录'}
    $prefix=$root.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    function Resolve-ScopedPath([string]$Relative) {
        if([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative)){throw '仅接受非空项目相对路径'}
        $full=[IO.Path]::GetFullPath((Join-Path $root $Relative))
        if(-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw '路径超出项目'}
        $cursor=$full
        while($cursor -and $cursor.Length -ge $root.Length){
            if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw '不沿重解析点读写'}
            $cursor=[IO.Path]::GetDirectoryName($cursor)
        }
        return $full
    }
    $selected=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    if(-not $FilePath.Count){throw '至少显式指定一个Java文件'}
    foreach($relative in $FilePath){
        $full=Resolve-ScopedPath $relative
        $rel=[IO.Path]::GetRelativePath($root,$full).Replace('\','/')
        if($rel -match '(^|/)(?:\.git|target|build|node_modules|\.gradle)(/|$)' -or [IO.Path]::GetExtension($full) -ne '.java'){throw '只检查指定业务Java文件，不检查构建目录或依赖'}
        if(-not (Test-Path -LiteralPath $full -PathType Leaf)){throw '指定源码不存在或不是文件'}
        $null=$selected.Add($full)
    }
    if($OutputPath){
        $writeTarget=Resolve-ScopedPath $OutputPath
        if([IO.Path]::GetExtension($writeTarget) -ne '.json' -or $selected.Contains($writeTarget)){throw '输出须为项目内独立JSON文件'}
    }
    foreach($full in ($selected | Sort-Object)){
        $rel=[IO.Path]::GetRelativePath($root,$full).Replace('\','/')
        $info=Get-Item -LiteralPath $full
        if($info.Length -gt $MaxSourceBytes){$unknown.Add(@{path=$rel;reason='超过单源码读取上限，未读取'});continue}
        $text=[IO.File]::ReadAllText($full)
        $mask=Get-BackendMask $text
        $files.Add(@{path=$rel;sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($full))).ToLowerInvariant()})
        foreach($m in [regex]::Matches($mask,'\b(?:FileTemplate|RemoteFileService|MultipartFile|StreamingResponseBody|ByteArrayMultipartFile)\b|@(?:[\w.]+\.)?(?:RequestExcel|ResponseExcel)\b')){
            $signals.Add(@{path=$rel;line=(Get-BackendLine $text $m.Index);kind=$m.Value.TrimStart('@');status='signal-only'})
        }
        $patterns=@(
            @{pattern='\b(?:readAllBytes|readAllLines|ByteArrayOutputStream|ByteArrayMultipartFile)\b';rule='AURA-BASE-RUNTIME-016';reason='整体字节/行集合或内存文件线索，核对输入上限和流生命周期'},
            @{pattern='\bdoReadSync\s*\(';rule='AURA-BASE-RUNTIME-017';reason='解析结果集中读取线索，核对展开行数和批次内存'},
            @{pattern='@(?:[\w.]+\.)?RequestExcel\b';rule='AURA-BASE-BE-053';reason='表格导入入口，核对有效行与解析错误、提交策略和结果计数'},
            @{pattern='@(?:[\w.]+\.)?ResponseExcel\b';rule='AURA-BASE-RUNTIME-019';reason='表格导出入口，核对有界List、字段权限和响应提交后的错误处理'}
        )
        if($mask -match '\bMultipartFile\b'){
            $patterns+=@{pattern='\.\s*getBytes\s*\(';rule='AURA-BASE-RUNTIME-016';reason='含MultipartFile的源码出现getBytes，须沿接收者确认是否全量加载文件'}
        }
        foreach($p in $patterns){foreach($m in [regex]::Matches($mask,$p.pattern)){
            $candidates.Add(@{path=$rel;line=(Get-BackendLine $text $m.Index);ruleId=$p.rule;message=$p.reason;status='candidate'})
        }}
    }
    $status=if($unknown.Count -or $candidates.Count){'partial'}else{'scan-complete'}
    $result=[ordered]@{schemaVersion=1;status=$status;summary=@{files=$files.Count;signals=$signals.Count;candidates=$candidates.Count;unresolved=$unknown.Count};files=@($files.ToArray());signals=@($signals.ToArray());candidates=@($candidates.ToArray());unresolved=@($unknown.ToArray());limitations=@('仅检查显式Java文件的词法线索；不解析依赖、SDK、权限、事务、文件内容或运行行为。','注解和内存读取只是复核入口，有界使用可能合理；零候选不代表业务符合。')}
    $exitCode=if($status -eq 'partial'){2}else{0}
} catch {
    $result=@{schemaVersion=1;status='failed';summary=@{files=$files.Count;candidates=$candidates.Count};issues=@(@{code='input_or_execution_error';message=$_.Exception.Message})}
    $exitCode=1
    $writeTarget=$null
}
$serialized=$result | ConvertTo-Json -Depth 8
if($writeTarget){
    $null=[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($writeTarget))
    [IO.File]::WriteAllText($writeTarget,$serialized,[Text.UTF8Encoding]::new($false))
}
if($Json){$serialized}else{"文件批处理盘点：$($result.status)，源码=$($files.Count)，候选=$($candidates.Count)，未读=$($unknown.Count)"}
exit $exitCode
