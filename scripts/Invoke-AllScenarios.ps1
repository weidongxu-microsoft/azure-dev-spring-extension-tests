[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$scenarios = Get-ChildItem (Join-Path $repoRoot "scenarios") -Filter scenario.json -Recurse |
    Sort-Object FullName

foreach ($scenario in $scenarios) {
    & (Join-Path $PSScriptRoot "Invoke-Scenario.ps1") -Scenario $scenario.FullName
}

