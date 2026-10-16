[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Scenario,

    [switch] $UpdateExpected
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$scenarioFile = (Resolve-Path (Join-Path $repoRoot $Scenario)).Path
$scenarioRoot = Split-Path -Parent $scenarioFile
$definition = Get-Content $scenarioFile -Raw | ConvertFrom-Json
$applicationSource = (Resolve-Path (Join-Path $scenarioRoot $definition.application.path)).Path
$expectedRoot = Join-Path $scenarioRoot $definition.expected.path
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) "azd-spring-scenario-$([guid]::NewGuid())"
$workingApplication = Join-Path $temporaryRoot "app"
$actualRoot = Join-Path $temporaryRoot "actual"

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [string] $Destination
    )

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Get-ChildItem $Source -Force | Copy-Item -Destination $Destination -Recurse -Force
}

function Copy-GeneratedPath {
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath,

        [Parameter(Mandatory)]
        [string] $DestinationRoot
    )

    $source = Join-Path $workingApplication $RelativePath
    if (-not (Test-Path $source)) {
        throw "Expected generated path was not created: $RelativePath"
    }

    $destination = Join-Path $DestinationRoot $RelativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item $source $destination -Recurse -Force
}

try {
    Copy-DirectoryContents -Source $applicationSource -Destination $workingApplication

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = "azd"
    $startInfo.WorkingDirectory = $workingApplication
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.ArgumentList.Add("spring")
    $startInfo.ArgumentList.Add("init")
    foreach ($argument in $definition.init.arguments) {
        $startInfo.ArgumentList.Add([string] $argument)
    }
    if ($null -ne $definition.init.environment) {
        foreach ($property in $definition.init.environment.PSObject.Properties) {
            $startInfo.Environment[$property.Name] = [string] $property.Value
        }
    }

    $process = [Diagnostics.Process]::Start($startInfo)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(600000)) {
        $process.Kill($true)
        throw "azd spring init timed out"
    }
    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    Write-Host $stdout
    if ($process.ExitCode -ne $definition.init.expectedExitCode) {
        Write-Error $stderr
        throw "azd spring init exited with $($process.ExitCode)"
    }

    New-Item -ItemType Directory -Path $actualRoot -Force | Out-Null
    foreach ($relativePath in $definition.expected.generatedPaths) {
        Copy-GeneratedPath -RelativePath $relativePath -DestinationRoot $actualRoot
    }

    if ($UpdateExpected) {
        foreach ($relativePath in $definition.expected.generatedPaths) {
            $existing = Join-Path $expectedRoot $relativePath
            if (Test-Path $existing) {
                Remove-Item $existing -Recurse -Force
            }
            $source = Join-Path $actualRoot $relativePath
            $destination = Join-Path $expectedRoot $relativePath
            New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
            Copy-Item $source $destination -Recurse -Force
        }
        Write-Host "Updated expected output for $($definition.name)."
        return
    }

    & git diff --no-index --exit-code --src-prefix=expected/ --dst-prefix=actual/ -- $expectedRoot $actualRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Generated output differs from the reviewed fixture. Inspect the diff or use -UpdateExpected."
    }
    Write-Host "Scenario passed: $($definition.name)"
}
finally {
    if (Test-Path $temporaryRoot) {
        Remove-Item $temporaryRoot -Recurse -Force
    }
}
