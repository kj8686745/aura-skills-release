#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ResultPath,[Parameter(Mandatory)][ValidateSet('Change','Project')][string]$Mode,[switch]$Json)
$ErrorActionPreference='Stop'
$issues=[Collections.Generic.List[object]]::new();$tables=[Collections.Generic.List[object]]::new();$texts=@{}
function Add-Issue($Level,$Code,$Path,$Message){$issues.Add(@{level=$Level;code=$Code;path=$Path;message=$Message})}
function Remove-Examples([string]$Text){[regex]::Replace($Text,'(?ms)^\s*(`{3,}|~{3,})[^\r\n]*\r?\n.*?^\s*\1\s*$|<!--.*?-->',{param($m) [regex]::Replace($m.Value,'[^\r\n]',' ')})}
function Normalize-Cell($Text){([string]$Text).Trim().Replace('`','').Replace('**','')}
function Get-Cells($Line){@(($Line.Trim().Trim('|') -split '(?<!\\)\|') | ForEach-Object {Normalize-Cell $_})}
function Read-Tables($Text,$Path){
  $lines=$Text -split "`r?`n"
  for($i=0;$i -lt $lines.Count-1;$i++){
    if($lines[$i] -notmatch '^\s*\|' -or $lines[$i+1] -notmatch '^\s*\|[\s:|\-]+\|\s*$'){continue}
    $headers=Get-Cells $lines[$i];$rows=[Collections.Generic.List[object]]::new();$j=$i+2
    while($j -lt $lines.Count -and $lines[$j] -match '^\s*\|'){
      $cells=Get-Cells $lines[$j]
      if($cells.Count -eq $headers.Count){$rows.Add(@{cells=$cells;line=$j+1})}else{Add-Issue incomplete table_syntax "${Path}:$($j+1)" '表格列数或转义语法无法解析，需人工复核'}
      $j++
    }
    $tables.Add(@{headers=$headers;rows=@($rows.ToArray());path=$Path;line=$i+1});$i=$j-1
  }
}
function Column($Table,$Pattern){for($i=0;$i -lt $Table.headers.Count;$i++){if($Table.headers[$i] -match $Pattern){return $i}};return -1}
function Select-Table($FirstPattern,$RequiredPattern,[switch]$Optional){
  $found=@($tables | Where-Object { $_.headers[0] -match $FirstPattern -and (Column $_ $RequiredPattern) -ge 0 })
  if(-not $found.Count){if(-not $Optional){Add-Issue incomplete missing_table '' "未找到可解析表格：$FirstPattern / $RequiredPattern"};return $null}
  if($found.Count -gt 1){Add-Issue incomplete ambiguous_table '' "存在多份/多版本表格，需按基线确认：$FirstPattern"}
  return $found[0]
}
function Get-Number($Value,$Path){
  $text=Normalize-Cell $Value
  if($text -notmatch '^\d+$'){Add-Issue error invalid_count $Path '统计必须为非负整数';return $null};return [long]$text
}
function Ids($Text,$Prefix){@([regex]::Matches([string]$Text,"(?<![A-Z0-9-])$Prefix-\d{3,}(?![A-Z0-9-])") | ForEach-Object Value | Sort-Object -Unique)}
$rulePattern='(?<![A-Z0-9-])(?:[A-Z][A-Z0-9]*-){2,}\d{3,}(?![A-Z0-9-])'
try{
  $resolved=(Resolve-Path -LiteralPath $ResultPath).Path
  if($Mode -eq 'Change'){
    if(-not (Test-Path -LiteralPath $resolved -PathType Leaf) -or [IO.Path]::GetExtension($resolved) -ne '.md'){throw 'Change 需要单个 Markdown 报告'}
    $texts[[IO.Path]::GetFileName($resolved)]=Remove-Examples ([IO.File]::ReadAllText($resolved))
    $main=$texts.Values | Select-Object -First 1
    foreach($heading in @('一、基线与范围','二、总体结论','三、对象与规则覆盖','四、发现与证据','五、候选与判定','六、整改与复核')){
      if($main -notmatch ('(?m)^#{1,6}\s+'+[regex]::Escape($heading)+'\s*$')){Add-Issue error missing_section $resolved "缺少单报告章节：$heading"}
    }
    $cards=[regex]::Match($main,'(?ms)^#{1,6}\s+四、发现与证据\s*\r?$\n(?<body>.*?)^#{1,6}\s+五、候选与判定\s*\r?$').Groups['body'].Value
  }else{
    if(-not (Test-Path -LiteralPath $resolved -PathType Container)){throw 'Project 需要六文件目录'}
    $names=@('00-结果包说明.md','01-审查报告.md','02-规则核查矩阵.md','03-证据与执行记录.md','04-整改与复核清单.md','05-扫描候选与判定.md')
    foreach($name in $names){$path=Join-Path $resolved $name;if(Test-Path -LiteralPath $path -PathType Leaf){$texts[$name]=Remove-Examples ([IO.File]::ReadAllText($path))}else{Add-Issue error missing_file $name '缺少结果包文件'}}
    $cards=[string]$texts['01-审查报告.md']
    $extra=@(Get-ChildItem -LiteralPath $resolved -File -Filter '*.md' | Where-Object Name -notin $names)
    foreach($item in $extra){Add-Issue incomplete extra_report $item.Name '结果包根目录有额外 Markdown，需确认职责与统计基线'}
  }
  foreach($path in $texts.Keys){Read-Tables $texts[$path] $path}
  $all=($texts.Values -join "`n").Replace('`','')
  $baseline=Select-Table '^基线$' '^内容$';$executionState=''
  if($baseline){
    $keys=$baseline.rows | ForEach-Object {$_.cells[0]}
    foreach($field in @('项目','仓库|提交|版本证据','规范','技能','执行状态','未覆盖|未验证','时间|开始|结束')){if(($keys -join ' ') -notmatch $field){Add-Issue incomplete baseline_field $baseline.path "基线缺可解析字段：$field"}}
    foreach($row in $baseline.rows){
      if($row.cells[0] -match '执行状态'){
        $states=@([regex]::Matches($row.cells[1],'阻断|部分完成|抽查完成|变更审查完成|静态审查完成|发布准入审查完成') | ForEach-Object Value | Sort-Object -Unique)
        if($states.Count -eq 1){$executionState=$states[0]}else{Add-Issue incomplete execution_state $baseline.path '执行状态缺失或有多种未裁定状态'}
      }
    }
  }
  foreach($name in $texts.Keys){
    $base=if($Mode -eq 'Change'){[IO.Path]::GetDirectoryName($resolved)}else{$resolved}
    foreach($m in [regex]::Matches($texts[$name],'\[[^\]\r\n]+\]\((?<href>[^\s)]+)\)')){
      $href=$m.Groups['href'].Value;$part=$href.Split('#')[0]
      if(-not $part -or $href -match '^(?:[A-Za-z][A-Za-z0-9+.-]*:|//)'){continue}
      $target=[IO.Path]::GetFullPath((Join-Path $base ([Uri]::UnescapeDataString($part))))
      $prefix=$base.TrimEnd([char[]]'\/')+[IO.Path]::DirectorySeparatorChar
      if(-not $target.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){Add-Issue incomplete external_reference $name '引用指向结果目录外，需按被审版本人工核对';continue}
      if(-not (Test-Path -LiteralPath $target)){Add-Issue error missing_link $name "报告引用目标不存在：$href"}
    }
  }
  $evidence=Select-Table '^证据\s*ID$' '类型';$eIds=[Collections.Generic.HashSet[string]]::new()
  if($evidence){foreach($row in $evidence.rows){$id=$row.cells[0];if($id -notmatch '^E-\d{3,}$'){Add-Issue incomplete evidence_format $evidence.path '证据编号无法解析';continue};if(-not $eIds.Add($id)){Add-Issue error duplicate_evidence $evidence.path "证据编号重复：$id"}}}
  $findings=@{};$priorities=@{P0=0;P1=0;P2=0;P3=0}
  foreach($m in [regex]::Matches($cards.Replace('`',''),'(?ms)^#{1,6}[ \t]+(?<id>F-\d{3,})(?:[：: \t][^\r\n]*)?\r?$\n(?<body>.*?)(?=^#{1,6}[ \t]+(?:F-\d{3,}|(?:[一二三四五六七八九十]|\d)[、.])|\z)')){
    $id=$m.Groups['id'].Value;$body=$m.Groups['body'].Value
    if($findings.ContainsKey($id)){Add-Issue error duplicate_finding '' "发现卡片重复：$id";continue}
    $priority=[regex]::Match($body,'(?m)^[^\r\n]*优先级[^\r\n]*\b(P[0-3])\b').Groups[1].Value
    if(-not $priority){Add-Issue error missing_priority '' "$id 未登记可解析优先级"}else{$priorities[$priority]++}
    $ruleIds=@([regex]::Matches($body,$rulePattern) | ForEach-Object Value | Sort-Object -Unique)
    $refs=Ids $body E
    if(-not $ruleIds.Count -or -not $refs.Count){Add-Issue error incomplete_finding '' "$id 缺规则或证据引用"}
    $findings[$id]=@{rules=$ruleIds;evidence=$refs;body=$body}
  }
  $matrix=Select-Table '^规则\s*ID' '^状态$';$ruleStates=@{};$ruleRows=[Collections.Generic.List[object]]::new()
  $units=Select-Table '^单元\s*ID$' '^检查状态$';$unitIds=[Collections.Generic.HashSet[string]]::new()
  if($units){foreach($row in $units.rows){if($row.cells[0] -notmatch '^U-\d{3,}$'){Add-Issue incomplete unit_format $units.path '单元编号无法解析'}elseif(-not $unitIds.Add($row.cells[0])){Add-Issue error duplicate_unit $units.path '单元编号重复'}}}
  if($matrix){
    $statusCol=Column $matrix '^状态$';$evCol=Column $matrix '证据';$fCol=Column $matrix '^F[-/]|判定依据'
    foreach($row in $matrix.rows){
      $ids=@([regex]::Matches($row.cells[0],$rulePattern) | ForEach-Object Value | Sort-Object -Unique)
      if($ids.Count -ne 1){Add-Issue incomplete rule_format $matrix.path '规则行需要能解析的唯一规则编号';continue}
      $id=$ids[0];$state=$row.cells[$statusCol]
      foreach($unit in (Ids ($row.cells -join ' ') U)){if(-not $unitIds.Contains($unit)){Add-Issue error unknown_unit $matrix.path "$id 引用未定义的 $unit"}}
      if($state -notin @('通过','偏差','未证实','不适用')){Add-Issue error invalid_rule_state $matrix.path "$id 状态不合法";continue}
      if(-not $ruleStates.ContainsKey($id)){$ruleStates[$id]=[Collections.Generic.List[string]]::new()};$ruleStates[$id].Add($state)
      $refs=if($evCol -ge 0){Ids $row.cells[$evCol] E}else{@()}
      if(-not $refs.Count){Add-Issue error missing_rule_evidence $matrix.path "$id 缺 E 证据引用"}
      $fs=if($fCol -ge 0){Ids $row.cells[$fCol] F}else{@()}
      if($state -eq '偏差' -and -not $fs.Count){Add-Issue error missing_rule_finding $matrix.path "$id 偏差未关联 F"}
      $ruleRows.Add(@{id=$id;state=$state;findings=$fs;evidence=$refs})
    }
  }
  if(-not $ruleStates.Count){Add-Issue incomplete no_rules '' '未解析到纳入规则，不能验证规则覆盖'}
  $counts=@{通过=0;偏差=0;未证实=0;不适用=0}
  foreach($id in $ruleStates.Keys){$values=$ruleStates[$id];$state=if($values.Contains('偏差')){'偏差'}elseif($values.Contains('未证实')){'未证实'}elseif($values.Contains('通过')){'通过'}else{'不适用'};$counts[$state]++}
  $summary=Select-Table '^规则域$' '^总规则$'
  if($summary -and $matrix -and $ruleRows.Count -eq $matrix.rows.Count){
    $totals=@($summary.rows | Where-Object {$_.cells[0] -in @('合计','总计')})
    if($totals.Count -ne 1){Add-Issue incomplete missing_rule_total $summary.path '摘要需要唯一合计行'}else{
      $expected=@{总规则=$ruleStates.Count;适用=$ruleStates.Count-$counts['不适用'];通过=$counts['通过'];偏差=$counts['偏差'];未证实=$counts['未证实'];不适用=$counts['不适用']}
      foreach($key in $expected.Keys){$col=Column $summary ('^'+$key+'$');if($col -lt 0){Add-Issue incomplete summary_column $summary.path "缺统计列：$key";continue};$value=Get-Number $totals[0].cells[$col] $summary.path;if($null -ne $value -and $value -ne $expected[$key]){Add-Issue error rule_count_mismatch $summary.path "$key 摘要与唯一规则判定不一致"}}
    }
  }
  $priorityTable=Select-Table '^P0$' '^唯一发现数$'
  if($priorityTable -and $priorityTable.rows.Count -ne 1){Add-Issue incomplete priority_rows $priorityTable.path '优先级汇总需要唯一当前基线行'}
  if($priorityTable -and $priorityTable.rows.Count -eq 1){foreach($key in @('P0','P1','P2','P3','唯一发现数')){$col=Column $priorityTable ('^'+$key+'$');if($col -lt 0){Add-Issue incomplete priority_column $priorityTable.path '优先级统计列缺失';continue};$n=Get-Number $priorityTable.rows[0].cells[$col] $priorityTable.path;$expected=if($key -eq '唯一发现数'){$findings.Count}else{$priorities[$key]};if($null -ne $n -and $n -ne $expected){Add-Issue error finding_count_mismatch $priorityTable.path '优先级统计与唯一发现卡不一致'}}}
  $candidateTable=Select-Table '^候选\s*ID$' '^判定$' -Optional;$candidateIds=[Collections.Generic.HashSet[string]]::new();$candidateCounts=@{确认偏差=0;排除=0;待补证=0}
  if($candidateTable){
    $stateCol=Column $candidateTable '^判定$'
    foreach($row in $candidateTable.rows){
      $id=$row.cells[0];if($id -notmatch '^C-\d{3,}$'){Add-Issue incomplete candidate_format $candidateTable.path '候选编号无法解析';continue}
      if(-not $candidateIds.Add($id)){Add-Issue error duplicate_candidate $candidateTable.path "候选编号重复：$id";continue}
      $state=$row.cells[$stateCol];if($state -notin @('确认偏差','排除','待补证')){Add-Issue error invalid_candidate_state $candidateTable.path "$id 缺有效判定";continue};$candidateCounts[$state]++
      $content=$row.cells -join ' ';$refs=Ids $content E;$fs=Ids $content F
      if(-not $refs.Count){Add-Issue error missing_candidate_evidence $candidateTable.path "$id 缺 E"}
      if($state -eq '确认偏差' -and -not $fs.Count){Add-Issue error missing_candidate_finding $candidateTable.path "$id 确认偏差未关联 F"}
      foreach($f in $fs){if(-not $findings.ContainsKey($f)){Add-Issue error unknown_finding $candidateTable.path "$id 引用不存在的 $f"}}
    }
  }
  $candidateSummary=Select-Table '^原始命中数$' '^唯一候选数$'
  if($candidateSummary -and $candidateSummary.rows.Count -ne 1){Add-Issue incomplete candidate_rows $candidateSummary.path '候选汇总需要唯一当前基线行'}
  if($candidateSummary -and $candidateSummary.rows.Count -eq 1){
    $candidateDataComplete=(-not $candidateTable -or $candidateIds.Count -eq $candidateTable.rows.Count)
    foreach($key in @('唯一候选数','确认偏差','排除','待补证')){$col=Column $candidateSummary ('^'+$key+'$');if($col -lt 0){Add-Issue incomplete candidate_count_column $candidateSummary.path '候选统计列缺失';continue};$n=Get-Number $candidateSummary.rows[0].cells[$col] $candidateSummary.path;$expected=if($key -eq '唯一候选数'){$candidateIds.Count}else{$candidateCounts[$key]};if($candidateDataComplete -and $null -ne $n -and $n -ne $expected){Add-Issue error candidate_count_mismatch $candidateSummary.path '候选统计与唯一候选判定不一致'}}
    $raw=Get-Number $candidateSummary.rows[0].cells[0] $candidateSummary.path
    if($null -ne $raw -and ($raw -lt $candidateIds.Count -or ($raw -gt 0 -and -not $candidateIds.Count))){Add-Issue error raw_count_mismatch $candidateSummary.path '原始命中与唯一候选数量不一致'}
  }
  $assets=Select-Table '^对象类别$' '^未检查数量$';$unchecked=0
  if($assets){foreach($row in $assets.rows){$values=@{};foreach($key in @('纳入数量','已检查数量','未检查数量','排除数量')){$col=Column $assets ('^'+$key+'$');if($col -lt 0){Add-Issue incomplete asset_column $assets.path '对象统计列缺失'}else{$values[$key]=Get-Number $row.cells[$col] $assets.path}};if($values.Count -eq 4){if($values['纳入数量'] -ne $values['已检查数量']+$values['未检查数量']){Add-Issue error asset_count_mismatch $assets.path '纳入不等于已检查加未检查'};$unchecked+=$values['未检查数量']}}}
  if($unchecked -gt 0 -and $executionState -in @('变更审查完成','静态审查完成','发布准入审查完成')){Add-Issue error false_completion '' '存在未检查纳入对象，却声明审查完成'}
  foreach($row in $ruleRows){foreach($f in $row.findings){if(-not $findings.ContainsKey($f)){Add-Issue error unknown_finding '' "$($row.id) 引用不存在的 $f"}elseif($row.state -eq '偏差' -and $row.id -notin $findings[$f].rules){Add-Issue error finding_rule_mismatch '' "$($row.id) 与 $f 卡片关联规则不一致"}}}
  foreach($id in $findings.Keys){foreach($rule in $findings[$id].rules){if(-not $ruleStates.ContainsKey($rule)){Add-Issue error unknown_rule '' "$id 引用未纳入矩阵的 $rule"}}}
  foreach($id in (Ids $all E)){if(-not $eIds.Contains($id)){Add-Issue error unknown_evidence '' "引用证据未定义：$id"}}
  $remediation=@($tables | Where-Object {$_.headers[0] -match '^发现\s*ID$' -and (Column $_ '^当前状态$') -ge 0})
  $remediated=[Collections.Generic.HashSet[string]]::new()
  foreach($table in $remediation){foreach($row in $table.rows){$id=$row.cells[0];$null=$remediated.Add($id);if(-not $findings.ContainsKey($id)){Add-Issue error unknown_finding $table.path "整改引用不存在的 $id"};$closeCol=Column $table '^关闭条件$';if($closeCol -lt 0 -or -not $row.cells[$closeCol]){Add-Issue error missing_close_condition $table.path "$id 缺关闭条件"};$statusCol=Column $table '^当前状态$';if($row.cells[$statusCol] -eq '已关闭'){Add-Issue incomplete closure_manual_review $table.path "$id 已关闭，须人工复核新证据与关闭条件，工具不裁定真实关闭"}}}
  foreach($id in $findings.Keys){if(-not $remediated.Contains($id)){Add-Issue error missing_remediation '' "$id 缺整改及复核行"}}
  $errors=@($issues | Where-Object level -eq error).Count;$incomplete=@($issues | Where-Object level -eq incomplete).Count
  $result=[ordered]@{schemaVersion=1;mode=$Mode;status=$(if($errors){'failed'}elseif($incomplete){'partial'}else{'passed'});summary=@{errors=$errors;incomplete=$incomplete;uniqueRules=$ruleStates.Count;findings=$findings.Count;candidates=$candidateIds.Count;evidence=$eIds.Count};issues=@($issues.ToArray());limitations=@('只验证可解析报告结构、ID 引用与统计；不证明规则覆盖完整、证据真实、例外有效、严重性正确或项目合规。','复杂 Markdown、多基线复核表及零项省略表可能需人工核对；原始源码、命令与运行行为未验证。')}
  $code=if($errors){1}elseif($incomplete){2}else{0}
}catch{$result=@{schemaVersion=1;mode=$Mode;status='failed';summary=@{errors=1;incomplete=0};issues=@(@{code='input_or_execution_error';message=$_.Exception.Message})};$code=1}
if($Json){$result | ConvertTo-Json -Depth 12}else{"报告自检：$($result.status)，错误=$($result.summary.errors)，待复核=$($result.summary.incomplete)"}
exit $code
