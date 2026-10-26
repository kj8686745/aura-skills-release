#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ProjectPath,[string[]]$ModulePath=@('.'),[ValidateSet('Auto','Required')][string]$ApiMode='Auto',[string]$OutputPath,[switch]$Json)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'backend-common.ps1')
$candidates=[Collections.Generic.List[object]]::new();$unresolved=[Collections.Generic.List[object]]::new()
$checked=[Collections.Generic.List[string]]::new();$reuse=[Collections.Generic.List[object]]::new()
$boundary=[ordered]@{external=0;internalCandidate=0;unresolved=0;platformAnnotationOnInternal=0}
function Add-Candidate($Rule,$Path,$Line,$Message,$Review){$candidates.Add(@{ruleId=$Rule;path=$Path;line=$Line;status='candidate';message=$Message;review=$Review})}
try{
  $scope=Get-BackendScope $ProjectPath $ModulePath
  foreach($file in $scope.files){
    $rel=[IO.Path]::GetRelativePath($scope.root,$file).Replace('\','/')
    $text=[IO.File]::ReadAllText($file)
    foreach($secret in @(Get-BackendSensitiveCandidates $text $rel)){
      Add-Candidate 'AURA-BASE-CONF-001' $secret.path $secret.line $secret.message $secret.review
    }
    if($rel -notlike '*.java' -or $rel -match '(^|/)src/test/'){continue}
    $checked.Add($rel);$mask=Get-BackendMask $text
    $controller=$mask -match '@(?:[\w.]+\.)?(RestController|Controller)\b'
    $service=$mask -match '@(?:[\w.]+\.)?Service\b'
    if($controller -or $service){
      foreach($m in [regex]::Matches($mask,'\b(?:JdbcTemplate|NamedParameterJdbcTemplate|Statement|PreparedStatement|EntityManager)\b|\.\s*(?:createStatement|prepareStatement|createNativeQuery)\s*\(')){
        Add-Candidate $(if($controller){'AURA-BASE-BE-004'}else{'AURA-BASE-BE-001'}) $rel (Get-BackendLine $text $m.Index) '入口/用例直接出现底层数据访问线索' '沿字段和调用核对真实职责；import、同名类型或适配器不能直接判为违规。'
      }
    }
    foreach($m in [regex]::Matches($mask,'\bnew\s+(?:java\.lang\.)?Thread\s*\(|\bExecutors\s*\.\s*new\w+\s*\(')){
      Add-Candidate 'AURA-BASE-BE-040' $rel (Get-BackendLine $text $m.Index) '自行创建线程或执行器' '核对生命周期、配置、容量与关闭归属；受控运行时组件可能合理。'
    }
    foreach($m in [regex]::Matches($mask,'\b(?:class|record|interface)\s+(?:R|PageResult|OpenPage|SecurityUtils)\b')){
      Add-Candidate 'AURA-BASE-BE-022' $rel (Get-BackendLine $text $m.Index) '本地声明与基础公共入口同名的类型' '核对包名、源码来源和职责；必须复用已提供的基础能力，不能仅凭名字认定重复。'
    }
    $markers=@([regex]::Matches($mask,'\b(?:BaseEntity|BaseMapper|ServiceImpl|SecurityUtils|HasPermission|TenantContextHolder|FileTemplate|R)\b') | ForEach-Object Value | Sort-Object -Unique)
    if($markers.Count){$reuse.Add(@{path=$rel;symbols=$markers;status='reference-only';review='追踪真实公开类型和调用链；符号/import 存在不证明复用或运行生效。'})}
  }
  if(-not $checked.Count){$unresolved.Add(@{path='';reason='指定范围无生产 Java 文件'})}
  $api=Invoke-BackendApiInventory $scope $ApiMode
  foreach($issue in $api.unresolved){$unresolved.Add($issue)}
  foreach($route in $api.routes){
    $public=$route.path -match '^/openapi(?:/|$)';$platform=$route.platformApi
    if($public){$boundary.external++}elseif($platform){$boundary.platformAnnotationOnInternal++;$boundary.unresolved++;Add-Candidate 'AURA-BASE-API-026' $route.source $route.line '内部路径发现 @PlatfomApi，需确认是否误标对外平台 API' '内部接口不应为自动收录添加平台注解；确认边界后保留或移除。'}else{$boundary.internalCandidate++}
    if($route.returnType -match '\b(?:IPage|Page|OpenPage)\s*<'){
      Add-Candidate 'AURA-BASE-API-014' $route.source $route.line 'HTTP 签名暴露 ORM 或独立分页类型' '解析实际类型与适配层，按统一公共分页目标核对；框架缺公共类型时报告缺口，不新造同名类型。'
    }
    if($route.returnType -notmatch '^(?:[\w$]+\.)*R\s*<'){
      Add-Candidate 'AURA-BASE-BE-006' $route.source $route.line 'HTTP 返回签名不直接使用泛型 R<T>' '核对实际全局封装与特殊文件/流协议；不能把所有非 JSON 下载接口机械改为 R。'
    }
    if($route.returnType -match '\b\w+Entity\b'){
      Add-Candidate 'AURA-BASE-BE-006' $route.source $route.line 'HTTP 签名包含 Entity 命名类型' '查类型是否为持久化实体，以及是否有公开模型转换；名称不是最终证据。'
    }
    if($public -and -not $platform){Add-Candidate 'AURA-BASE-API-026' $route.source $route.line '公开路径未发现直接 @PlatfomApi 登记' '核对方法、注解和平台收录；不向内部接口统一补注解。'}
    if($platform){
      if(-not $public){Add-Candidate 'AURA-BASE-API-026' $route.source $route.line '平台 API 注解路径未以 /openapi 开头' '确认接口是否对外及网关最终路径，不根据类名推断边界。'}
      foreach($key in @('code','version','name','requestPath')){
        if(-not $platform["${key}Expression"] -or ($null -ne $platform[$key] -and [string]::IsNullOrWhiteSpace($platform[$key]))){Add-Candidate 'AURA-BASE-API-026' $route.source $route.line "平台 API 缺少或留空 $key" '补齐真实登记契约，不虚构常量或网关配置。'}
        elseif($null -eq $platform[$key]){$unresolved.Add(@{path=$route.source;line=$route.line;reason="平台 API $key 使用表达式，需解析实际值"})}
      }
      if($platform.requestPath -and $platform.requestPath -cne $route.path){Add-Candidate 'AURA-BASE-API-026' $route.source $route.line 'requestPath 与直接 Controller 映射不一致' '核对完整映射、变量正则及实际网关登记。'}
    }
  }
  foreach($path in $scope.skipped){$unresolved.Add(@{path=$path;reason='跳过重解析点'})}
  $result=[ordered]@{schemaVersion=1;status=$(if($candidates.Count -or $unresolved.Count){'needs-review'}else{'scan-complete'});project=$scope.root;modules=$ModulePath;files=@($checked.ToArray());candidates=@($candidates.ToArray());capabilityReferences=@($reuse.ToArray());unresolved=@($unresolved.ToArray());apiBoundary=$boundary;coverage=@('入口底层数据访问线索','线程创建','同名基础入口','直接 HTTP 响应/分页/Entity 类型','OpenAPI 路径与平台注解','敏感配置字面值候选');requiredSemanticReview=@('基础业务和公共支撑对应功能是否沿真实公开入口复用；未命中符号不能判断无复用。','DTO 全字段、权限/租户、事务/缓存/幂等和调用方兼容，按改动范围核对。','接口边界需由任务/文档/网关事实确认；internalCandidate 不是内部结论，external 需核对公开登记。','敏感配置候选必须区分真实凭据、测试夹具、占位符和环境变量引用，不回显字面值。');limitations=@('所有命中都是待复核候选，不自动整改或给出整个项目合规结论。','只扫描指定目录，排除测试与生成文件；继承、动态或组合映射需补证，网关及运行未验证。','敏感配置扫描覆盖受控的 Java 字符串/字符数组声明及常见配置资源，不替代历史提交、镜像、日志和二进制扫描。')}
  $result['api']=@{status=$api.status;limitations=@($api.limitations)}
  $result['reviewFocus']=@(Get-BackendReviewFocus $scope)
  $code=if($candidates.Count -or $unresolved.Count){2}else{0}
}catch{$result=@{schemaVersion=1;status='failed';candidates=@();unresolved=@(@{reason=$_.Exception.Message})};$code=1}
Write-BackendResult $result $OutputPath $Json "后端静态候选：$($result.status)，文件=$($checked.Count)，候选=$($candidates.Count)，待补证=$(@($result.unresolved).Count)"
exit $code
