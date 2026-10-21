#requires -Version 7.0
[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$DocumentPath,
  [string]$InventoryPath,
  [switch]$Json
)
$ErrorActionPreference='Stop'
$issues=[Collections.Generic.List[object]]::new()
$apiRows=[Collections.Generic.List[object]]::new()
function Issue($Level,$Code,$Line,$Message){$issues.Add(@{level=$Level;code=$Code;line=$Line;message=$Message})}
function Normalize-Cell([string]$Value){$Value.Trim().Trim('`')}
function Path-Key([string]$Value){$Value=[regex]::Replace((Normalize-Cell $Value),'\{(\w+):(?:[^{}]|\{[^{}]*\})+\}','{$1}');return $Value.TrimEnd('/')}
function Get-ParameterRows([string]$Body) {
  $columns=@();$result=[Collections.Generic.List[object]]::new()
  foreach($line in ($Body -split "`n")) {
    if($line -notmatch '^\s*\|'){$columns=@();continue}
    $cells=@(($line.Trim().Trim('|') -split '(?<!\\)\|') | ForEach-Object {Normalize-Cell $_})
    if($cells.Count -and $cells[0] -match '^:?-+:?$'){continue}
    if('参数名' -in $cells -or '参数' -in $cells){$columns=$cells;continue}
    if($columns.Count -ne $cells.Count -or -not $columns.Count){continue}
    $nameAt=[array]::IndexOf($columns,'参数名');if($nameAt -lt 0){$nameAt=[array]::IndexOf($columns,'参数')};$locationAt=[array]::IndexOf($columns,'位置')
    if($locationAt -lt 0){$locationAt=[array]::IndexOf($columns,'参数位置')}
    $result.Add(@{name=$cells[$nameAt];location=$(if($locationAt -ge 0){$cells[$locationAt]}else{''})})
  }
  return $result.ToArray()
}
try {
  $file=(Resolve-Path -LiteralPath $DocumentPath).Path
  $text=[IO.File]::ReadAllText($file).Replace("`r`n","`n")
  $lines=$text -split "`n";$fenced=$false;$headers=@();$fenceChar='';$singleInfo=@{}
  for($i=0;$i -lt $lines.Count;$i++) {
    if($lines[$i] -match '^\s*(`{3,}|~{3,})'){$marker=$Matches[1].Substring(0,1);if(-not $fenced){$fenced=$true;$fenceChar=$marker}elseif($fenceChar -eq $marker){$fenced=$false};continue}
    if($fenced){continue}
    if($lines[$i] -match '\[(填写|待填|名称|类型|规则|语义|field|值|状态|错误码|按需增加)[^\]]*\]'){Issue error placeholder ($i+1) '存在尚未替换的模板占位内容'}
    if($lines[$i] -match '待确认|待核实|未核实'){Issue incomplete unverified_contract ($i+1) '契约内容尚未核实，保留待确认'}
    if($lines[$i] -notmatch '^\s*\|'){$headers=@();continue}
    $cells=@(($lines[$i].Trim().Trim('|') -split '(?<!\\)\|') | ForEach-Object {Normalize-Cell $_})
    if($cells.Count -and $cells[0] -match '^:?-+:?$'){continue}
    if($cells.Count -eq 2 -and $cells[0] -in @('接口编号','网关路径','接口路径')){$singleInfo[$cells[0]]=@{value=$cells[1];line=$i+1}}
    if('接口编号' -in $cells -and '方法' -in $cells -and '路径' -in $cells){$headers=$cells;continue}
    if(-not $headers.Count){continue}
    if($cells.Count -ne $headers.Count){Issue incomplete unparsed_table ($i+1) '接口总览列数不一致，需核对转义或复杂路径';continue}
    $row=@{};for($col=0;$col -lt $headers.Count;$col++){$row[$headers[$col]]=$cells[$col]}
    if($row['方法'] -notmatch '^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|TRACE)$'){Issue incomplete unsupported_protocol ($i+1) '当前脚本只核对明确的 HTTP 方法';continue}
    if($row['路径'] -notmatch '^/'){Issue error invalid_path ($i+1) '总览路径应是明确的访问路径；域名和网关改写另行说明'}
    $apiRows.Add(@{id=$row['接口编号'];method=$row['方法'];path=$row['路径'];line=$i+1})
  }
  if(-not $apiRows.Count -and $singleInfo['接口编号'].value -match '^API-[A-Za-z0-9-]+$'){
    foreach($key in @('网关路径','接口路径')){
      if($singleInfo[$key].value -match '^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|TRACE)\s+(/\S+)$'){$apiRows.Add(@{id=$singleInfo['接口编号'].value;method=$Matches[1];path=$Matches[2];line=$singleInfo[$key].line});break}
    }
  }
  if(-not $apiRows.Count){Issue incomplete missing_overview 0 '未识别到模块总览或等价单接口身份/方法/路径，不能判断覆盖'}
  foreach($group in ($apiRows | Group-Object id)){if($group.Count -gt 1){Issue error duplicate_id $group.Group[0].line "总览接口编号重复：$($group.Name)"}}
  foreach($group in ($apiRows | Group-Object {"$($_.method) $(Path-Key $_.path)"})){if($group.Count -gt 1){Issue incomplete duplicate_route $group.Group[0].line "同一方法路径有多行，需核对媒体/参数/版本等约束：$($group.Name)"}}
  $cards=@([regex]::Matches($text,'(?m)^#{2,3}\s+(?:接口逐项契约[：:]\s*)?(?<id>API-[A-Za-z0-9-]+)[^\n]*'))
  $common=if($cards.Count){$text.Substring(0,$cards[0].Index)}else{$text}
  $sharedStart=$text.Length
  if($cards.Count -and $cards[0].Value -match '^###\s'){
    $tailAt=$cards[-1].Index+$cards[-1].Length
    $nextSection=[regex]::Match($text.Substring($tailAt),'(?m)^##\s+')
    if($nextSection.Success){$sharedStart=$tailAt+$nextSection.Index;$common+="`n"+$text.Substring($sharedStart)}
  }
  $cardMap=@{}
  if(-not $cards.Count -and $apiRows.Count){Issue incomplete unsupported_card_layout 0 '未解析接口卡片结构，需核对是否采用其他有效组织形式'}
  for($index=0;$index -lt $cards.Count;$index++) {
    $card=$cards[$index];$id=$card.Groups['id'].Value;$end=if($index+1 -lt $cards.Count){$cards[$index+1].Index}else{$sharedStart}
    $body=$text.Substring($card.Index,$end-$card.Index);$line=1+[regex]::Matches($text.Substring(0,$card.Index),"`n").Count
    if($cardMap.ContainsKey($id)){Issue error duplicate_card $line "接口明细卡片重复：$id";continue}
    $cardMap[$id]=@{body=$body;line=$line}
    if($apiRows.Count -and $id -notin @($apiRows.id)){Issue error card_not_in_overview $line "接口明细未列入总览：$id"}
  }
  foreach($api in $apiRows) {
    if(-not $cardMap.ContainsKey($api.id)){if($cards.Count){Issue error missing_card $api.line "缺少接口逐项契约：$($api.id)"};continue}
    $card=$cardMap[$api.id];$body=$card.body
    foreach($topic in @('请求','响应','错误|异常','权限|认证','幂等|并发','兼容|变更')) {
      if(($body+"`n"+$common) -notmatch "(?m)^(?:#{1,6}\s+|\s*[-*]\s+\*\*)[^\n]*(?:$topic)"){Issue incomplete unlocated_contract_section $card.line "$($api.id) 未能定位契约主题：$topic；需检查共享章节或其他表达，不直接认定缺内容"}
    }
    if($text -notmatch '(?m)^#{1,6}\s+[^\n]*联调'){Issue error missing_integration_section $card.line '模块文档缺少联调验证章节'}
    $envelopes=[Collections.Generic.List[object]]::new()
    foreach($block in [regex]::Matches(($body+"`n"+$common),'(?ms)^\s*```json\s*\n(?<json>.*?)^\s*```\s*$')) {
      try{
        $obj=$block.Groups['json'].Value | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        if($obj -is [Collections.IDictionary] -and $obj.Contains('code') -and $obj.Contains('msg') -and $obj.Contains('data')){$envelopes.Add($obj)}
      }catch{Issue error invalid_json $card.line "$($api.id) 的 JSON 示例不是可解析的完整 JSON"}
    }
    if(-not $envelopes.Count){Issue error missing_response_example $card.line "$($api.id) 未找到包含 code/msg/data 的完整响应示例"}
    if(-not @($envelopes | Where-Object {$_.code -eq 200}).Count){Issue error missing_success_example $card.line "$($api.id) 缺少成功码 200 的响应示例"}
    if(-not @($envelopes | Where-Object {$_.code -is [ValueType] -and $_.code -ne 200}).Count){Issue error missing_error_example $card.line "$($api.id) 缺少完整错误响应示例"}
    foreach($envelope in $envelopes) {
      if($envelope.code -isnot [int] -and $envelope.code -isnot [long]){Issue error invalid_response_code $card.line "$($api.id) 的 code 不是整数"}
    }
    # HTTP example or request path listing must agree with the overview.
    $requests=@([regex]::Matches(($body+"`n"+$common),'(?m)(?:^\s*|`)(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS|TRACE)\s+(/[^`\s?]+)(?:\?[^`\s]*)?(?:`|\s*$)'))
    if(-not @($requests | Where-Object {$_.Groups[1].Value -eq $api.method -and (Path-Key $_.Groups[2].Value) -eq (Path-Key $api.path)}).Count) {
      Issue incomplete missing_matching_request $card.line "$($api.id) 未找到与总览一致的方法/路径请求行，需核对 curl 或其他示例"
    }
  }
  if($InventoryPath) {
    $inventory=Get-Content -LiteralPath $InventoryPath -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
    if($inventory.schemaVersion -ne 1 -or $inventory.status -eq 'failed'){Issue incomplete invalid_inventory 0 '接口盘点不完整或版本不支持'}
    foreach($item in @($inventory.unresolved | Where-Object {$null -ne $_})){Issue incomplete inventory_unresolved 0 "$($item.path):$($item.line) $($item.reason)"}
    foreach($route in @($inventory.routes | Where-Object {$null -ne $_})) {
      $rows=@($apiRows | Where-Object {$_.method -eq $route.method -and (Path-Key $_.path) -eq (Path-Key $route.path)})
      if($route.method -eq 'ANY'){Issue incomplete wildcard_method 0 "$($route.source):$($route.line) 需核对实际 HTTP 方法";continue}
      if(-not $rows.Count){Issue error undocumented_endpoint 0 "未列入模块文档：$($route.method) $($route.path)；$($route.source):$($route.line)";continue}
      foreach($row in $rows) {
        if(-not $cardMap.ContainsKey($row.id)){continue};$body=$cardMap[$row.id].body+"`n"+$common
        $documentedParams=@(Get-ParameterRows $body)
        foreach($param in @($route.parameters | Where-Object {$_.location -in @('path','query','header','part')})) {
          if(-not @($documentedParams | Where-Object {$_.name -eq $param.wireName -and (-not $_.location -or $_.location -eq $param.location)}).Count){Issue error undocumented_parameter $row.line "$($row.id) 参数表未说明 $($param.location) 参数 $($param.wireName)"}
        }
      }
      if($route.path -match '^/openapi(?:/|$)') {
        if(-not $route.platformApi){Issue error openapi_registration_missing 0 "$($route.method) $($route.path) 缺少直接可见的 @PlatfomApi";continue}
        foreach($key in @('code','version','name','requestPath')) {if(-not $route.platformApi["${key}Expression"]){Issue error openapi_metadata_missing 0 "平台 API 缺少 $key：$($route.path)"}}
        if(-not $route.platformApi.requestPath){Issue incomplete unresolved_platform_path 0 "平台 API requestPath 不是可解析的字面量：$($route.path)"}
        elseif($route.platformApi.requestPath -ne $route.path){Issue error openapi_path_mismatch 0 "平台登记与实际 Controller 映射不同：$($route.path)；实际网关路径仍需独立核对"}
      }
    }
    foreach($row in $apiRows) {
      if(-not @($inventory.routes | Where-Object {$_.method -eq $row.method -and (Path-Key $_.path) -eq (Path-Key $row.path)}).Count){Issue incomplete documented_route_not_found $row.line "盘点中未找到 $($row.method) $($row.path)，需核对外部提供方、网关改写或未解析项"}
    }
  }else{Issue incomplete inventory_not_provided 0 '只核对文档内部结构，未比对代码接口盘点'}
}catch{Issue incomplete input_or_environment 0 $_.Exception.Message}
$errors=@($issues | Where-Object level -eq 'error').Count;$incomplete=@($issues | Where-Object level -eq 'incomplete').Count
$exit=if($errors){1}elseif($incomplete){2}else{0}
$result=@{schemaVersion=1;status=$(if($errors){'failed'}elseif($incomplete){'partial'}else{'passed'});document=$DocumentPath;interfaceCount=$apiRows.Count;summary=@{errors=$errors;incomplete=$incomplete};issues=@($issues.ToArray());limitations=@('检查可解析 HTTP 模块文档、已识别响应示例和代码盘点对照；不验证业务语义、DTO 全部字段、实际鉴权或联调。')}
if($Json){$result | ConvertTo-Json -Depth 10}else{Write-Output "接口文档：$($result.status)，错误=$errors，待核对=$incomplete";$issues | Format-Table level,code,line,message -Wrap}
exit $exit
