[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,
    [string[]]$PathFilter = @(),
    [string[]]$RuleId = @(),
    [string[]]$ApiPath = @(),
    [ValidateRange(1, 200)]
    [int]$MaxItems = 20
)

$ErrorActionPreference = 'Stop'

function Get-Count([object]$Value) {
    if ($null -eq $Value) { return 0 }
    if ($Value -is [System.Array]) { return $Value.Count }
    return 1
}

function Get-Text([object]$Value) {
    if ($null -eq $Value) { return '' }
    return [string]$Value
}

function Test-Match([object]$Item, [string[]]$Values, [string[]]$Properties) {
    if ($Values.Count -eq 0) { return $true }
    foreach ($property in $Properties) {
        $text = Get-Text $Item.$property
        foreach ($value in $Values) {
            if ($text -like "*$value*") { return $true }
        }
    }
    return $false
}

function Test-RuleMatch([object]$Item, [string[]]$Values) {
    if ($Values.Count -eq 0) { return $true }
    $ids = @()
    if ($null -ne $Item.ruleId) { $ids += [string]$Item.ruleId }
    if ($null -ne $Item.ruleIds) { $ids += @($Item.ruleIds | ForEach-Object { [string]$_ }) }
    foreach ($id in $ids) {
        foreach ($value in $Values) {
            if ($id -like "*$value*") { return $true }
        }
    }
    return $false
}

function Convert-CompactItem([object]$Item) {
    $result = [ordered]@{}
    foreach ($property in @('path', 'line', 'method', 'route', 'apiPath', 'ruleId', 'status', 'decision', 'reason', 'signal', 'message')) {
        if ($null -ne $Item.$property -and [string]$Item.$property -ne '') {
            $result[$property] = $Item.$property
        }
    }
    return [pscustomobject]$result
}

$resolved = Resolve-Path -LiteralPath $InputPath
$raw = Get-Content -LiteralPath $resolved.Path -Raw -Encoding UTF8
$document = $raw | ConvertFrom-Json

$collections = @()
foreach ($name in @('routes', 'candidates', 'unresolved', 'issues', 'findings', 'assets', 'files')) {
    $value = $document.$name
    if ($null -ne $value) {
        foreach ($item in @($value)) {
            if ($name -in @('assets', 'files') -and $null -eq $item.path) { continue }
            $collections += [pscustomobject]@{ collection = $name; item = $item }
        }
    }
}

$selected = @(
    $collections |
        Where-Object {
            (Test-Match $_.item $PathFilter @('path', 'source', 'file', 'module')) -and
            (Test-RuleMatch $_.item $RuleId) -and
            (Test-Match $_.item $ApiPath @('path', 'apiPath', 'route'))
        } |
        Select-Object -First $MaxItems |
        ForEach-Object {
            $compact = Convert-CompactItem $_.item
            $compact | Add-Member -NotePropertyName collection -NotePropertyValue $_.collection
            $compact
        }
)

$summary = [ordered]@{
    status = if ($document.status) { $document.status } else { 'ok' }
    mode = if ($document.mode) { $document.mode } else { 'unknown' }
    schemaVersion = if ($document.schemaVersion) { $document.schemaVersion } else { $null }
    input = [IO.Path]::GetFileName($resolved.Path)
    counts = [ordered]@{
        routes = Get-Count $document.routes
        unresolved = Get-Count $document.unresolved
        candidates = Get-Count $document.candidates
        issues = (Get-Count $document.issues) + (Get-Count $document.findings)
        assets = (Get-Count $document.assets) + (Get-Count $document.files)
        capabilitySignals = if ($document.capabilityReuse) { Get-Count $document.capabilityReuse.signals } else { Get-Count $document.capabilityCandidates }
    }
    selectedCount = $selected.Count
    items = $selected
}

$summary | ConvertTo-Json -Depth 8 -Compress
