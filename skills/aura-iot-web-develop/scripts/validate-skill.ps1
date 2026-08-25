param(
  [string]$SkillRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$required = @(
  'SKILL.md',
  'README.md',
  'USAGE.md',
  'DESIGN.md',
  'knowledge/README.md',
  'references/project-profile.md',
  'references/css-tailwind-guidelines.md',
  'references/naming-conventions.md',
  'references/component-and-style-guidelines.md',
  'references/template-vs-example-guidelines.md',
  'checklists/pre-development.md',
  'checklists/implementation.md',
  'checklists/validation.md',
  'recipes/hooks-standards.md',
  'recipes/page-patterns.md',
  'recipes/vueuse-decision-guide.md',
  'templates/README.md',
  'templates/api-module.md',
  'templates/pinia-store.md',
  'templates/components/README.md',
  'templates/components/base-display-component.md',
  'templates/components/define-model-component.md',
  'templates/components/slots-container-component.md',
  'templates/components/form-field-component.md',
  'templates/components/dialog-drawer-component.md',
  'templates/components/list-card-component.md',
  'scripts/validate-qiankun.ps1',
  'scripts/scan-tailwind-theme-vars.ps1',
  'scripts/scan-page-complexity.ps1',
  'examples/tailwind-element-plus-theme.vue',
  'examples/components/define-model-input.vue',
  'examples/components/slot-section-card.vue',
  'examples/components/dialog-form-example.vue',
  'examples/components/list-card-example.vue'
)

Write-Output "# validate aura-iot-devWeb-develop"
Write-Output "SkillRoot: $SkillRoot"
Write-Output ""

$failed = $false
foreach ($item in $required) {
  $path = Join-Path $SkillRoot $item
  if (Test-Path $path) {
    Write-Output "[OK] $item"
  } else {
    Write-Output "[MISS] $item"
    $failed = $true
  }
}

Write-Output ""
Write-Output "## forbidden words"
$forbidden = '优先|参考项目|aura-iam|foundation-dev-web/docs|docs/代码约束|从项目|副本|从 .* 迁移|迁移来的|补齐来的|来源|应必须'
$matches = Get-ChildItem $SkillRoot -Recurse -File -Include *.md,*.vue,*.ts,*.ps1 |
  Where-Object {
    $_.FullName -ne $PSCommandPath -and
    $_.FullName -notmatch [regex]::Escape((Join-Path $SkillRoot '.planning'))
  } |
  Select-String -Pattern $forbidden -Encoding UTF8

if ($matches) {
  $matches | ForEach-Object { Write-Output "[FOUND] $($_.Path):$($_.LineNumber): $($_.Line.Trim())" }
  $failed = $true
} else {
  Write-Output '[OK] no forbidden words found'
}

if ($failed) {
  exit 1
}

Write-Output ""
Write-Output '[PASS] skill validation passed'
