param(
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

Write-Output '# Tailwind / Element Plus 主题变量扫描'
Write-Output "ProjectRoot: $ProjectRoot"
Write-Output ''

$srcRoot = Join-Path $ProjectRoot 'src'
if (-not (Test-Path $srcRoot)) {
  Write-Output '[MISS] 缺少 src 目录'
  exit 1
}

$files = Get-ChildItem $srcRoot -Recurse -File -Include *.vue,*.scss,*.css |
  Where-Object {
    $_.FullName -notmatch '\\node_modules\\' -and
    $_.FullName -notmatch '\\dist\\' -and
    $_.FullName -notmatch '\\.planning\\'
  }

$hexPattern = '#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b'
$rgbPattern = 'rgba?\([^\)]*\)'
$tailwindColorPattern = '(?:text|bg|border|from|to|via|ring|divide|placeholder|accent|caret|decoration|outline|shadow)-(?:slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-\d{2,3}'
$allowPattern = 'var\(--(?:el|aura)-|currentColor|transparent|inherit|initial|unset|#[0-9a-fA-F]+;\s*/?\*?\s*允许|tailwindcss'

$issues = @()

foreach ($file in $files) {
  $lines = Get-Content -Encoding UTF8 $file.FullName
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match $allowPattern) { continue }

    $hitTypes = @()
    if ($line -match $hexPattern) { $hitTypes += '硬编码十六进制颜色' }
    if ($line -match $rgbPattern) { $hitTypes += '硬编码 rgb/rgba 颜色' }
    if ($line -match $tailwindColorPattern) { $hitTypes += 'Tailwind 固定色阶' }

    if ($hitTypes.Count -gt 0) {
      $relative = Resolve-Path -Relative $file.FullName
      $issues += [PSCustomObject]@{
        File = $relative
        Line = $i + 1
        Type = ($hitTypes -join '、')
        Content = $line.Trim()
      }
    }
  }
}

if ($issues.Count -eq 0) {
  Write-Output '[PASS] 未发现明显硬编码颜色或 Tailwind 固定色阶'
  exit 0
}

Write-Output "[WARN] 发现 $($issues.Count) 处可能不符合主题变量规范的样式："
Write-Output ''
foreach ($issue in $issues) {
  Write-Output "[FOUND] $($issue.File):$($issue.Line) $($issue.Type)"
  Write-Output "        $($issue.Content)"
}

Write-Output ''
Write-Output '## 建议'
Write-Output '- Tailwind 颜色建议改为任意值变量，例如 `text-[var(--el-color-primary)]`。'
Write-Output '- SCSS 颜色建议使用 `var(--el-...)` 或 `var(--aura-...)`。'
Write-Output '- 背景、边框、阴影也应绑定 Element Plus 主题变量。'
Write-Output '- 本脚本只扫描并提示，不自动修改文件。'
