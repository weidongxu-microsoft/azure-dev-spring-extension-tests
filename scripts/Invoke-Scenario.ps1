[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Scenario,

    [switch] $UpdateExpected
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$scenarioPath = if ([IO.Path]::IsPathRooted($Scenario)) {
    $Scenario
}
else {
    Join-Path $repoRoot $Scenario
}
$scenarioFile = (Resolve-Path $scenarioPath).Path
$scenarioRoot = Split-Path -Parent $scenarioFile
$definition = Get-Content $scenarioFile -Raw | ConvertFrom-Json
$applicationSource = if ($null -ne $definition.application.path) {
    (Resolve-Path (Join-Path $scenarioRoot $definition.application.path)).Path
}
else {
    $null
}
$applicationOverlay = if ($null -ne $definition.application.overlay) {
    (Resolve-Path (Join-Path $scenarioRoot $definition.application.overlay)).Path
}
else {
    $null
}
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
    if ($null -ne $applicationSource) {
        Copy-DirectoryContents -Source $applicationSource -Destination $workingApplication
    }
    else {
        $checkoutRoot = Join-Path $temporaryRoot "source"
        New-Item -ItemType Directory -Path $checkoutRoot -Force | Out-Null
        & git -C $checkoutRoot init --quiet
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to initialize application checkout"
        }
        & git -C $checkoutRoot remote add origin $definition.application.repository
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to configure application source: $($definition.application.repository)"
        }
        & git -C $checkoutRoot fetch --quiet --depth 1 origin $definition.application.commit
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to fetch application commit: $($definition.application.commit)"
        }
        & git -C $checkoutRoot checkout --quiet --detach FETCH_HEAD
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to check out fetched application commit"
        }
        $actualCommit = (& git -C $checkoutRoot rev-parse HEAD).Trim()
        if ($LASTEXITCODE -ne 0 -or $actualCommit -ne $definition.application.commit) {
            throw "Application checkout does not match pinned commit: $actualCommit"
        }
        Remove-Item (Join-Path $checkoutRoot ".git") -Recurse -Force

        $checkoutSource = $checkoutRoot
        if ($null -ne $definition.application.subpath) {
            $subpath = [string] $definition.application.subpath
            if ([string]::IsNullOrWhiteSpace($subpath) -or [IO.Path]::IsPathRooted($subpath)) {
                throw "Application subpath must be a non-empty relative path: $subpath"
            }
            $checkoutSource = [IO.Path]::GetFullPath((Join-Path $checkoutRoot $subpath))
            $checkoutPrefix = $checkoutRoot.TrimEnd(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            ) + [IO.Path]::DirectorySeparatorChar
            if (-not $checkoutSource.StartsWith($checkoutPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Application subpath escapes the pinned repository: $subpath"
            }
            if (-not (Test-Path $checkoutSource -PathType Container)) {
                throw "Application subpath does not exist in the pinned repository: $subpath"
            }
        }
        Copy-DirectoryContents -Source $checkoutSource -Destination $workingApplication
    }
    if ($null -ne $applicationOverlay) {
        Copy-DirectoryContents -Source $applicationOverlay -Destination $workingApplication
    }

    $commandArguments = [Collections.Generic.List[string]]::new()
    $commandArguments.Add("spring")
    $commandArguments.Add("init")
    foreach ($argument in $definition.init.arguments) {
        $commandArguments.Add([string] $argument)
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    if ($null -ne $definition.init.interaction) {
        $startInfo.FileName = "python"
        $startInfo.ArgumentList.Add((Join-Path $PSScriptRoot "Invoke-Interactive.py"))
        $startInfo.ArgumentList.Add("--cwd")
        $startInfo.ArgumentList.Add($workingApplication)
        $startInfo.ArgumentList.Add("--interaction")
        $startInfo.ArgumentList.Add((Resolve-Path (
            Join-Path $scenarioRoot $definition.init.interaction
        )).Path)
        $startInfo.ArgumentList.Add("--")
        $startInfo.ArgumentList.Add("azd")
        foreach ($argument in $commandArguments) {
            $startInfo.ArgumentList.Add($argument)
        }
    }
    else {
        $startInfo.FileName = "azd"
        foreach ($argument in $commandArguments) {
            $startInfo.ArgumentList.Add($argument)
        }
    }
    $startInfo.WorkingDirectory = $workingApplication
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
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
    $reviewedPaths = @($definition.expected.generatedPaths)
    if ($null -ne $definition.expected.reviewedPaths) {
        $reviewedPaths += @($definition.expected.reviewedPaths)
    }
    foreach ($relativePath in $reviewedPaths) {
        Copy-GeneratedPath -RelativePath $relativePath -DestinationRoot $actualRoot
    }

    if ($UpdateExpected) {
        foreach ($relativePath in $reviewedPaths) {
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

    & git -c core.autocrlf=false -c core.safecrlf=false diff --no-index --exit-code --ignore-space-at-eol `
        --src-prefix=expected/ --dst-prefix=actual/ -- $expectedRoot $actualRoot
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
