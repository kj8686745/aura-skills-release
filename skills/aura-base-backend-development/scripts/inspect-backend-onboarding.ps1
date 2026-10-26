#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$ProjectPath,
  [string[]]$ModulePath=@('.'),
  [string]$OutputPath,
  [string]$MarkdownPath,
  [string]$OutputDirectory,
  [int]$RecentCommitCount=20,
  [switch]$Json
)

$ErrorActionPreference='Stop'
$utf8=[Text.UTF8Encoding]::new($false)
function Resolve-Project([string]$Path){
  $resolved=(Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
  if(-not(Test-Path -LiteralPath $resolved -PathType Container)){throw 'ProjectPath 必须是目录'}
  $resolved
}
function Resolve-Module([string]$Root,[string]$Relative){
  if([IO.Path]::IsPathRooted($Relative)){throw 'ModulePath 必须是项目相对目录'}
  $target=[IO.Path]::GetFullPath((Join-Path $Root $Relative))
  $prefix=$Root.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
  if($target -ne $Root -and -not $target.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'ModulePath 超出项目根目录'}
  if(-not(Test-Path -LiteralPath $target -PathType Container)){throw "模块目录不存在：$Relative"}
  $target
}
function Relative([string]$Root,[string]$Path){[IO.Path]::GetRelativePath($Root,$Path).Replace('\','/')}
function Read-Safe([string]$Path){
  $text=[IO.File]::ReadAllText($Path)
  $text=$text -replace '(?s)```.*?```',''
  $text=$text -replace '(?m)^\s*[-*+]?\s*`[^`]+`\s*$',''
  $text
}
function Get-DocSummary([string]$Root,[string]$Path){
  $text=Read-Safe $Path
  $heading=[regex]::Match($text,'(?m)^\s*#\s+(.+?)\s*$').Groups[1].Value.Trim()
  $paragraph=''
  foreach($line in ($text -split "`r?`n")){
    $v=$line.Trim()
    if(-not $v -or $v.StartsWith('#') -or $v.StartsWith('|') -or $v.StartsWith('>') -or $v.StartsWith('<!--') -or $v.StartsWith('```')){continue}
    if($v.Length -ge 12){$paragraph=$v;break}
  }
  [ordered]@{path=(Relative $Root $Path);title=$heading;summary=if($paragraph.Length -gt 240){$paragraph.Substring(0,240)+'…'}else{$paragraph}}
}
function Get-JavaSummary([string]$Root,[string]$Path){
  $text=[IO.File]::ReadAllText($Path)
  $class=[regex]::Match($text,'(?m)\b(?:class|interface|record|enum)\s+(?<name>[A-Za-z_][A-Za-z0-9_]*)').Groups['name'].Value
  if(-not $class){return $null}
  $annotations=@([regex]::Matches($text,'@([A-Za-z_][A-Za-z0-9_.]*)') | ForEach-Object {$_.Groups[1].Value} | Select-Object -First 8)
  $role='other'
  if($text -match '\bSpringBootApplication\b'){$role='application-entry'}
  elseif($annotations -match 'RestController|Controller'){$role='controller'}
  elseif($annotations -match 'Configuration|ConfigurationProperties'){$role='configuration'}
  elseif($annotations -match 'Service|Component'){$role='service'}
  elseif(([IO.Path]::GetFileNameWithoutExtension($Path) -match '(?i)(Mapper|Repository|Dao|DAO)$') -or ($Path -match '(?i)[\\/]mapper[\\/]')){$role='data-access'}
  $comment=''
  $prefix=$text.Substring(0,[Math]::Min($text.Length,[Math]::Max(0,$text.IndexOf($class))))
  $javadocs=@([regex]::Matches($prefix,'(?s)/\*\*.*?\*/') | Select-Object -Last 1)
  if($javadocs.Count){
    $raw=$javadocs[0].Value
    if($raw.Length -ge 5){$comment=$raw.Substring(3,$raw.Length-5)}
    $comment=($comment -split "`r?`n" | ForEach-Object {($_ -replace '^\s*\*\s?','').Trim()} | Where-Object {$_ -and $_ -notmatch '^@'}) -join ' '
  }
  if($comment.Length -gt 240){$comment=$comment.Substring(0,240)+'…'}
  $purpose=if($comment){$comment}else{switch($role){'application-entry'{'应用启动入口（未提供类级说明）'}'controller'{'HTTP 接口入口（未提供类级说明）'}'service'{'业务服务或应用编排类（未提供类级说明）'}'data-access'{'数据访问类（未提供类级说明）'}'configuration'{'配置与基础设施装配类（未提供类级说明）'}default{'业务实现类（未提供类级说明）'}}}
  [ordered]@{path=(Relative $Root $Path);className=$class;role=$role;purpose=$purpose;annotations=$annotations;comment=$comment;commentFound=[bool]$comment}
}
function Invoke-GitText([string]$Root,[string[]]$GitArgs){@(& git -C $Root -c core.quotepath=false @GitArgs 2>$null | Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_)})}
function Get-GitPortrait([string]$Root,[string[]]$ModuleRoots,[int]$Limit){
  $head=@(Invoke-GitText $Root @('rev-parse','HEAD')) | Select-Object -First 1
  $branch=@(Invoke-GitText $Root @('branch','--show-current')) | Select-Object -First 1
  if(-not $head){return [ordered]@{available=$false}}
  $repoRoot=@(Invoke-GitText $Root @('rev-parse','--show-toplevel')) | Select-Object -First 1
  $inherited= -not [string]::Equals([IO.Path]::GetFullPath($repoRoot).TrimEnd([char[]]'\/'),$Root.TrimEnd([char[]]'\/'),[StringComparison]::OrdinalIgnoreCase)
  if([string]::IsNullOrWhiteSpace([string]$branch)){$branch='(detached HEAD)'}
  $paths=@('--')+$ModuleRoots
  $recent=@(Invoke-GitText $Root (@('log','-n',[string]$Limit,'--date=short','--format=%h|%ad|%an|%s')+$paths)) | ForEach-Object {
    $parts=[string]$_ -split '\|',4
    [ordered]@{commit=$parts[0];date=$parts[1];author=$parts[2];subject=if($parts.Count -gt 3){$parts[3]}else{''}}
  }
  $changed=@(Invoke-GitText $Root (@('log','-n',[string]$Limit,'--relative','--name-only','--format=')+$paths)) | Where-Object {$_ -and $_ -notmatch '^\s*$'} | Group-Object | Sort-Object Count -Descending | Select-Object -First 20 | ForEach-Object {[ordered]@{path=$_.Name.Replace('\','/');commitCount=$_.Count}}
  $status=@(Invoke-GitText $Root @('status','--short','--untracked-files=all','--','.')) | Where-Object { $_.Length -ge 4 -and $_.Substring(3).Trim('"').Replace('\','/') -notlike 'docs/临时验证物料/*' }
  [ordered]@{available=$true;repositoryRoot=$repoRoot;inheritedRepository=$inherited;branch=$branch;head=$head;dirtyCount=@($status).Count;statusScope='project-only; excludes docs/临时验证物料';recentCommits=@($recent);changeHotspots=@($changed);limitations=@('分支与HEAD是所属仓库元数据；工作树统计限当前项目，提交和热点限所选模块，不扫描外层项目文件。','提交主题反映 Git 记录，不等于完整需求说明；类职责来自注释、命名和结构线索，仍需按任务核对。')}
}
function Write-OnboardingMarkdown($Result,[string]$Path){
  $tick=[char]96
  $lines=[Collections.Generic.List[string]]::new()
  $lines.Add('# 后端项目 Git 画像与研读摘要');$lines.Add('')
  $lines.Add(('- 项目：{0}{1}{0}' -f $tick,$Result.projectRoot))
  $lines.Add("- 模块：$($Result.moduleRoots -join ', ')")
  $lines.Add("- 文件：$($Result.counts.files)，文档：$($Result.counts.documentation)，Java 类摘要：$($Result.counts.javaClasses)，已分类职责类：$($Result.counts.annotatedJava)");$lines.Add('')
  $lines.Add('## 一、Git 画像');$lines.Add('')
  if($Result.git.available){
    if($Result.git.inheritedRepository){$lines.Add('- 当前目录不是独立 Git 仓库；以下分支与提交来自外层所属仓库，工作树数量仅统计当前项目。');$lines.Add('')}
    $lines.Add(('- 分支：{0}{1}{0}' -f $tick,$Result.git.branch));$lines.Add(('- 当前提交：{0}{1}{0}' -f $tick,$Result.git.head));$lines.Add("- 工作树未提交项：$($Result.git.dirtyCount)");$lines.Add('');$lines.Add('### 最近提交与实现主题');$lines.Add('');foreach($c in $Result.git.recentCommits){$lines.Add(('- {0}{1}{0} {2} {3}' -f $tick,$c.commit,$c.date,$c.subject))};$lines.Add('');$lines.Add('### 变更热点');$lines.Add('');foreach($h in $Result.git.changeHotspots){$lines.Add(('- {0}{1}{0}：{2} 次提交命中' -f $tick,$h.path,$h.commitCount))}
  }else{$lines.Add('- 未发现 Git 仓库信息，只能使用文件和文档研读')}
  $lines.Add('');$lines.Add('## 二、项目与模块说明');$lines.Add('');foreach($d in @($Result.projectEntry+$Result.moduleDocumentation)){if($d){$lines.Add(('- {0}{1}{0}：{2}；{3}' -f $tick,$d.path,$d.title,$d.summary))}}
  $lines.Add('');$lines.Add('## 三、类职责与注释');$lines.Add('');foreach($role in @('application-entry','controller','service','data-access','configuration','other')){$group=@($Result.codeEntries|Where-Object role -eq $role);if($group.Count){$lines.Add("### $role（$($group.Count)）");$lines.Add('');foreach($c in $group){$lines.Add(('- {0}{1}{0} → {0}{2}{0}：{3}' -f $tick,$c.path,$c.className,$c.purpose))};$lines.Add('')}}
  $lines.Add('## 四、推荐阅读顺序');$lines.Add('');foreach($step in $Result.readOrder){$lines.Add("1. $step")};$lines.Add('');$lines.Add('## 五、研读缺口');$lines.Add('');if($Result.gaps.Count){foreach($gap in $Result.gaps){$lines.Add("- $gap")}}else{$lines.Add('- 未发现结构性研读缺口')};$lines.Add('');$lines.Add('## 六、边界');$lines.Add('');foreach($l in $Result.limitations){$lines.Add("- $l")}
  [IO.File]::WriteAllLines([IO.Path]::GetFullPath($Path),$lines,$utf8)
}
try{
  $root=Resolve-Project $ProjectPath
  $modules=@($ModulePath | ForEach-Object {Resolve-Module $root $_} | Select-Object -Unique)
  if([string]::IsNullOrWhiteSpace($OutputDirectory)){
    $moduleName=([IO.Path]::GetFileName(($modules | Select-Object -First 1))).ToLowerInvariant() -replace '[^a-z0-9一-龥_-]','-'
    $OutputDirectory=Join-Path $root (Join-Path 'docs/临时验证物料/后端项目研读' $moduleName)
  }else{
    $OutputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
    $projectPrefix=$root.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
    if(-not $OutputDirectory.StartsWith($projectPrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'OutputDirectory 必须位于项目根目录内'}
  }
  if(-not(Test-Path -LiteralPath $OutputDirectory -PathType Container)){New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null}
  if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path $OutputDirectory '后端项目研读摘要.json'}
  if([string]::IsNullOrWhiteSpace($MarkdownPath)){$MarkdownPath=Join-Path $OutputDirectory '后端项目Git画像.md'}
  $allFiles=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach($file in Get-ChildItem -LiteralPath $root -File -Force | Where-Object {$_.Name -match '^(README|pom\.xml|build\.gradle(?:\.kts)?|settings\.gradle(?:\.kts)?|mvnw|gradlew)'} ){$null=$allFiles.Add($file.FullName)}
  $rootDocs=Join-Path $root 'docs'
  if(Test-Path -LiteralPath $rootDocs -PathType Container){foreach($file in Get-ChildItem -LiteralPath $rootDocs -Recurse -File -Force | Where-Object {$_.Extension -in @('.md','.adoc','.txt')}){$null=$allFiles.Add($file.FullName)}}
  foreach($module in $modules){
    foreach($file in Get-ChildItem -LiteralPath $module -Recurse -File -Force | Where-Object {$_.FullName -notmatch '\\(?:target|build|node_modules|\.git|\.idea|\.gradle|out)(?:\\|$)'}){$null=$allFiles.Add($file.FullName)}
  }
  # 产物固定在项目内，但不能再次被当成项目文档或源码统计；否则重复运行会让数量漂移。
  $outputPrefix=[IO.Path]::GetFullPath($OutputDirectory).TrimEnd([char[]]'\\/')+[IO.Path]::DirectorySeparatorChar
  $generatedRoot=Join-Path $root 'docs/临时验证物料'
  $generatedPrefix=[IO.Path]::GetFullPath($generatedRoot).TrimEnd([char[]]'\\/')+[IO.Path]::DirectorySeparatorChar
  # 项目内的研读、审查和注释产物都属于验证物料，不能再次进入项目画像统计。
  $allFiles=@($allFiles | Where-Object {-not $_.StartsWith($outputPrefix,[StringComparison]::OrdinalIgnoreCase) -and -not $_.StartsWith($generatedPrefix,[StringComparison]::OrdinalIgnoreCase)})
  $docs=@($allFiles | Where-Object {[IO.Path]::GetExtension($_).ToLowerInvariant() -in @('.md','.adoc','.txt') -and $_ -match '(?i)(README|说明|文档|guide|overview|docs)'} | ForEach-Object {Get-DocSummary $root $_} | Select-Object -First 40)
  $build=@($allFiles | Where-Object {[IO.Path]::GetFileName($_) -in @('pom.xml','build.gradle','build.gradle.kts','settings.gradle','settings.gradle.kts','gradlew','mvnw')} | ForEach-Object {[ordered]@{path=(Relative $root $_);type=[IO.Path]::GetFileName($_)}} | Select-Object -First 30)
  $java=@($allFiles | Where-Object {[IO.Path]::GetExtension($_).ToLowerInvariant() -eq '.java'} | ForEach-Object {Get-JavaSummary $root $_} | Where-Object {$_})
  $moduleDocs=@($docs | Where-Object {$_.path -match '(?i)(^|/)README|docs/|说明|文档'} | Select-Object -First 20)
  $result=[ordered]@{
    schemaVersion=1
    status='complete'
    projectRoot=$root
    moduleRoots=@($modules | ForEach-Object {Relative $root $_})
    counts=[ordered]@{files=$allFiles.Count;documentation=$docs.Count;buildFiles=$build.Count;javaClasses=$java.Count;annotatedJava=@($java | Where-Object role -ne 'other').Count}
    projectEntry=@($docs | Where-Object {$_.path -notmatch '/'} | Select-Object -First 5)
    moduleDocumentation=@($moduleDocs)
    buildEntries=@($build)
    codeEntries=@($java)
    output=[ordered]@{directory=$OutputDirectory;json=$OutputPath;markdown=$MarkdownPath}
    git=Get-GitPortrait $root @($modules | ForEach-Object {Relative $root $_}) $RecentCommitCount
    readOrder=@('项目根 README 或总说明','模块 README/docs 与模块说明','构建文件和模块依赖','SpringBootApplication/配置入口','Controller → Service → DAO/Mapper → 外部 Client','按实际需求再读取对应能力和规范')
    gaps=@(
      if(-not $docs.Count){'未发现 README/docs 说明文件'}
      if(-not $build.Count){'未发现 Maven/Gradle 构建入口'}
      if(-not @($java | Where-Object role -eq 'application-entry').Count){'未发现 SpringBootApplication 启动类'}
      if(-not @($java | Where-Object {$_.comment}).Count){'未发现可提取的类级注释'}
    )
    limitations=@('只输出文档摘要、类角色和注释片段，不输出完整源码、配置值或调用链结论。','无框架角色的类保留为 other；每个 Java 文件只采集首个可识别类型，不保证嵌套类型和方法覆盖。','注释缺失只记录为研读缺口，不直接判定项目规范偏差。','继承、组合注解、动态注册和运行时行为需要后续按任务核对。')
  }
  $serialized=$result|ConvertTo-Json -Depth 12
  if($OutputPath){[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath),$serialized,$utf8)}
  if($MarkdownPath){Write-OnboardingMarkdown $result $MarkdownPath}
  if($Json){$serialized}else{"后端项目研读摘要完成：文件=$($allFiles.Count)，文档=$($docs.Count)，入口=$(@($java|Where-Object role -eq 'application-entry').Count)，注释=$(@($java|Where-Object comment).Count)"}
}catch{
  if($Json){[ordered]@{schemaVersion=1;status='failed';errorType=$_.Exception.GetType().Name}|ConvertTo-Json}else{'后端项目研读摘要失败'}
  exit 1
}
