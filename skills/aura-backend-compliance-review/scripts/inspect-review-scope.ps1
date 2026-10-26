#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$ProjectPath,
  [string[]]$ModulePath=@('.'),
  [string]$BaseRef,
  [string]$HeadRef='HEAD',
  [switch]$IncludeWorkingTree,
  [string]$OutputPath,
  [switch]$IncludeFiles,
  [switch]$IncludeCapabilityCandidates,
  [switch]$Json
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'backend-common.ps1')

function Get-XmlValue($Node,[string]$Name) {
  $child=@($Node.ChildNodes | Where-Object LocalName -eq $Name | Select-Object -First 1)
  if($child.Count){ return [string]$child[0].InnerText }
  return $null
}

function Add-Dependency($List,[hashtable]$Dependency) {
  if([string]::IsNullOrWhiteSpace([string]$Dependency.artifact)){ return }
  $text=('{0}:{1} {2}' -f $Dependency.group,$Dependency.artifact,$Dependency.version)
  $isFramework=([string]$Dependency.group -match '^(?i:org\.springframework|org\.springframework\.boot|org\.springframework\.cloud|com\.alibaba\.cloud|io\.micrometer)$') -or ([string]$Dependency.artifact -match '^(?i:spring-boot|spring-cloud|spring-|micrometer-)')
  $Dependency.frameworkLike=$isFramework
  $Dependency.sdkLike=([bool](-not $isFramework -and $text -match '(?i)sdk|starter|client|feign|openapi|oss|storage|socket|mqtt|video|iot|gateway'))
  $List.Add($Dependency)
}

function Invoke-GitText([string]$Root,[string[]]$Arguments) {
  $start=[Diagnostics.ProcessStartInfo]::new()
  $start.FileName='git.exe'
  $start.UseShellExecute=$false
  $start.RedirectStandardOutput=$true
  $start.RedirectStandardError=$true
  $start.ArgumentList.Add('-C')
  $start.ArgumentList.Add($Root)
  foreach($argument in @($Arguments)){$start.ArgumentList.Add([string]$argument)}
  $proc=[Diagnostics.Process]::Start($start)
  $stdout=$proc.StandardOutput.ReadToEndAsync()
  $stderr=$proc.StandardError.ReadToEndAsync()
  $proc.WaitForExit()
  $outText=$stdout.GetAwaiter().GetResult()
  $errorText=$stderr.GetAwaiter().GetResult()
  $lines=@($outText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
  if($proc.ExitCode -ne 0 -and $errorText){$lines += @($errorText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })}
  $code=$proc.ExitCode
  $proc.Dispose()
  return @{code=$code;lines=$lines}
}

function Convert-GitNameStatus($Lines) {
  $items=[Collections.Generic.List[object]]::new()
  foreach($line in @($Lines)) {
    if([string]::IsNullOrWhiteSpace([string]$line)){continue}
    $parts=([string]$line) -split "`t",2
    if($parts.Count -lt 2){$items.Add(@{status='?';path=([string]$line).Trim()});continue}
    $items.Add(@{status=$parts[0].Trim();path=$parts[1].Trim()})
  }
  return @($items.ToArray())
}

function Convert-GitStatus($Lines) {
  $items=[Collections.Generic.List[object]]::new()
  foreach($line in @($Lines)) {
    if([string]::IsNullOrWhiteSpace([string]$line)){continue}
    $text=[string]$line
    if($text.Length -lt 4){$items.Add(@{status=$text.Trim();path=$null});continue}
    $items.Add(@{status=$text.Substring(0,2);path=$text.Substring(3).Trim()})
  }
  return @($items.ToArray())
}

