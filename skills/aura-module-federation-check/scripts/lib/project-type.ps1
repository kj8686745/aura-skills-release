function Get-MfProjectType {
	param(
		[Parameter(Mandatory = $true)][string]$ProjectPath,
		[ValidateSet('Auto', 'Integrated', 'Provider', 'Consumer')][string]$RequestedType = 'Auto'
	)

	if ($RequestedType -ne 'Auto') {
		return [pscustomobject]@{
			Type = $RequestedType
			Evidence = @("由 -ProjectType 显式指定为 $RequestedType")
		}
	}

	$evidence = [System.Collections.Generic.List[string]]::new()
	$baseConfigPath = Join-Path $ProjectPath 'src\config\moduleFederationBaseConfig.ts'
	$exposesPath = Join-Path $ProjectPath 'src\hooks\moduleFederation.ts'
	$registryPath = Join-Path $ProjectPath 'src\utils\moduleFederationRegistry.ts'
	$viteFiles = @(Get-ChildItem -LiteralPath $ProjectPath -File -Filter 'vite.config.*' -ErrorAction SilentlyContinue)
	$viteContent = ($viteFiles | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"

	$hasBaseConfig = (Test-Path -LiteralPath $baseConfigPath -PathType Leaf) -and
		((Get-Content -LiteralPath $baseConfigPath -Raw -Encoding UTF8) -match '\bcurrentRemoteConfig\b')
	$hasStandardExposes = (Test-Path -LiteralPath $exposesPath -PathType Leaf) -and
		((Get-Content -LiteralPath $exposesPath -Raw -Encoding UTF8) -match '\bexposeModules\b')
	$hasRuntimeRegistry = (Test-Path -LiteralPath $registryPath -PathType Leaf) -and
		((Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8) -match '\bgetModuleFederationLoader\b')
	$hasFederationVite = $viteContent -match '@module-federation/vite' -and $viteContent -match '\bfederation\s*\('

	if ($hasBaseConfig) { [void]$evidence.Add('命中 currentRemoteConfig 综合端基础配置') }
	if ($hasStandardExposes) { [void]$evidence.Add('命中 exposeModules 标准聚合入口') }
	if ($hasRuntimeRegistry) { [void]$evidence.Add('命中 getModuleFederationLoader 运行时注册表') }
	if ($hasFederationVite) { [void]$evidence.Add('命中 @module-federation/vite 配置') }

	if ($hasBaseConfig -and $hasStandardExposes -and $hasRuntimeRegistry -and $hasFederationVite) {
		return [pscustomobject]@{ Type = 'Integrated'; Evidence = @($evidence) }
	}

	$allSourceContent = (Get-MfProjectSourceFiles -ProjectPath $ProjectPath |
		ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"
	$hasProviderEvidence = $viteContent -match '(?s)\bexposes\s*:' -or $allSourceContent -match '\bexposeModules\b'
	$hasConsumerEvidence = $viteContent -match '(?s)\bremotes\s*:' -or
		$allSourceContent -match '\b(registerRemotes|loadRemote)\s*\('

	if ($hasProviderEvidence) { [void]$evidence.Add('命中 exposes 对外提供特征') }
	if ($hasConsumerEvidence) { [void]$evidence.Add('命中 remotes/registerRemotes/loadRemote 消费特征') }

	if ($hasProviderEvidence -and -not $hasConsumerEvidence) {
		return [pscustomobject]@{ Type = 'Provider'; Evidence = @($evidence) }
	}
	if ($hasConsumerEvidence -and -not $hasProviderEvidence) {
		return [pscustomobject]@{ Type = 'Consumer'; Evidence = @($evidence) }
	}

	if ($evidence.Count -eq 0) { [void]$evidence.Add('未发现可确认的模块联邦项目特征') }
	elseif ($hasProviderEvidence -and $hasConsumerEvidence) { [void]$evidence.Add('同时命中生产端和消费端特征，无法唯一归类') }

	return [pscustomobject]@{ Type = 'Unknown'; Evidence = @($evidence) }
}
