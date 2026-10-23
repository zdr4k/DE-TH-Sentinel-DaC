#Requires -Version 7
# Menu tool to manage the table schemas used to validate the KQL of the rules.
# Usage: ./tools/Sentinel-Schemas.ps1

$ErrorActionPreference = 'Stop'

$WorkspaceId   = $env:SENTINEL_WORKSPACE_ID
$ResourceGroup = 'rg-de-lab'
$WorkspaceName = 'log-analyst-de-lab'

$Root       = Split-Path $PSScriptRoot -Parent
$RulesDir   = Join-Path $Root 'rules'
$SchemasDir = Join-Path $Root 'Schemas/tables'
$KqlTool    = Join-Path $PSScriptRoot 'kql_check.js'
$KnownTypes = 'string', 'datetime', 'long', 'int', 'real', 'bool', 'dynamic', 'guid', 'timespan'

function Install-Dependencies {
    $modules = 'powershell-yaml', 'Az.Accounts', 'Az.OperationalInsights'

    # Install everything first, then import. Importing a module before installing the
    # next one can lock a dependency (for example Az.Accounts) that needs an update.
    foreach ($name in $modules) {
        if (-not (Get-Module -ListAvailable -Name $name)) {
            Write-Host "Installing module $name..."
            Install-Module $name -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
        }
    }
    foreach ($name in $modules) { Import-Module $name -ErrorAction Stop }

    if (-not (Test-Path (Join-Path $Root 'node_modules/@kusto/language-service-next'))) {
        if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
            throw 'Node.js is required. Install it from https://nodejs.org and run this script again.'
        }
        Push-Location $Root
        try {
            if (Test-Path 'package-lock.json') {
                Write-Host 'Installing npm packages (npm ci)...'
                npm ci
            }
            else {
                Write-Host 'Installing npm packages (first run, creating package-lock.json)...'
                npm install --save-exact --no-audit --no-fund @kusto/language-service-next@12.4.1
                Write-Host 'Commit package.json and package-lock.json to the repo.'
            }
            if ($LASTEXITCODE -ne 0) { throw 'npm install failed' }
        }
        finally { Pop-Location }
    }
}

function Get-RuleTables {
    $items = foreach ($file in Get-ChildItem $RulesDir -Filter *.yml) {
        $rule = Get-Content $file.FullName -Raw | ConvertFrom-Yaml
        [pscustomobject]@{ id = $file.BaseName; query = [string]$rule.query }
    }
    $json = ConvertTo-Json -InputObject @($items) -Depth 5
    $out = $json | node $KqlTool tables
    if ($LASTEXITCODE -ne 0) { throw 'kql_check.js failed' }
    @(($out | ConvertFrom-Json).tables | Sort-Object -Unique)
}

function Get-MissingTables([string[]]$Tables) {
    @($Tables | Where-Object { -not (Test-Path (Join-Path $SchemasDir "$_.json")) })
}

function Connect-IfNeeded {
    try {
        $null = Get-AzAccessToken -ResourceUrl 'https://api.loganalytics.io' -ErrorAction Stop
    }
    catch {
        Write-Host 'No active Azure session. Signing in...'
        $null = Connect-AzAccount
    }
}

function Resolve-WorkspaceId {
    if ($WorkspaceId) { return $WorkspaceId }
    (Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName).CustomerId
}

function Get-TableSchema([string]$Workspace, [string]$Table) {
    $query = "$Table | getschema | project ColumnName, ColumnType"
    $result = Invoke-AzOperationalInsightsQuery -WorkspaceId $Workspace -Query $query
    $columns = foreach ($row in $result.Results) {
        if ($row.ColumnType -notin $KnownTypes) {
            throw "$Table.$($row.ColumnName): unsupported type '$($row.ColumnType)'"
        }
        [ordered]@{ name = $row.ColumnName; type = $row.ColumnType }
    }
    [ordered]@{ name = $Table; columns = @($columns) }
}

function Save-Schema($Schema) {
    New-Item -ItemType Directory -Force $SchemasDir | Out-Null
    $path = Join-Path $SchemasDir "$($Schema.name).json"
    $json = (ConvertTo-Json $Schema -Depth 5) -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($path, $json + "`n", [System.Text.UTF8Encoding]::new($false))
    $path
}

function Show-Status {
    $tables = Get-RuleTables
    $missing = Get-MissingTables $tables
    foreach ($t in $tables) {
        $state = if ($t -in $missing) { 'MISSING' } else { 'ok' }
        Write-Host ('  {0,-8} {1}' -f $state, $t)
    }
}

function Update-Schemas {
    $tables = Get-RuleTables
    if (-not $tables) { Write-Host '  No tables found in the rules.'; return }

    Connect-IfNeeded
    $workspace = Resolve-WorkspaceId
    $failed = @()
    foreach ($t in $tables) {
        try {
            $path = Save-Schema (Get-TableSchema $workspace $t)
            Write-Host ('  WROTE  {0}' -f (Resolve-Path -Relative $path))
        }
        catch {
            Write-Host "  FAILED $t : $($_.Exception.Message)"
            $failed += $t
        }
    }
    if ($failed) { throw "Could not download: $($failed -join ', ')" }
}

function Add-Table {
    $name = (Read-Host 'Table name').Trim()
    if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
        throw "Invalid table name '$name'"
    }

    Connect-IfNeeded
    $workspace = Resolve-WorkspaceId
    $path = Save-Schema (Get-TableSchema $workspace $name)
    Write-Host ('  WROTE  {0}' -f (Resolve-Path -Relative $path))
}


Install-Dependencies

while ($true) {
    Write-Host ''
    Write-Host 'Sentinel schemas'
    Write-Host '  1) Show status'
    Write-Host '  2) Update schemas (download missing and refresh existing)'
    Write-Host '  3) Add a table by name'
    Write-Host '  0) Exit'
    $choice = Read-Host 'Choose an option'
    try {
        switch ($choice) {
            '1' { Show-Status }
            '2' { Update-Schemas }
            '3' { Add-Table }
            '0' { return }
            default { Write-Host '  Invalid option.' }
        }
    }
    catch {
        Write-Host "  ERROR: $($_.Exception.Message)"
    }

}