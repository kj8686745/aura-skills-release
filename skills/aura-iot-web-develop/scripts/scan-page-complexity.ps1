param(
  [string]$ProjectRoot = (Get-Location).Path,
  [int]$WarnLines = 300,
  [int]$SuggestSplitLines = 500,
  [int]$HighRiskLines = 800
)

$ErrorActionPreference = 'Stop'

function Count-Matches {
  param(
    [string]$Text,
    [string]$Pattern
  )
  return ([regex]::Matches($Text, $Pattern)).Count
}

function Get-BlockLineCount {
  param(
    [string]$Text,
    [string]$StartPattern,
    [string]$EndPattern
  )
  $match = [regex]::Match($Text, "(?s)$StartPattern(.*?)$EndPattern")
  if (-not $match.Success) { return 0 }
  return ($match.Value -split "`r?`n").Count
}

Write-Output '# 页面复杂度扫描'
Write-Output "ProjectRoot: $ProjectRoot"
Write-Output ''

$viewsRoot = Join-Path $ProjectRoot 'src/views'
if (-not (Test-Path $viewsRoot)) {
  Write-Output '[MISS] 缺少 src/views 目录'
  exit 1
}

$files = Get-ChildItem $viewsRoot -Recurse -File -Include *.vue
if ($files.Count -eq 0) {
  Write-Output '[WARN] src/views 下没有 Vue 页面文件'
  exit 0
}

$results = @()
foreach ($file in $files) {
  $text = Get-Content -Raw -Encoding UTF8 $file.FullName
  $lineCount = ($text -split "`r?`n").Count
  $templateLines = Get-BlockLineCount $text '<template[^>]*>' '</template>'
  $scriptLines = Get-BlockLineCount $text '<script[^>]*>' '</script>'
  $styleLines = Get-BlockLineCount $text '<style[^>]*>' '</style>'

  $reactivityCount = Count-Matches $text '\b(ref|reactive|computed|watch)\s*\('
  $messageCount = Count-Matches $text '\bElMessage(Box)?\b'
  $axiosCount = Count-Matches $text '\baxios\b'
  $longClassCount = Count-Matches $text 'class="[^"]{120,}"'
  $dialogCount = Count-Matches $text '<el-dialog\b'
  $drawerCount = Count-Matches $text '<el-drawer\b'
  $tableCount = Count-Matches $text '<el-table\b'
  $vForCount = Count-Matches $text '\bv-for\b'

  $level = 'OK'
  if ($lineCount -ge $HighRiskLines) {
    $level = 'HIGH'
  } elseif ($lineCount -ge $SuggestSplitLines) {
    $level = 'SPLIT'
  } elseif ($lineCount -ge $WarnLines -or $dialogCount + $drawerCount -gt 1 -or $longClassCount -gt 3) {
    $level = 'WARN'
  }

  $results += [PSCustomObject]@{
    Level = $level
    File = Resolve-Path -Relative $file.FullName
    Lines = $lineCount
    Template = $templateLines
    Script = $scriptLines
    Style = $styleLines
    Reactivity = $reactivityCount
    Message = $messageCount
    Axios = $axiosCount
    LongClass = $longClassCount
    Dialog = $dialogCount
    Drawer = $drawerCount
    Table = $tableCount
    VFor = $vForCount
  }
}

$results = $results | Sort-Object @{ Expression = 'Lines'; Descending = $true }, File

foreach ($item in $results) {
  Write-Output "[$($item.Level)] $($item.File) lines=$($item.Lines) template=$($item.Template) script=$($item.Script) style=$($item.Style) ref/reactive/computed/watch=$($item.Reactivity) dialog=$($item.Dialog) drawer=$($item.Drawer) table=$($item.Table) v-for=$($item.VFor) longClass=$($item.LongClass) axios=$($item.Axios) message=$($item.Message)"
}

Write-Output ''
Write-Output '## 拆分建议'
Write-Output "- $WarnLines 行以上：关注页面职责是否过多。"
Write-Output "- $SuggestSplitLines 行以上：建议拆分局部组件、hooks 或 styles。"
Write-Output "- $HighRiskLines 行以上：高风险页面，建议尽快重构。"
Write-Output '- 查询表格页必须复用 `src/hooks/table.ts` 的 `useTable`。'
Write-Output '- 图表逻辑必须复用 `src/hooks/echarts.ts` 的 `useECharts`。'
Write-Output '- 消息弹窗必须复用 `src/hooks/message.ts`。'
Write-Output '- 弹窗、抽屉、复杂查询区、图表卡片按真实需求拆分，不固定创建无意义文件。'
Write-Output '- 页面私有样式较多时拆到当前页面模块 `styles/`，跨页面复用样式写入 `src/styles/page.scss`。'

$problemCount = ($results | Where-Object { $_.Level -ne 'OK' }).Count
Write-Output ''
Write-Output "[DONE] 扫描完成，需关注页面数：$problemCount"
