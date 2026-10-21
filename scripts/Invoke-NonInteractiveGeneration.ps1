[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$scenarioRunner = Join-Path $PSScriptRoot "Invoke-Scenario.ps1"
$scenarios = Get-ChildItem (Join-Path $repoRoot "scenarios") -Filter scenario.json -Recurse |
    ForEach-Object {
        $definition = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $reviewedPaths = @($definition.expected.generatedPaths)
        if ($null -ne $definition.expected.reviewedPaths) {
            $reviewedPaths += @($definition.expected.reviewedPaths)
        }
        if ($null -eq $definition.init.interaction -and $reviewedPaths -contains "azure.yaml") {
            $_
        }
    } |
    Sort-Object FullName

if ($scenarios.Count -eq 0) {
    throw "No non-interactive azure.yaml generation scenarios were found."
}

$failures = [Collections.Generic.List[string]]::new()
$passed = 0
foreach ($scenario in $scenarios) {
    $relativePath = [IO.Path]::GetRelativePath($repoRoot, $scenario.FullName)
    Write-Host "=== $relativePath ==="
    try {
        & $scenarioRunner -Scenario $scenario.FullName
        $passed++
    }
    catch {
        $failures.Add($relativePath)
        Write-Warning $_.Exception.Message
    }
}

Write-Host ""
Write-Host "Generation regression: $passed passed, $($failures.Count) failed."
if ($failures.Count -ne 0) {
    throw "Failed scenarios: $($failures -join ', ')"
}
