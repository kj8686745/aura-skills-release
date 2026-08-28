function Invoke-IntegratedChecks {
	param(
		[Parameter(Mandatory = $true)][string]$ProjectPath,
		[string[]]$ComponentPath = @(),
		[string]$ManifestPath = ''
	)

	$findings = [System.Collections.Generic.List[object]]::new()
	$packagePath = Join-Path $ProjectPath 'package.json'
	$packageContent = Get-Content -LiteralPath $packagePath -Raw -Encoding UTF8
	$package = $packageContent | ConvertFrom-Json

	# 检查模板占位身份；规范文档目录不参与业务项目扫描。
	foreach ($file in (Get-MfProjectAuditFiles -ProjectPath $ProjectPath)) {
		$content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
		foreach ($match in [regex]::Matches($content, 'pigx-nexus|pigxNexus')) {
			Add-MfFinding -Findings $findings -RuleId 'MF-ID-001' -Severity 'error' `
				-Message "仍包含模板占位身份：$($match.Value)" `
				-Suggestion '替换为当前业务项目的真实 remoteName、remoteEntryName 或 systemId，并核对用途。' `
				-File (Get-MfRelativePath -ProjectPath $ProjectPath -FilePath $file.FullName) `
				-Line (Get-MfLineNumber -Content $content -Index $match.Index)
		}
	}

	$baseConfigPath = Join-Path $ProjectPath 'src\config\moduleFederationBaseConfig.ts'
	$siteConfigPath = Join-Path $ProjectPath 'src\config\siteConfig.ts'
	$indexPath = Join-Path $ProjectPath 'index.html'
	$postcssPath = Join-Path $ProjectPath 'postcss.config.js'
	$tailwindCssPath = Join-Path $ProjectPath 'src\styles\moduleFederationTailwind.css'
	$baseContent = if (Test-Path -LiteralPath $baseConfigPath) { Get-Content -LiteralPath $baseConfigPath -Raw -Encoding UTF8 } else { '' }
	$siteContent = if (Test-Path -LiteralPath $siteConfigPath) { Get-Content -LiteralPath $siteConfigPath -Raw -Encoding UTF8 } else { '' }
	$indexContent = if (Test-Path -LiteralPath $indexPath) { Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8 } else { '' }
	$postcssContent = if (Test-Path -LiteralPath $postcssPath) { Get-Content -LiteralPath $postcssPath -Raw -Encoding UTF8 } else { '' }
	$tailwindCssContent = if (Test-Path -LiteralPath $tailwindCssPath) { Get-Content -LiteralPath $tailwindCssPath -Raw -Encoding UTF8 } else { '' }

	$remoteNameMatch = Get-MfFirstCapture -Content $baseContent -Pattern 'remoteName\s*:\s*[''"](?<value>[^''"]+)'
	$entryNameMatch = Get-MfFirstCapture -Content $baseContent -Pattern 'remoteEntryName\s*:\s*[''"](?<value>[^''"]+)'
	$systemIdMatch = Get-MfFirstCapture -Content $siteContent -Pattern 'systemId\s*:\s*[''"](?<value>[^''"]+)'
	$identityItems = @(
		@{ Name = 'remoteName'; Match = $remoteNameMatch; File = 'src/config/moduleFederationBaseConfig.ts' },
		@{ Name = 'remoteEntryName'; Match = $entryNameMatch; File = 'src/config/moduleFederationBaseConfig.ts' },
		@{ Name = 'systemId'; Match = $systemIdMatch; File = 'src/config/siteConfig.ts' }
	)
	foreach ($item in $identityItems) {
		if (-not $item.Match) {
			Add-MfFinding -Findings $findings -RuleId 'MF-ID-002' -Severity 'error' -Message "缺少 $($item.Name) 配置。" `
				-Suggestion '按综合端身份职责补齐配置，禁止复用模板占位名。' -File $item.File
		}
	}

	$remoteName = if ($remoteNameMatch) { $remoteNameMatch.Value } else { '' }
	$entryName = if ($entryNameMatch) { $entryNameMatch.Value } else { '' }
	$systemId = if ($systemIdMatch) { $systemIdMatch.Value } else { '' }
	if ($remoteName -and $remoteName -notmatch '^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$') {
		Add-MfFinding -Findings $findings -RuleId 'MF-ID-003' -Severity 'error' -Message "remoteName 不是 kebab-case：$remoteName" `
			-Suggestion '使用类似 aura-order-web 的小写短横线名称。' -File 'src/config/moduleFederationBaseConfig.ts' `
			-Line (Get-MfLineNumber -Content $baseContent -Index $remoteNameMatch.Index)
	}
	if ($entryName -and $entryName -notmatch '^[a-z][a-zA-Z0-9]*$') {
		Add-MfFinding -Findings $findings -RuleId 'MF-ID-003' -Severity 'error' -Message "remoteEntryName 不是 lowerCamelCase：$entryName" `
			-Suggestion '使用类似 auraOrderWeb 的 lowerCamelCase 名称。' -File 'src/config/moduleFederationBaseConfig.ts' `
			-Line (Get-MfLineNumber -Content $baseContent -Index $entryNameMatch.Index)
	}

	if ($remoteName) {
		$expectedScope = "aura-mf-remote-$remoteName"
		foreach ($scopeFile in @(
			@{ Path = 'postcss.config.js'; Content = $postcssContent },
			@{ Path = 'src/styles/moduleFederationTailwind.css'; Content = $tailwindCssContent }
		)) {
			if (-not $scopeFile.Content -or $scopeFile.Content -notmatch [regex]::Escape($expectedScope)) {
				Add-MfFinding -Findings $findings -RuleId 'MF-ID-004' -Severity 'error' `
					-Message "Tailwind scope 未与 remoteName 对齐，期望包含 $expectedScope。" `
					-Suggestion '同步修改 PostCSS REMOTE_SCOPE 和 moduleFederationTailwind.css 根选择器。' -File $scopeFile.Path
			}
		}
	}

	$cacheKeyMatch = Get-MfFirstCapture -Content $indexContent -Pattern 'localStorage\.getItem\(\s*[''"](?<value>[^''"]+):bootstrap-config'
	if ($systemId -and (-not $cacheKeyMatch -or $cacheKeyMatch.Value -ne $systemId)) {
		$actualCacheKey = if ($cacheKeyMatch) { $cacheKeyMatch.Value } else { '未配置' }
		Add-MfFinding -Findings $findings -RuleId 'MF-ID-005' -Severity 'error' `
			-Message "启动缓存键前缀与 systemId 不一致：$actualCacheKey / $systemId" `
			-Suggestion '把 index.html 的 bootstrap-config 缓存键前缀改为 systemId。' -File 'index.html'
	}

	if ($remoteName -and [string]$package.name -ne $remoteName) {
		Add-MfFinding -Findings $findings -RuleId 'MF-ID-006' -Severity 'warning' `
			-Message "package.json.name 与 remoteName 不一致：$($package.name) / $remoteName" `
			-Suggestion '若无明确发布命名约束，建议让包名与 remoteName 保持一致。' -File 'package.json' -Line 2
	}

	$envPath = Join-Path $ProjectPath '.env'
	$envContent = if (Test-Path -LiteralPath $envPath) { Get-Content -LiteralPath $envPath -Raw -Encoding UTF8 } else { '' }
	$publicPathMatch = Get-MfFirstCapture -Content $envContent -Pattern '(?m)^\s*VITE_PUBLIC_PATH\s*=\s*["'']?\s*(?<value>[^\s"'']+)'
	if ($entryName -and $publicPathMatch -and $publicPathMatch.Value -ne '/') {
		$normalizedPublicPath = '/' + $publicPathMatch.Value.Trim('/') + '/'
		$expectedPublicPath = "/$entryName/"
		if ($normalizedPublicPath -ne $expectedPublicPath) {
			Add-MfFinding -Findings $findings -RuleId 'MF-ID-007' -Severity 'warning' `
				-Message "VITE_PUBLIC_PATH 与 remoteEntryName 前缀不一致：$normalizedPublicPath / $expectedPublicPath" `
				-Suggestion '结合 Nginx 实际部署前缀确认并同步配置。' -File '.env' `
				-Line (Get-MfLineNumber -Content $envContent -Index $publicPathMatch.Index)
		}
	}
	Add-MfFinding -Findings $findings -RuleId 'MF-ID-008' -Severity 'manual' `
		-Message '无法从单个仓库确认 remoteName、remoteEntryName、systemId 在部署环境中全局唯一。' `
		-Suggestion '在发布清单、网关和其他综合端中核对名称唯一性。'

	# 依赖和运行环境。
	foreach ($dependency in @('@module-federation/vite', '@module-federation/enhanced')) {
		if (-not (Get-MfPackageVersion -Package $package -Name $dependency)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-DEP-001' -Severity 'error' -Message "缺少依赖 $dependency。" `
				-Suggestion '按当前综合端模板锁定的版本补齐依赖。' -File 'package.json'
		}
	}
	foreach ($dependency in @('@originjs/vite-plugin-federation', 'vite-plugin-top-level-await')) {
		if (Get-MfPackageVersion -Package $package -Name $dependency) {
			Add-MfFinding -Findings $findings -RuleId 'MF-DEP-002' -Severity 'error' -Message "禁止使用旧模块联邦依赖：$dependency" `
				-Suggestion '删除旧依赖和对应 Vite 插件配置。' -File 'package.json'
		}
	}

	$nodeEngine = if ($package.engines) { [string]$package.engines.node } else { '' }
	if ($nodeEngine -match '(?<major>\d+)\.(?<minor>\d+)') {
		if ([int]$Matches.major -lt 20 -or ([int]$Matches.major -eq 20 -and [int]$Matches.minor -lt 12)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-DEP-003' -Severity 'error' -Message "Node 版本约束低于 20.12.0：$nodeEngine" `
				-Suggestion '把 engines.node 调整到 >=20.12.0，并使用匹配运行环境。' -File 'package.json'
		}
	} else {
		Add-MfFinding -Findings $findings -RuleId 'MF-DEP-003' -Severity 'warning' -Message '未声明可识别的 engines.node。' `
			-Suggestion '在 package.json 中明确 Node >=20.12.0。' -File 'package.json'
	}
	$packageManager = [string]$package.packageManager
	if ($packageManager -match '^pnpm@(?<major>\d+)\.(?<minor>\d+)') {
		if ([int]$Matches.major -lt 10 -or ([int]$Matches.major -eq 10 -and [int]$Matches.minor -lt 28)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-DEP-003' -Severity 'error' -Message "pnpm 版本低于 10.28.0：$packageManager" `
				-Suggestion '使用 pnpm 10.28.0 或更高兼容版本。' -File 'package.json'
		}
	} else {
		Add-MfFinding -Findings $findings -RuleId 'MF-DEP-003' -Severity 'warning' -Message '未声明可识别的 packageManager: pnpm@版本。' `
			-Suggestion '在 package.json 中锁定 pnpm 版本。' -File 'package.json'
	}

	$viteFile = Get-ChildItem -LiteralPath $ProjectPath -File -Filter 'vite.config.*' | Select-Object -First 1
	$viteContent = if ($viteFile) { Get-Content -LiteralPath $viteFile.FullName -Raw -Encoding UTF8 } else { '' }
	$viteRelative = if ($viteFile) { Get-MfRelativePath -ProjectPath $ProjectPath -FilePath $viteFile.FullName } else { 'vite.config.*' }
	$viteRequired = @(
		@{ Token = '@module-federation/vite'; Message = '缺少 @module-federation/vite 导入。' },
		@{ Token = 'federation('; Message = '缺少 federation 插件调用。' },
		@{ Token = 'name: currentFederationName'; Message = 'federation.name 未使用 currentFederationName。' },
		@{ Token = "filename: 'remoteEntry.js'"; Message = 'federation.filename 不是 remoteEntry.js。' },
		@{ Token = 'manifest: true'; Message = '未启用 Module Federation manifest。' }
	)
	foreach ($required in $viteRequired) {
		if (-not $viteContent.Contains($required.Token)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-VITE-001' -Severity 'error' -Message $required.Message `
				-Suggestion '恢复综合端模板的 federation 基础配置。' -File $viteRelative
		}
	}

	$singletonPatterns = [ordered]@{
		vue = '(?m)^\s*vue\s*:\s*\{[^\r\n}]*singleton\s*:\s*true'
		'vue-router' = '[''"]vue-router[''"]\s*:\s*\{[^}]*singleton\s*:\s*true'
		'vue-i18n' = '[''"]vue-i18n[''"]\s*:\s*\{[^}]*singleton\s*:\s*true'
		pinia = '(?m)^\s*pinia\s*:\s*\{[^\r\n}]*singleton\s*:\s*true'
		'element-plus' = '[''"]element-plus[''"]\s*:\s*\{[^}]*singleton\s*:\s*true'
	}
	foreach ($item in $singletonPatterns.GetEnumerator()) {
		if ($viteContent -notmatch $item.Value) {
			Add-MfFinding -Findings $findings -RuleId 'MF-VITE-002' -Severity 'error' -Message "$($item.Key) 未配置 shared singleton。" `
				-Suggestion '按综合端模板在 federation.shared 中恢复 singleton。' -File $viteRelative
		}
	}
	$elementVersion = Get-MfPackageVersion -Package $package -Name 'element-plus'
	if ($elementVersion -ne '2.14.3' -or $viteContent -notmatch '[''"]element-plus[''"][^}]*requiredVersion\s*:\s*[''"]\^2\.14\.3[''"]') {
		Add-MfFinding -Findings $findings -RuleId 'MF-VITE-003' -Severity 'error' `
			-Message "Element Plus 版本或 shared requiredVersion 未对齐 2.14.3，当前依赖为 $elementVersion。" `
			-Suggestion '把依赖锁定为 2.14.3，并把 requiredVersion 配为 ^2.14.3。' -File $viteRelative
	}
	if ($viteContent -notmatch 'modulePreload\s*:\s*false' -or $viteContent -notmatch 'skipModuleFederationRemotePreload\s*\(') {
		Add-MfFinding -Findings $findings -RuleId 'MF-VITE-004' -Severity 'error' `
			-Message '未同时禁用 modulePreload 并启用远程预加载跳过插件。' `
			-Suggestion '恢复 build.modulePreload=false 和 skipModuleFederationRemotePreload()。' -File $viteRelative
	}
	if ($viteContent -notmatch 'bundleAllCSS\s*:\s*false') {
		Add-MfFinding -Findings $findings -RuleId 'MF-VITE-005' -Severity 'warning' `
			-Message 'bundleAllCSS 未明确配置为 false。' `
			-Suggestion '保持 expose 级 CSS 拆分，以便消费端按 manifest 精确加载样式。' -File $viteRelative
	}

	# 综合端运行时外壳和标准扩展口。
	$requiredRuntimeFiles = @(
		'src/config/moduleFederationBaseConfig.ts',
		'src/config/viteModuleFederationConfig.ts',
		'src/config/remoteConfig.ts',
		'src/hooks/moduleFederation.ts',
		'src/utils/moduleFederationRegistry.ts',
		'src/utils/moduleFederationRemotes.ts',
		'src/utils/moduleFederationI18n.ts',
		'src/utils/moduleFederationStyles.ts',
		'src/components/ModuleFederationElementProvider/index.vue',
		'src/styles/moduleFederationTailwind.ts',
		'src/styles/moduleFederationTailwind.css'
	)
	foreach ($relativePath in $requiredRuntimeFiles) {
		if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath $relativePath) -PathType Leaf)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-RUNTIME-001' -Severity 'error' -Message "缺少综合端标准文件：$relativePath" `
				-Suggestion '从当前 PIGX 综合端模板恢复文件，并重新核对本项目适配。' -File $relativePath
		}
	}

	$exposesPath = Join-Path $ProjectPath 'src\hooks\moduleFederation.ts'
	$exposesContent = if (Test-Path -LiteralPath $exposesPath) { Get-Content -LiteralPath $exposesPath -Raw -Encoding UTF8 } else { '' }
	foreach ($expose in @('./i18n/langs', './styles/moduleFederationTailwind.ts', './moduleFederation/runtime')) {
		if (-not $exposesContent.Contains($expose)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-RUNTIME-002' -Severity 'error' -Message "缺少标准 expose：$expose" `
				-Suggestion '恢复标准 expose，并确保最终合并到 exposeModules。' -File 'src/hooks/moduleFederation.ts'
		}
	}
	if ($exposesContent -notmatch '\bexposeModules\b' -or $exposesContent -notmatch '\.\.\.styleExposes' -or $exposesContent -notmatch '\.\.\.i18nExposes') {
		Add-MfFinding -Findings $findings -RuleId 'MF-RUNTIME-002' -Severity 'error' -Message '标准 expose 分类未完整合并到 exposeModules。' `
			-Suggestion '恢复 styleExposes、i18nExposes 等分类合并。' -File 'src/hooks/moduleFederation.ts'
	}

	$registryPath = Join-Path $ProjectPath 'src\utils\moduleFederationRegistry.ts'
	$registryContent = if (Test-Path -LiteralPath $registryPath) { Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 } else { '' }
	$hasScopedProviderTree = $registryContent -match '(?s)class\s*:\s*\[[^\]]*[''"]aura-mf-remote-scope[''"][\s\S]*?h\(ModuleFederationElementProvider'
	if (-not $hasScopedProviderTree) {
		Add-MfFinding -Findings $findings -RuleId 'MF-RUNTIME-003' -Severity 'error' `
			-Message '远程路由未保持真实 scope 根节点并在其内部注入 Element Provider。' `
			-Suggestion '保持 aura-mf-remote-scope 为真实 div 根节点，并把 ModuleFederationElementProvider 放在内部。' `
			-File 'src/utils/moduleFederationRegistry.ts'
	}
	foreach ($marker in @('loadError', 'refreshModuleFederationRemote', 'resetRemoteI18nCache', 'resetRemoteStyleCache', 'data-mf-load-error', '重新加载')) {
		if (-not $registryContent.Contains($marker)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-RUNTIME-004' -Severity 'error' -Message "远程加载隔离或重试能力缺少标记：$marker" `
				-Suggestion '恢复当前综合端模板的内容区错误隔离和强制刷新链路。' -File 'src/utils/moduleFederationRegistry.ts'
		}
	}
	$remotesPath = Join-Path $ProjectPath 'src\utils\moduleFederationRemotes.ts'
	$remotesContent = if (Test-Path -LiteralPath $remotesPath) { Get-Content -LiteralPath $remotesPath -Raw -Encoding UTF8 } else { '' }
	foreach ($marker in @('registerRemotes', 'normalizeRemoteEntry', 'getRemoteManifestEntry', 'refreshModuleFederationRemote')) {
		if (-not $remotesContent.Contains($marker)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-RUNTIME-005' -Severity 'error' -Message "运行时远程注册缺少能力：$marker" `
				-Suggestion '恢复远程入口标准化、manifest 推导和刷新能力。' -File 'src/utils/moduleFederationRemotes.ts'
		}
	}

	# 综合端作为提供方时，检查全部 expose 映射和国际化扫描目录。
	$exposePattern = '[''"](?<key>\./[^''"]+)[''"]\s*:\s*[''"](?<path>\./src/[^''"]+)[''"]'
	$exposeRecords = @(
		[regex]::Matches($exposesContent, $exposePattern) | ForEach-Object {
			[pscustomobject]@{
				Key = $_.Groups['key'].Value
				Path = $_.Groups['path'].Value
				Index = $_.Index
			}
		}
	)
	$exposeMap = @{}
	foreach ($group in ($exposeRecords | Group-Object Key)) {
		if ($group.Count -gt 1) {
			Add-MfFinding -Findings $findings -RuleId 'MF-PROVIDER-001' -Severity 'error' -Message "expose key 重复：$($group.Name)" `
				-Suggestion '每个 expose key 只保留一个目标文件。' -File 'src/hooks/moduleFederation.ts'
		}
	}
	foreach ($record in $exposeRecords) {
		$exposeMap[$record.Key] = $record.Path
		$physicalPath = Join-Path $ProjectPath $record.Path.Substring(2).Replace('/', '\')
		if (-not (Test-Path -LiteralPath $physicalPath -PathType Leaf)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-PROVIDER-001' -Severity 'error' `
				-Message "expose 目标文件不存在：$($record.Key) -> $($record.Path)" `
				-Suggestion '修正目标路径或补齐真实文件。' -File 'src/hooks/moduleFederation.ts' `
				-Line (Get-MfLineNumber -Content $exposesContent -Index $record.Index)
		}
		if ($record.Key.StartsWith('./views/')) {
			$expectedPath = './src/' + $record.Key.Substring(2)
			if ($record.Path -ne $expectedPath) {
				Add-MfFinding -Findings $findings -RuleId 'MF-PROVIDER-002' -Severity 'error' `
					-Message "页面 expose key 与真实路径不一致：$($record.Key) -> $($record.Path)" `
					-Suggestion "页面路径应映射为 $expectedPath。" -File 'src/hooks/moduleFederation.ts' `
					-Line (Get-MfLineNumber -Content $exposesContent -Index $record.Index)
			}
		}
	}

	$i18nScanBlock = Get-MfFirstCapture -Content $baseContent -Pattern 'i18nScanDirs\s*:\s*\[(?<value>[^\]]*)\]'
	$i18nScanDirs = @()
	if ($i18nScanBlock) {
		$i18nScanDirs = @([regex]::Matches($i18nScanBlock.Value, '[''"](?<path>src/[^''"]+)[''"]') | ForEach-Object { $_.Groups['path'].Value.TrimEnd('/') })
	}
	foreach ($record in ($exposeRecords | Where-Object { $_.Key.StartsWith('./views/') })) {
		$relativeSourcePath = $record.Path.Substring(2).Replace('/', '\')
		$segments = $relativeSourcePath -split '[\\/]'
		if ($segments.Count -lt 3) { continue }
		$businessRootRelative = ($segments[0..2] -join '\')
		$businessRoot = Join-Path $ProjectPath $businessRootRelative
		$hasBusinessI18n = (Test-Path -LiteralPath $businessRoot -PathType Container) -and
			@(Get-ChildItem -LiteralPath $businessRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '[\\/]i18n[\\/]' }).Count -gt 0
		if (-not $hasBusinessI18n) { continue }

		$normalizedPath = $record.Path.Substring(2).Replace('\', '/')
		$isCovered = @($i18nScanDirs | Where-Object { $normalizedPath.StartsWith($_.TrimEnd('/') + '/', [System.StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
		if (-not $isCovered) {
			Add-MfFinding -Findings $findings -RuleId 'MF-PROVIDER-003' -Severity 'error' `
				-Message "页面存在业务 i18n，但未被 i18nScanDirs 覆盖：$($record.Key)" `
				-Suggestion '把对应 src/views 业务目录加入 currentRemoteConfig.i18nScanDirs。' `
				-File 'src/config/moduleFederationBaseConfig.ts'
		}
	}

	# 综合端作为消费方时，检查运行时远程、环境变量、代理、编译期 remotes 和源码导入。
	$remoteNamesMatch = Get-MfFirstCapture -Content $baseContent -Pattern 'moduleFederationRemoteNames\s*=\s*\[(?<value>[^\]]*)\]'
	$remoteNames = @()
	if ($remoteNamesMatch) {
		$remoteNames = @([regex]::Matches($remoteNamesMatch.Value, '[''"](?<name>[a-zA-Z0-9_-]+)[''"]') | ForEach-Object { $_.Groups['name'].Value })
	}
	$runtimeConfigPath = Join-Path $ProjectPath 'src\config\remoteConfig.ts'
	$runtimeConfigContent = if (Test-Path -LiteralPath $runtimeConfigPath) { Get-Content -LiteralPath $runtimeConfigPath -Raw -Encoding UTF8 } else { '' }
	$runtimeEntryRecords = @(
		[regex]::Matches($runtimeConfigContent, '[''"](?<name>[a-zA-Z0-9_-]+)[''"]\s*:\s*import\.meta\.env\.(?<env>VITE_[A-Z0-9_]+)') | ForEach-Object {
			[pscustomobject]@{ Name = $_.Groups['name'].Value; Env = $_.Groups['env'].Value; Index = $_.Index }
		}
	)
	$runtimeNames = @($runtimeEntryRecords | ForEach-Object Name)
	foreach ($name in $remoteNames) {
		if ($runtimeNames -notcontains $name) {
			Add-MfFinding -Findings $findings -RuleId 'MF-CONSUMER-001' -Severity 'error' -Message "运行时清单缺少远程入口：$name" `
				-Suggestion '在 moduleFederationRemoteEntries 中增加同名 entry。' -File 'src/config/remoteConfig.ts'
		}
	}
	foreach ($name in $runtimeNames) {
		if ($remoteNames -notcontains $name) {
			Add-MfFinding -Findings $findings -RuleId 'MF-CONSUMER-001' -Severity 'error' -Message "运行时 entry 未加入 moduleFederationRemoteNames：$name" `
				-Suggestion '同步模块联邦远程名称常量。' -File 'src/config/moduleFederationBaseConfig.ts'
		}
	}

	$envFiles = @(Get-ChildItem -LiteralPath $ProjectPath -File -Filter '.env*' -ErrorAction SilentlyContinue)
	$envContents = @{}
	$allEnvContent = ''
	foreach ($envFile in $envFiles) {
		$content = Get-Content -LiteralPath $envFile.FullName -Raw -Encoding UTF8
		$envContents[$envFile.Name] = $content
		$allEnvContent += "`n$content"
	}
	foreach ($entry in $runtimeEntryRecords) {
		$envValuePattern = '(?m)^\s*' + [regex]::Escape($entry.Env) + '\s*=\s*[''"]?\s*(?<value>[^\s''"]+)'
		$envValueMatch = [regex]::Match($allEnvContent, $envValuePattern)
		if (-not $envValueMatch.Success) {
			Add-MfFinding -Findings $findings -RuleId 'MF-CONSUMER-002' -Severity 'error' `
				-Message "远程 $($entry.Name) 使用的环境变量未在 .env* 声明：$($entry.Env)" `
				-Suggestion '补充远程入口环境变量，并确保不同环境地址正确。' -File 'src/config/remoteConfig.ts' `
				-Line (Get-MfLineNumber -Content $runtimeConfigContent -Index $entry.Index)
			continue
		}

		$entryValue = $envValueMatch.Groups['value'].Value
		$entryUri = $null
		try { $entryUri = [uri]$entryValue } catch { $entryUri = $null }
		$entryPath = if ($entryUri -and $entryUri.IsAbsoluteUri) { $entryUri.AbsolutePath } else { $entryValue }
		$prefixMatch = [regex]::Match($entryPath, '^/(?<prefix>[^/]+)/')
		if (-not $prefixMatch.Success) { continue }

		$proxyPrefix = '/' + $prefixMatch.Groups['prefix'].Value
		$proxyEnv = $entry.Env -replace '_REMOTE_PATH$', '_PROXY_PATH'
		$devEnvContent = if ($envContents.ContainsKey('.env.development')) { $envContents['.env.development'] } else { '' }
		$proxyEnvDeclared = $devEnvContent -match "(?m)^\s*$([regex]::Escape($proxyEnv))\s*="
		$proxyConfigured = $viteContent.Contains("'$proxyPrefix'") -or $viteContent.Contains(([char]34 + $proxyPrefix + [char]34))
		$proxyUsesEnv = $viteContent.Contains("env.$proxyEnv")
		if (-not $proxyEnvDeclared -or -not $proxyConfigured -or -not $proxyUsesEnv) {
			Add-MfFinding -Findings $findings -RuleId 'MF-CONSUMER-003' -Severity 'error' `
				-Message "远程 $($entry.Name) 的入口、开发代理或代理环境变量未完整对齐：$proxyPrefix / $proxyEnv" `
				-Suggestion '在 .env.development 声明代理目标，并让 Vite 同前缀代理使用该变量。' -File $viteRelative
		}
	}

	$compileConfigPath = Join-Path $ProjectPath 'src\config\viteModuleFederationConfig.ts'
	$compileConfigContent = if (Test-Path -LiteralPath $compileConfigPath) { Get-Content -LiteralPath $compileConfigPath -Raw -Encoding UTF8 } else { '' }
	$compileEntryRecords = @(
		[regex]::Matches($compileConfigContent, '[''"](?<name>[a-zA-Z0-9_-]+)[''"]\s*:\s*env\.(?<env>VITE_[A-Z0-9_]+)') | ForEach-Object {
			[pscustomobject]@{ Name = $_.Groups['name'].Value; Env = $_.Groups['env'].Value }
		}
	)
	$compileNames = @($compileEntryRecords | ForEach-Object Name)
	$remoteImports = [System.Collections.Generic.List[object]]::new()
	$importPatterns = @(
		@{ Kind = 'static'; Pattern = '(?m)^\s*import\s+(?!type\b).*?\s+from\s+[''"](?<module>[a-zA-Z0-9_-]+/[^''"]+)[''"]' },
		@{ Kind = 'dynamic'; Pattern = 'import\(\s*[''"](?<module>[a-zA-Z0-9_-]+/[^''"]+)[''"]\s*\)' }
	)
	foreach ($file in (Get-MfProjectSourceFiles -ProjectPath $ProjectPath)) {
		if ($file.Extension -notin @('.ts', '.tsx', '.js', '.jsx', '.mjs', '.mts', '.vue')) { continue }
		$content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
		foreach ($importPattern in $importPatterns) {
			foreach ($match in [regex]::Matches($content, $importPattern.Pattern)) {
				$moduleId = $match.Groups['module'].Value
				$importRemoteName = ($moduleId -split '/')[0]
				if ($remoteNames -notcontains $importRemoteName) { continue }
				[void]$remoteImports.Add([pscustomobject]@{
					Kind = $importPattern.Kind
					Module = $moduleId
					RemoteName = $importRemoteName
					File = Get-MfRelativePath -ProjectPath $ProjectPath -FilePath $file.FullName
					Line = Get-MfLineNumber -Content $content -Index $match.Index
					Content = $content
				})
			}
		}
	}

	$typeFilesContent = (Get-ChildItem -LiteralPath (Join-Path $ProjectPath 'src') -Recurse -File -Filter '*.d.ts' -ErrorAction SilentlyContinue |
		ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"
	$uniqueRemoteImports = @($remoteImports | Sort-Object Module -Unique)
	foreach ($importRecord in $uniqueRemoteImports) {
		if ($compileNames -notcontains $importRecord.RemoteName) {
			Add-MfFinding -Findings $findings -RuleId 'MF-CONSUMER-004' -Severity 'error' `
				-Message "源码直接导入远程模块，但编译期 remotes 缺少 $($importRecord.RemoteName)：$($importRecord.Module)" `
				-Suggestion '在 getModuleFederationRemoteEntries 中增加该远程；仅动态菜单页面不需要此配置。' `
				-File $importRecord.File -Line $importRecord.Line
		}
		$exactDeclaration = 'declare\s+module\s+[''"]' + [regex]::Escape($importRecord.Module) + '[''"]'
		$wildcardDeclaration = 'declare\s+module\s+[''"]' + [regex]::Escape($importRecord.RemoteName) + '/\*[''"]'
		if ($typeFilesContent -notmatch $exactDeclaration -and $typeFilesContent -notmatch $wildcardDeclaration) {
			Add-MfFinding -Findings $findings -RuleId 'MF-CONSUMER-005' -Severity 'error' `
				-Message "远程模块缺少 TypeScript 声明：$($importRecord.Module)" `
				-Suggestion '增加精确 declare module 或受控的远程通配声明。' -File $importRecord.File -Line $importRecord.Line
		}
	}
	foreach ($importRecord in ($remoteImports | Where-Object { $_.Module -match '\.vue$' -and $_.File -match '\.vue$' })) {
		if ($importRecord.Kind -eq 'static') {
				Add-MfFinding -Findings $findings -RuleId 'MF-CONSUMER-006' -Severity 'error' `
					-Message "远程 Vue 组件禁止静态默认导入：$($importRecord.Module)" `
					-Suggestion '改用 defineAsyncComponent + 动态 import 建立异步渲染边界。' -File $importRecord.File -Line $importRecord.Line
		} elseif ($importRecord.Content -notmatch 'defineAsyncComponent\s*\(') {
				Add-MfFinding -Findings $findings -RuleId 'MF-CONSUMER-006' -Severity 'error' `
					-Message "远程 Vue 组件动态导入未使用 defineAsyncComponent：$($importRecord.Module)" `
					-Suggestion '模板使用的远程组件必须由 defineAsyncComponent 包裹。' -File $importRecord.File -Line $importRecord.Line
		}
	}

	# 检查源码字面量和显式传入的后台菜单 componentPath。
	$menuRecords = [System.Collections.Generic.List[object]]::new()
	foreach ($pathValue in $ComponentPath) {
		if ($pathValue) { [void]$menuRecords.Add([pscustomobject]@{ Path = $pathValue; File = ''; Line = 0 }) }
	}
	foreach ($file in (Get-MfProjectSourceFiles -ProjectPath $ProjectPath)) {
		$content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
		foreach ($match in [regex]::Matches($content, '[''"](?<path>/[a-zA-Z0-9_-]+/[^''"\s]+\?type=moduleFederation(?:&[^''"\s]*)?)[''"]')) {
			[void]$menuRecords.Add([pscustomobject]@{
				Path = $match.Groups['path'].Value
				File = Get-MfRelativePath -ProjectPath $ProjectPath -FilePath $file.FullName
				Line = Get-MfLineNumber -Content $content -Index $match.Index
			})
		}
	}
	$menuRecords = @($menuRecords | Sort-Object Path, File, Line -Unique)
	foreach ($menuRecord in $menuRecords) {
		$pathMatch = [regex]::Match($menuRecord.Path, '^/(?<remote>[a-z][a-z0-9-]*)/(?<expose>views/[^?]+)\?type=moduleFederation(?:&.*)?$')
		if (-not $pathMatch.Success) {
			Add-MfFinding -Findings $findings -RuleId 'MF-MENU-001' -Severity 'error' -Message "模块联邦 componentPath 格式错误：$($menuRecord.Path)" `
				-Suggestion '使用 /remote-name/views/真实路径.vue?type=moduleFederation。' -File $menuRecord.File -Line $menuRecord.Line
			continue
		}
		$menuRemote = $pathMatch.Groups['remote'].Value
		$menuExpose = './' + $pathMatch.Groups['expose'].Value
		if ($menuRemote -eq $remoteName) {
			if (-not $exposeMap.ContainsKey($menuExpose)) {
				Add-MfFinding -Findings $findings -RuleId 'MF-MENU-002' -Severity 'error' `
					-Message "本项目菜单找不到对应 expose：$($menuRecord.Path) -> $menuExpose" `
					-Suggestion '让 componentPath 剩余路径与 pageExposes key 完全一致。' -File $menuRecord.File -Line $menuRecord.Line
			}
		} elseif ($remoteNames -notcontains $menuRemote -or $runtimeNames -notcontains $menuRemote) {
			Add-MfFinding -Findings $findings -RuleId 'MF-MENU-002' -Severity 'error' `
				-Message "外部菜单远程未完整加入运行时清单：$menuRemote" `
				-Suggestion '同步 moduleFederationRemoteNames、运行时 entry 和环境变量。' -File $menuRecord.File -Line $menuRecord.Line
		}
	}
	if ($menuRecords.Count -gt 0) {
		Add-MfFinding -Findings $findings -RuleId 'MF-MENU-003' -Severity 'manual' `
			-Message '已检查 componentPath，但无法从前端仓库确认后台菜单“带参”开关。' `
			-Suggestion '在菜单管理中确认“带参”为“是”。'
	} else {
		Add-MfFinding -Findings $findings -RuleId 'MF-MENU-003' -Severity 'manual' `
			-Message '项目中未发现可检查的后台 componentPath。' `
			-Suggestion '通过 -ComponentPath 传入后台真实组件值，并确认“带参”为“是”。'
	}

	# 只扫描业务源文件，排除模块联邦底层实现中的合法路径处理逻辑。
	foreach ($file in (Get-MfProjectSourceFiles -ProjectPath $ProjectPath)) {
		$relativePath = Get-MfRelativePath -ProjectPath $ProjectPath -FilePath $file.FullName
		if ($relativePath -match '^src/(utils/moduleFederation|hooks/moduleFederation|config/moduleFederation|config/remoteConfig)') { continue }
		$content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
		foreach ($match in [regex]::Matches($content, '(?i)(?:src\s*=\s*[''"]|url\(\s*[''"]?|[''"])/assets/')) {
			Add-MfFinding -Findings $findings -RuleId 'MF-RESOURCE-001' -Severity 'warning' -Message '发现硬编码 /assets/ 资源根路径。' `
				-Suggestion 'import 资源使用 getStaticResourceUrl，public 资源使用 getPublicResourceUrl。' -File $relativePath `
				-Line (Get-MfLineNumber -Content $content -Index $match.Index)
		}
		$assetImport = [regex]::Match($content, '(?m)from\s+[''"]/\@/assets/[^''"]+\.(png|jpe?g|gif|svg|webp|woff2?|ttf|mp4|webm)[''"]')
		if ($assetImport.Success -and $content -notmatch '\bgetStaticResourceUrl\s*\(') {
			Add-MfFinding -Findings $findings -RuleId 'MF-RESOURCE-002' -Severity 'warning' `
				-Message '导入了静态资源，但文件中未调用 getStaticResourceUrl。' `
				-Suggestion '在资源用于 src、背景图或配置项前转换远程地址。' -File $relativePath `
				-Line (Get-MfLineNumber -Content $content -Index $assetImport.Index)
		}
		foreach ($match in [regex]::Matches($content, 'https?://(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?')) {
			Add-MfFinding -Findings $findings -RuleId 'MF-RESOURCE-003' -Severity 'warning' -Message "业务源码硬编码 IP 地址：$($match.Value)" `
				-Suggestion '改用环境变量、请求封装或部署配置。' -File $relativePath `
				-Line (Get-MfLineNumber -Content $content -Index $match.Index)
		}
	}

	$resolvedManifestPath = ''
	if ($ManifestPath) {
		$candidate = if ([System.IO.Path]::IsPathRooted($ManifestPath)) { $ManifestPath } else { Join-Path $ProjectPath $ManifestPath }
		if (Test-Path -LiteralPath $candidate -PathType Leaf) { $resolvedManifestPath = (Resolve-Path -LiteralPath $candidate).Path }
		else {
			Add-MfFinding -Findings $findings -RuleId 'MF-BUILD-002' -Severity 'error' -Message "指定的 manifest 不存在：$ManifestPath" `
				-Suggestion '先执行构建，或传入正确的 mf-manifest.json 路径。' -File $ManifestPath
		}
	} else {
		$defaultManifest = Join-Path $ProjectPath 'dist\mf-manifest.json'
		if (Test-Path -LiteralPath $defaultManifest -PathType Leaf) { $resolvedManifestPath = $defaultManifest }
	}

	$distPath = Join-Path $ProjectPath 'dist'
	if ($resolvedManifestPath -or (Test-Path -LiteralPath $distPath -PathType Container)) {
		$remoteEntryPath = Join-Path $ProjectPath 'dist\remoteEntry.js'
		if (-not (Test-Path -LiteralPath $remoteEntryPath -PathType Leaf)) {
			Add-MfFinding -Findings $findings -RuleId 'MF-BUILD-002' -Severity 'error' -Message '构建目录缺少 dist/remoteEntry.js。' `
				-Suggestion '重新执行综合端生产构建并检查 federation.filename。' -File 'dist/remoteEntry.js'
		}
		if ($resolvedManifestPath) {
			$manifestContent = Get-Content -LiteralPath $resolvedManifestPath -Raw -Encoding UTF8
			foreach ($expose in @('i18n/langs', 'styles/moduleFederationTailwind.ts', 'moduleFederation/runtime')) {
				if (-not $manifestContent.Contains($expose)) {
					Add-MfFinding -Findings $findings -RuleId 'MF-BUILD-002' -Severity 'error' -Message "manifest 缺少标准 expose：$expose" `
						-Suggestion '核对 exposeModules 并重新构建。' -File (Get-MfRelativePath -ProjectPath $ProjectPath -FilePath $resolvedManifestPath)
				}
			}
			foreach ($record in $exposeRecords) {
				$normalizedExpose = $record.Key.TrimStart('./')
				if (-not $manifestContent.Contains($normalizedExpose) -and -not $manifestContent.Contains($record.Key)) {
					Add-MfFinding -Findings $findings -RuleId 'MF-PROVIDER-004' -Severity 'error' `
						-Message "manifest 缺少源码声明的 expose：$($record.Key)" `
						-Suggestion '核对 exposeModules 并重新构建，确认构建产物已更新。' `
						-File (Get-MfRelativePath -ProjectPath $ProjectPath -FilePath $resolvedManifestPath)
				}
			}
		} elseif (-not $ManifestPath) {
			Add-MfFinding -Findings $findings -RuleId 'MF-BUILD-002' -Severity 'error' -Message '构建目录存在但缺少 mf-manifest.json。' `
				-Suggestion '重新执行构建并确认 manifest=true。' -File 'dist/mf-manifest.json'
		}
	} else {
		Add-MfFinding -Findings $findings -RuleId 'MF-BUILD-001' -Severity 'warning' -Message '未发现 dist/mf-manifest.json，尚未验证构建产物。' `
			-Suggestion '在依赖已安装时执行 pnpm build，然后重新运行检查。' -File 'dist/mf-manifest.json'
	}
	Add-MfFinding -Findings $findings -RuleId 'MF-BUILD-003' -Severity 'manual' `
		-Message '静态扫描无法替代独立运行和宿主加载验证。' `
		-Suggestion '按验收清单验证路由、i18n、样式、资源请求、失败隔离和重新加载。'

	return @($findings)
}
