$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Errors = [System.Collections.Generic.List[string]]::new()
$RequiredFiles = @(
  'SKILL.md', 'README.md', 'USAGE.md', 'DESIGN.md', 'agents/openai.yaml',
  'references/project-profile.md', 'references/ui-plus-installation.md',
  'references/video-component-guide.md', 'references/video-business-rules.md',
  'templates/README.md', 'templates/fxft-video-basic-page.md',
  'templates/fxft-video-ptz-page.md', 'templates/fxft-video-playback-page.md',
  'templates/fxft-multi-video-basic-page.md', 'templates/fxft-multi-video-draggable-page.md',
  'templates/fxft-multi-video-playback-page.md', 'checklists/pre-development.md',
  'checklists/implementation.md', 'checklists/validation.md',
  'recipes/install-and-resolver.md', 'recipes/video-business-workflow.md',
  'recipes/single-video-integration.md', 'recipes/multi-video-integration.md',
  'recipes/playback-and-state-handling.md'
)

foreach ($RelativePath in $RequiredFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $Root $RelativePath) -PathType Leaf)) {
    $Errors.Add("缺少必要文件：$RelativePath")
  }
}

$AllText = (Get-ChildItem -LiteralPath $Root -Recurse -File -Include '*.md','*.yaml' |
  ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"

foreach ($Keyword in @('FxftWebVideo', 'FxftWebMultiVideo', 'WebVideoSource', 'channel.id', '1.1.2')) {
  if ($AllText -notmatch [regex]::Escape($Keyword)) { $Errors.Add("缺少新版关键字：$Keyword") }
}

foreach ($Forbidden in @(
  ('Fxft' + 'VideoPlayer'),
  ('Fxft' + 'MultiVideoPlayer'),
  'new JessibucaPro', 'playMode=', ':split=', ':videos=', 'uuid:'
)) {
  if ($AllText -match [regex]::Escape($Forbidden)) { $Errors.Add("仍包含旧版契约：$Forbidden") }
}

Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object {
  $Bytes = [System.IO.File]::ReadAllBytes($_.FullName)
  if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
    $Errors.Add("文件包含 UTF-8 BOM：$($_.FullName.Substring($Root.Length + 1))")
  }
}

if ($Errors.Count) {
  Write-Host 'fxft-video 技能校验失败：' -ForegroundColor Red
  $Errors | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
  exit 1
}

Write-Host 'fxft-video 技能校验通过。' -ForegroundColor Green