function Test-ExcludedGitPath([string]$Path,[string[]]$Exclusions) {
  $normalized=([string]$Path).Replace('\','/').TrimStart('./')
  foreach($excluded in @($Exclusions)) {
    if([string]::IsNullOrWhiteSpace([string]$excluded)){continue}
    $candidate=([string]$excluded).Replace('\','/').TrimStart('./').TrimEnd('/')
    if($normalized -eq $candidate -or $normalized.StartsWith($candidate+'/',[StringComparison]::OrdinalIgnoreCase)){return $true}
  }
  return $false
}

$dependencies=[Collections.Generic.List[object]]::new()
$usageCandidates=[Collections.Generic.List[object]]::new()
$unresolved=[Collections.Generic.List[object]]::new()
$configurationEvidence=[Collections.Generic.List[object]]::new()
try {
  $scope=Get-BackendScope $ProjectPath $ModulePath
  $outputFull=if($OutputPath){[IO.Path]::GetFullPath($OutputPath)}else{$null}
  $files=@($scope.files | Where-Object { -not $outputFull -or -not [string]::Equals($_,$outputFull,[StringComparison]::OrdinalIgnoreCase) })
  $relativePaths=@($files | ForEach-Object { [IO.Path]::GetRelativePath($scope.root,$_).Replace('\','/') })
  $configPattern='(^|/)(application[^/]*\.(yml|yaml|properties)|bootstrap[^/]*\.(yml|yaml|properties))$'
  $categories=[ordered]@{
    source=@($files | Where-Object { $_ -match '\.(java|kt|groovy)$' }).Count
    build=@($files | Where-Object { [IO.Path]::GetFileName($_) -in @('pom.xml','build.gradle','build.gradle.kts','settings.gradle','settings.gradle.kts') }).Count
    configuration=@($relativePaths | Where-Object { $_ -match $configPattern }).Count
    documentation=@($files | Where-Object { $_ -match '\.(md|adoc|rst)$' }).Count
    tests=@($relativePaths | Where-Object { $_ -match '(^|/)(src/test|src/it)/' }).Count
  }
  foreach($file in $files){
    $relative=[IO.Path]::GetRelativePath($scope.root,$file).Replace('\','/')
    $name=[IO.Path]::GetFileName($file)
    if($relative -match $configPattern){
      $bytes=[IO.File]::ReadAllBytes($file)
      $configurationEvidence.Add(@{path=$relative;bytes=$bytes.Length;sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant();contentIncluded=$false})
    }
    if($name -eq 'pom.xml'){
      try {
        $xml=[Xml.XmlDocument]::new();$xml.XmlResolver=$null;$xml.Load($file)
        foreach($dep in @($xml.GetElementsByTagName('dependency'))){
          Add-Dependency $dependencies ([ordered]@{kind='maven';path=$relative;group=Get-XmlValue $dep 'groupId';artifact=Get-XmlValue $dep 'artifactId';version=Get-XmlValue $dep 'version';scope=Get-XmlValue $dep 'scope'})
        }
      } catch { $unresolved.Add(@{path=$relative;reason='构建声明无法解析';errorType=$_.Exception.GetType().Name;detail='解析异常正文不输出；可能包含原始配置值，请在本地核对文件'}) }
    } elseif($name -match '^build\.gradle(?:\.kts)?$'){
      $text=[IO.File]::ReadAllText($file)
      foreach($m in [regex]::Matches($text,'(?m)^\s*(?<kind>implementation|api|compileOnly|runtimeOnly|testImplementation)\s*[\(]?\s*["''](?<coord>[^"'']+)["'']')){
        $parts=$m.Groups['coord'].Value -split ':',3
        Add-Dependency $dependencies ([ordered]@{kind='gradle';path=$relative;group=$(if($parts.Count -gt 0){$parts[0]}else{$null});artifact=$(if($parts.Count -gt 1){$parts[1]}else{$null});version=$(if($parts.Count -gt 2){$parts[2]}else{$null});scope=$m.Groups['kind'].Value})
      }
      if($text -match '(?m)^\s*(?:implementation|api|compileOnly|runtimeOnly|testImplementation)\s*[^\r\n]*(?:\$|project\(|versionCatalog)'){
        $unresolved.Add(@{path=$relative;reason='Gradle 依赖使用变量或项目引用，坐标需人工核对'})
      }
    } elseif($name -like '*.java'){
      $mask=Get-BackendMask ([IO.File]::ReadAllText($file))
      foreach($m in [regex]::Matches($mask,'(?m)^\s*import\s+[^;]*(?i:Sdk|SDK|Client|Feign|OpenAPI|Oss|Storage|Socket|Mqtt|Video|Iot)[^;]*;|\b@FeignClient\b|\bnew\s+\w*(?:Client|Sdk|SDK)\b')){
        $pattern=if($m.Value -match '(?i)FeignClient'){'FeignClient'}elseif($m.Value -match '(?i)^\s*import'){'external-client-import'}else{'client-construction'}
        $usageCandidates.Add(@{path=$relative;line=Get-BackendLine $mask $m.Index;pattern=$pattern})
      }
    }
  }
  foreach($dependency in @($dependencies.ToArray() | Where-Object { $_.sdkLike -and ([string]::IsNullOrWhiteSpace([string]$_.version) -or [string]$_.version -match '^\$\{.+\}$') })){
    $unresolved.Add(@{path=$dependency.path;reason='SDK 候选版本由 BOM/属性继承，需人工核对最终版本';dependency=('{0}:{1}' -f $dependency.group,$dependency.artifact)})
  }
  $sdkCandidates=@($dependencies | Where-Object { $_.sdkLike })
  $relativeFiles=@($files | ForEach-Object { [IO.Path]::GetRelativePath($scope.root,$_).Replace('\','/') })
  $fileDigestInput=[Text.Encoding]::UTF8.GetBytes(($relativeFiles -join "`n"))
  $fileDigest=([BitConverter]::ToString(([Security.Cryptography.SHA256]::Create().ComputeHash($fileDigestInput)))).Replace('-','').ToLowerInvariant()
  $scopeResult=[ordered]@{
    includedFileCount=$relativeFiles.Count
    includedFileDigest=$fileDigest
    skippedReparsePoints=@($scope.skipped)
    excludedDirectoryNames=@('.git','target','build','node_modules','.idea','.gradle','out')
    outputExcluded=$true
    excludedOutputPath=$(if($outputFull -and $outputFull -in @($scope.files)){[IO.Path]::GetRelativePath($scope.root,$outputFull).Replace('\','/')}else{$null})
    digestKind='sorted-relative-paths-only; not a content snapshot'
    scanPolicy=@{version=1;modulePaths=@($ModulePath);followReparsePoints=$false;configurationPattern=$configPattern;configurationContentIncluded=$false;categoriesOverlap=$true;outputExclusion='explicit OutputPath file only; other report files require a source-only ModulePath'}
  }
  if($IncludeFiles){$scopeResult.includedFiles=$relativeFiles}else{$scopeResult.fileListing='已省略；需要逐文件资产目录时使用 -IncludeFiles'}
  $gitResult=[ordered]@{
    status='not-requested'
    repoRoot=$null
    projectPath=$null
    branch=$null
    headRef=$HeadRef
    headCommit=$null
    baseRef=$BaseRef
    baseCommit=$null
    baseToHead=@()
    workingTree=@()
    untracked=@()
    workingTreeIncluded=[bool]$IncludeWorkingTree
    exclusions=@()
    limitations=@()
  }
  if($BaseRef -or $IncludeWorkingTree) {
    $probe=Invoke-GitText $scope.root @('rev-parse','--show-toplevel')
    if($probe.code -ne 0 -or -not @($probe.lines).Count){throw "无法在项目范围内定位 Git 仓库：$(@($probe.lines) -join ' ')"}
    $gitRoot=(Resolve-Path -LiteralPath ([string]$probe.lines[0])).Path
    $projectRelative=[IO.Path]::GetRelativePath($gitRoot,$scope.root).Replace('\','/')
    $gitResult.repoRoot=$gitRoot
    $gitResult.projectPath=$projectRelative
    $branchProbe=Invoke-GitText $gitRoot @('symbolic-ref','--short','-q','HEAD')
    if($branchProbe.code -eq 0 -and @($branchProbe.lines).Count){$gitResult.branch=[string]$branchProbe.lines[0]}else{$gitResult.branch='(detached HEAD)'}
    $headProbe=Invoke-GitText $gitRoot @('rev-parse','--verify',"$HeadRef`^{commit}")
    if($headProbe.code -ne 0 -or -not @($headProbe.lines).Count){throw "无法解析 HeadRef：$HeadRef"}
    $gitResult.headCommit=([string]$headProbe.lines[0]).Trim()
    $outputExclusions=@()
    if($OutputPath){
      $outputFull=[IO.Path]::GetFullPath($OutputPath)
      if($outputFull.StartsWith($gitRoot.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){$outputExclusions+=([IO.Path]::GetRelativePath($gitRoot,$outputFull).Replace('\','/'))}
    }
    $allExclusions=@($outputExclusions + @()) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Sort-Object -Unique
    $gitResult.exclusions=@($allExclusions | ForEach-Object {@{path=$_;reason='审查输出路径，不纳入未跟踪资产'}})
    if($BaseRef){
      $baseProbe=Invoke-GitText $gitRoot @('rev-parse','--verify',"$BaseRef`^{commit}")
      if($baseProbe.code -ne 0 -or -not @($baseProbe.lines).Count){$gitResult.limitations+=@("无法解析 BaseRef：$BaseRef")}
      else {
        $gitResult.baseCommit=([string]$baseProbe.lines[0]).Trim()
        $diffProbe=Invoke-GitText $gitRoot @('diff','--name-status','--no-renames',"$BaseRef`^{commit}","$HeadRef`^{commit}")
        if($diffProbe.code -ne 0){$gitResult.limitations+=@('无法读取 base/head 差异')}
        else {$gitResult.baseToHead=@(Convert-GitNameStatus $diffProbe.lines | Where-Object { -not (Test-ExcludedGitPath $_.path $allExclusions) })}
      }
    }else{$gitResult.limitations+=@('未提供 BaseRef，只能记录工作树；不能声称差异相对基线完整')}
    if($IncludeWorkingTree){
      $staged=Invoke-GitText $gitRoot @('diff','--cached','--name-status','--no-renames')
      $unstaged=Invoke-GitText $gitRoot @('diff','--name-status','--no-renames')
      $untrackedProbe=Invoke-GitText $gitRoot @('ls-files','--others','--exclude-standard')
      $workingTreeLines=@($staged.lines)+@($unstaged.lines)
      $gitResult.workingTree=@(Convert-GitNameStatus $workingTreeLines | Where-Object { -not (Test-ExcludedGitPath $_.path $allExclusions) })
      $gitResult.untracked=@($untrackedProbe.lines | ForEach-Object {@{status='??';path=([string]$_).Trim()}} | Where-Object { -not (Test-ExcludedGitPath $_.path $allExclusions) })
      if($staged.code -ne 0 -or $unstaged.code -ne 0 -or $untrackedProbe.code -ne 0){$gitResult.limitations+=@('工作树差异或未跟踪文件读取不完整')}
    }
    $digestLines=@($gitResult.baseToHead + $gitResult.workingTree + $gitResult.untracked | ForEach-Object {"$($_.status)`t$($_.path)"} | Sort-Object)
    $digestInput=[Text.Encoding]::UTF8.GetBytes(($digestLines -join "`n"))
    $gitResult.scopeId=([BitConverter]::ToString(([Security.Cryptography.SHA256]::Create().ComputeHash($digestInput)))).Replace('-','').ToLowerInvariant()
    $gitResult.status=if($BaseRef -and $gitResult.baseCommit -and -not $gitResult.limitations.Count){'complete'}else{'partial'}
  }
  $result=[ordered]@{
    schemaVersion=1
    status=$(if($unresolved.Count){'partial'}else{'complete'})
    projectRoot=$scope.root
    moduleRoots=@($ModulePath)
    scope=$scopeResult
    git=$gitResult
    categories=$categories
    dependencies=@($dependencies.ToArray())
    sdkCandidates=$sdkCandidates
    localUsageCandidates=@($usageCandidates.ToArray())
    configurationEvidence=@($configurationEvidence.ToArray())
    evidencePolicy=@{configuration='path, byte length and SHA-256 only; no keys or values';parseErrors='error type and file path only; raw parser messages omitted';limits='not a general secret scanner; source/dependency metadata and manually collected evidence still require review'}
    boundary=@{
      inspect='当前项目内依赖声明、配置、调用、适配和公开契约'
      stopAt='当前项目的 Client/Adapter 调用出口'
      doNotInspect=@('Maven/Gradle缓存','JAR反编译或其中源码','邻仓库或供应商源码','SDK内部线程/连接池/重试实现')
      externalImplementationFetched=$false
    }
    unresolved=@($unresolved.ToArray())
    limitations=@('依赖清单来自项目内构建声明，不解析依赖树或实际制品。','sdkCandidates 和 localUsageCandidates 只是项目内取证队列，不代表能力复用正确或存在偏差。','规则适用性、调用链、调用是否符合公开契约和严重性必须由审查 Agent 判断。')
  }
  if($IncludeCapabilityCandidates){
    . (Join-Path $PSScriptRoot 'capability-candidates.ps1')
    $result.capabilityReuse=Get-CapabilityReuseCandidates $scope.root $files @($dependencies.ToArray()) @($configurationEvidence.ToArray())
  }
  $code=if($unresolved.Count){2}else{0}
} catch {
  $result=[ordered]@{schemaVersion=1;status='failed';unresolved=@(@{reason=$_.Exception.Message})};$code=1
}
Write-BackendResult $result $OutputPath $Json "审查范围：$($result.status)，文件=$($result.scope.includedFileCount)，依赖=$(@($result.dependencies).Count)，SDK候选=$(@($result.sdkCandidates).Count)，待核实=$(@($result.unresolved).Count)"
exit $code
