# PIGX 业务项目规则扫描脚本

param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectPath,
  [string[]]$Files = @()
)

$ErrorActionPreference = "Stop"
$errors = @()
$warnings = @()
$resolvedProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path

if ($Files.Count -gt 0) {
  $sourceFiles = foreach ($file in $Files) {
    $candidate = if ([System.IO.Path]::IsPathRooted($file)) {
      $file
    } else {
      Join-Path $resolvedProjectPath $file
    }

    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      Get-Item -LiteralPath $candidate
    } else {
      $warnings += "未找到待扫描文件：$file"
    }
  }
} else {
  $sourceRoot = Join-Path $resolvedProjectPath "src"
  if (-not (Test-Path -LiteralPath $sourceRoot)) {
    throw "项目中不存在 src 目录：$resolvedProjectPath"
  }

  $sourceFiles = Get-ChildItem -LiteralPath $sourceRoot -Recurse -File |
    Where-Object { $_.Extension -in @(".ts", ".tsx", ".vue", ".js", ".jsx") }
}

$exactMessageImportPattern = 'import\s*\{\s*useMessage\s*,\s*useMessageBox\s*\}\s*from\s*[''"]/@/hooks/message[''"]\s*;?'
$directElementImportPattern = 'import\s*\{[^}]*\b(ElMessage|ElMessageBox|Message|MessageBox)\b[^}]*\}\s*from\s*[''"]element-plus[''"]'
$oldMessagePattern = 'const\s*\{\s*message\s*,\s*messageBox\s*\}\s*=\s*useMessage\s*\('

function Get-CommentText {
  param([string]$Source)

  return ([regex]::Matches($Source, '(?s)<!--.*?-->|/\*.*?\*/|//[^\r\n]*') | ForEach-Object { $_.Value }) -join "`n"
}

function Test-CommentAnchor {
  param(
    [string]$CommentText,
    [string[]]$Keywords
  )

  return $Keywords | Where-Object { $CommentText -match $_ } | Select-Object -First 1
}

function Test-CommentBefore {
  param(
    [string]$Source,
    [string]$Pattern,
    [int]$Lookback = 240
  )

  $match = [regex]::Match($Source, $Pattern)
  if (-not $match.Success) {
    return $true
  }

  $start = [Math]::Max(0, $match.Index - $Lookback)
  $context = $Source.Substring($start, $match.Index - $start)
  return $context -match '(?s)(<!--.*?-->|/\*.*?\*/|//[^\r\n]*)\s*$'
}

foreach ($file in $sourceFiles) {
  if (-not $file) {
    continue
  }

  $relativePath = $file.FullName.Substring($resolvedProjectPath.Length + 1).Replace("\", "/")
  $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  $commentText = Get-CommentText -Source $content

  # 统一消息 Hook 本身是唯一允许直接封装 Element Plus 消息 API 的边界。
  $isMessageHook = $relativePath -eq "src/hooks/message.ts"

  if (-not $isMessageHook -and $content -match $directElementImportPattern) {
    $errors += "$relativePath：禁止直接从 element-plus 导入 Message/MessageBox"
  }

  if ($content -match $oldMessagePattern) {
    $errors += "$relativePath：禁止从 useMessage() 解构 message/messageBox"
  }

  $usesMessageHook = $content -match "\buseMessage(Box)?\s*\("
  if ($usesMessageHook -and -not $isMessageHook -and $content -notmatch $exactMessageImportPattern) {
    $errors += "$relativePath：使用消息 API 时必须显式导入 useMessage 和 useMessageBox"
  }

  if ($content -match 'from\s+[''"]@/') {
    $errors += "$relativePath：项目内部路径必须使用 /@/，不能使用 @/"
  }

  if ($content -match 'import\s+axios\s+from\s+[''"]axios[''"]' -or $content -match '\baxios\.create\s*\(') {
    $errors += "$relativePath：业务请求必须走 /@/utils/request"
  }

  # 注释扫描为告警：只识别页面结构和高风险语法，避免用注释数量制造噪音。
  $isVueView = $file.Extension -eq '.vue' -and $relativePath -match '^src/views/.+\.vue$'
  if ($isVueView -and $content -notmatch '(?s)\A\s*<!--\s*\*?\s*@description\b') {
    $warnings += "$($relativePath)：页面缺少带 @description 的中文文件头说明"
  }

  $isCardList = $isVueView -and $content -match '<el-card\b' -and ($content -match '<el-form\b' -or $content -match '<pagination\b')
  if ($isCardList) {
    $anchorRules = @(
      @{ Name = '查询/筛选区'; Keywords = @('查询区', '筛选区') },
      @{ Name = '工具栏'; Keywords = @('工具栏') },
      @{ Name = '卡片列表'; Keywords = @('卡片列表', '列表区') },
      @{ Name = '空态'; Keywords = @('空态', '空状态') },
      @{ Name = '分页'; Keywords = @('分页') }
    )
    foreach ($rule in $anchorRules) {
      if (-not (Test-CommentAnchor -CommentText $commentText -Keywords $rule.Keywords)) {
        $warnings += "$($relativePath)：查询卡片页缺少【$($rule.Name)】注释锚点；没有对应区块时请在交付中说明"
      }
    }
  }

  if ($isVueView -and $content -match 'v-(if|for)\s*=\s*"[^"]*(?:&&|\|\|)[^"]*"' -and -not (Test-CommentBefore -Source $content -Pattern 'v-(if|for)\s*=\s*"[^"]*(?:&&|\|\|)[^"]*"')) {
    $warnings += "$($relativePath)：组合条件渲染附近缺少说明业务触发场景的注释"
  }

  if ($isVueView -and $content -match '@[\w-]+\.stop\b' -and -not (Test-CommentBefore -Source $content -Pattern '@[\w-]+\.stop\b')) {
    $warnings += "$($relativePath)：事件阻断附近缺少说明交互边界的注释"
  }

  if ($file.Extension -eq '.vue' -and $content -match ':deep\(' -and -not (Test-CommentBefore -Source $content -Pattern ':deep\(')) {
    $warnings += "$($relativePath)：:deep() 覆盖附近缺少说明第三方样式覆盖原因的注释"
  }
}

foreach ($warning in $warnings) {
  Write-Host "! $warning" -ForegroundColor Yellow
}

foreach ($errorItem in $errors) {
  Write-Host "✗ $errorItem" -ForegroundColor Red
}

if ($errors.Count -gt 0) {
  Write-Host "扫描失败：共 $($errors.Count) 项错误" -ForegroundColor Red
  exit 1
}

Write-Host "✓ 项目规则扫描通过，共检查 $($sourceFiles.Count) 个文件" -ForegroundColor Green
