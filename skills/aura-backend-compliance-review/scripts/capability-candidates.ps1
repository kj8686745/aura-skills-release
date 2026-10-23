# Internal helper for inspect-review-scope.ps1; no downloads or dependency resolution.
function Get-CapabilityReuseCandidates($Root,$Files,$Dependencies,$ConfigurationEvidence) {
  $base='references/standards/05-能力包/01-通用工具类/'
  $definitions=@(
    @{id='AURA-CAP-COMMON-BUSINESS';doc=$base+'01-基础业务开发能力包/总入口.md';dependencies='^aura-common-(service-starter|core|data)$';features=@(
      @{name='数据访问与实体';symbols=@('BaseEntity','BaseMapper','ServiceImpl');alternatives=@('JdbcTemplate','EntityManager');config='^(spring\.datasource|mybatis-plus)\.'}
    )},
    @{id='AURA-CAP-BASE';doc=$base+'03-基础通用支撑能力包/02-能力清单与边界.md';dependencies='^aura-common-(service-starter|core|data|security|log|audit|feign|oss)$';features=@(
      @{name='统一响应与 JSON';symbols=@('R','RetOps','JsonUtils','CustomException');alternatives=@('ObjectMapper','ResponseEntity');config='^spring\.jackson\.'},
      @{name='身份权限与租户';symbols=@('SecurityUtils','HasPermission','TenantContextHolder','TenantBroker');alternatives=@('SecurityContextHolder');config='^(security|spring\.security)\.'},
      @{name='缓存';symbols=@('RedisUtils');alternatives=@('RedisTemplate','StringRedisTemplate');config='^spring\.(data\.)?redis\.'},
      @{name='日志与审计';symbols=@('SysLog','SysLogUtils','Audit');alternatives=@();config='^logging\.'},
      @{name='服务间调用';symbols=@('FeignClient');alternatives=@('RestTemplate','WebClient');config='^(spring\.cloud\.openfeign|feign)\.'},
      @{name='文件存储';symbols=@('FileTemplate','LocalFileTemplate','OssTemplate');alternatives=@('MinioClient','S3Client');config='^file\.(oss|local)\.'}
    )}
  )
  $records=[Collections.Generic.List[object]]::new()
  $scanFiles=[Collections.Generic.List[string]]::new()
  $configPaths=@($ConfigurationEvidence | ForEach-Object {$_.path})
  foreach($file in $Files){
    $rel=[IO.Path]::GetRelativePath($Root,$file).Replace('\','/')
    if($rel -notlike '*.java' -or $rel -match '(^|/)src/(test|it)/'){continue}
    $scanFiles.Add($rel)
    $mask=Get-BackendMask ([IO.File]::ReadAllText($file))
    foreach($definition in $definitions){foreach($feature in $definition.features){
      foreach($symbol in @($feature.symbols)+@($feature.alternatives)){
        $pattern='\b'+[regex]::Escape($symbol)+'\b'
        foreach($match in [regex]::Matches($mask,$pattern)){
          $line=Get-BackendLine $mask $match.Index
          $start=$mask.LastIndexOf("`n",[Math]::Max(0,$match.Index-1))+1
          $prefix=$mask.Substring($start,$match.Index-$start)
          $tail=$mask.Substring($match.Index+$match.Length)
          $kind=if($prefix -match '\b(?:class|record|interface|enum)\s+$'){'local-declaration'}elseif($prefix -match '^\s*import\s+'){'import'}elseif($tail -match '^\s*\.\s*\w+\s*\('){'member-call'}else{'symbol-reference'}
          $records.Add(@{capabilityId=$definition.id;feature=$feature.name;path=$rel;line=$line;symbol=$symbol;kind=$kind;signal=$(if($symbol -in $feature.symbols){'public-entry-name'}else{'alternative-implementation-hint'})})
        }
      }
    }}
  }
  # Properties keys only. Do not parse YAML blocks or emit values / source lines.
  foreach($file in $Files){
    $rel=[IO.Path]::GetRelativePath($Root,$file).Replace('\','/')
    if($rel -notin $configPaths -or $rel -notlike '*.properties'){continue}
    $line=0;$continued=$false
    foreach($text in [IO.File]::ReadLines($file)){
      $line++
      $isContinuation=$continued
      if(-not $isContinuation -and $text -match '^\s*[#!]'){$continued=$false;continue}
      $continued=([regex]::Match($text,'\\+$').Length % 2) -eq 1
      if($isContinuation){continue}
      if($text -notmatch '^\s*(?<key>[A-Za-z_][A-Za-z0-9_.-]*)\s*[=:]'){continue}
      $key=$Matches.key
      foreach($definition in $definitions){foreach($feature in $definition.features){
        if($key -match $feature.config){$records.Add(@{capabilityId=$definition.id;feature=$feature.name;path=$rel;line=$line;symbol=$null;kind='configuration-key';signal='configuration-location-only'})}
      }}
    }
  }
  $ledger=foreach($definition in $definitions){
    $signals=@($records | Where-Object capabilityId -eq $definition.id | Sort-Object path,line,symbol,kind -Unique)
    $deps=@($Dependencies | Where-Object {$_.artifact -match $definition.dependencies} | Sort-Object path,group,artifact,version,scope -Unique)
    @{
      capabilityId=$definition.id
      reuseLevel='基础必查'
      publicReference=$definition.doc
      expectedEntryVersion='核对目标工程实际版本与公开契约；不以本工具映射代表兼容性'
      triggerStatus=$(if($signals.Count -or $deps.Count){'signals-found'}else{'not-observed'})
      dependencyDeclarations=$deps
      configurationFiles=@($ConfigurationEvidence)
      signals=$signals
      possibleDuplicateImplementations=@($signals | Where-Object {$_.kind -eq 'local-declaration' -or ($_.signal -eq 'alternative-implementation-hint' -and $_.kind -ne 'import')})
      reviewStatus='not-evaluated'
      requiredReview=@('核对实际功能及能力适用性；未命中不是不适用','解析真实类型和项目内调用/配置链；import、同名类和依赖均不证明复用','对照目标版本的公开入口；候选可能是合理适配或扩展','人工将核实结果归入现有能力账本，关联正式规则及 U/E/F；不以能力 ID 判违规')
    }
  }
  return @{
    schemaVersion=1;status='candidate-only';mappingVersion=2
    items=@($ledger)
    scan=@{productionJavaFiles=$scanFiles.Count;configurationFiles=$configPaths.Count;configurationKeyParser='properties-only; YAML is location-only';contentIncluded=$false}
    boundary='当前项目内；不读取 SDK、JAR、缓存或邻仓库，不解析传递依赖'
    limitations=@('仅覆盖已登记基础能力名称线索，不是完整能力目录或 Java AST。','配置文件列表是位置候选，不证明归属于某项能力；YAML、不识别的配置格式和自定义入口由 Agent 继续核对。','没有候选不证明未复用；调用点线索不证明调用链或运行生效；不自动生成最终报告或合规结论。')
  }
}
