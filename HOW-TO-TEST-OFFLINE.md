# Test the packed Spring extension

This branch contains a self-contained `azure.springboot` extension bundle and
a non-interactive Petclinic REST generation scenario. It does not require an
extension registry or Azure credentials.

The scenario vendors the pinned Apache-2.0 application source. Maven still
requires either network access or a populated local dependency cache.
Cloning the branch also requires network access unless the repository is
provided through an internal share or removable media.

## Human

### 1. Install prerequisites

- Git
- Azure Developer CLI (`azd`) 1.34.2 or later
- JDK 17 or later
- Maven 3.9 or later
- PowerShell 7 for the commands below

Docker and Azure credentials are not required for this generation-only demo.
The application includes Maven Wrapper, but installing Maven makes the local
Java toolchain explicit and easier to diagnose.

Verify the tools:

```powershell
git --version
azd version
java -version
mvn -version
pwsh --version
```

### 2. Clone this branch

```powershell
git clone --branch offline-extension-demo `
  https://github.com/weidongxu-microsoft/azure-dev-spring-extension-tests.git
Set-Location azure-dev-spring-extension-tests
```

### 3. Confirm a clean extension state

```powershell
azd extension list
```

If `azure.springboot` has an installed version, remove it and check again:

```powershell
azd extension uninstall azure.springboot
azd extension list
```

Continue when `azure.springboot` has no installed version.

### 4. Verify and install the packed extension

```powershell
$bundle = "artifacts/azure-springboot_0.0.1.zip"
$expectedHash = "2b41cd01e98694f7cc22eea3876b676ef61358656b865430980e2826b3801df9"
$actualHash = (Get-FileHash $bundle -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $expectedHash) {
    throw "Extension bundle checksum mismatch"
}
azd extension install $bundle
azd extension list
azd spring init --help
```

The extension list should show `azure.springboot` version `0.0.1` as installed.

### 5. Copy the application to a disposable directory

Do not initialize the checked-in fixture directly because the command writes
deployment files.

```powershell
$source = Resolve-Path "scenarios/petclinic-rest-noninteractive/application"
$demo = Join-Path $env:TEMP "azd-spring-petclinic-rest-demo"
if (Test-Path $demo) {
    throw "Demo directory already exists: $demo"
}
Copy-Item $source $demo -Recurse
Set-Location $demo
```

The source has no `azure.yaml`. Its MySQL and PostgreSQL password settings are
runtime-only placeholders without fallback passwords:

```powershell
Test-Path ./azure.yaml
Select-String -Path ./src/main/resources/application-*.properties `
  -Pattern '^spring\.datasource\.password=\$\{[A-Z0-9_]+\}$'
```

The first command must return `False`; the second must match both datasource
property files.

### 6. Generate the azd project

```powershell
azd spring init --profiles postgres,spring-data-jpa
```

Answer `y` when asked to trust the Maven project and when asked to create the
deployment files. There should be no credential-repair prompt because the
checked-in datasource passwords are already runtime-only placeholders.

The command executes the trusted Maven project for inspection, then generates:

- `azure.yaml`
- `infra/`
- `.azd-spring/`
- `.azd-spring/prepare-database-password.ps1`

It does not ask for credential values or create Azure resources.

### 7. Inspect the generated project

```powershell
Get-Content ./azure.yaml
Get-ChildItem ./infra
Get-ChildItem ./.azd-spring
Select-String -Path ./azure.yaml -Pattern 'preprovision'
Select-String -Path ./infra/database.bicep -Pattern 'Microsoft.DBforPostgreSQL'
```

The generated `azure.yaml` should configure one Container Apps service and a
preprovision password hook. The Bicep should configure PostgreSQL/password,
not managed identity.

### 8. Optionally compile and package locally

If Azure CLI with Bicep is installed:

```powershell
az bicep build --file ./infra/main.bicep --stdout > $null
```

Package the Java application without deploying:

```powershell
mvn -Dmaven.test.skip=true package
```

Alternatively, use `.\mvnw.cmd` on Windows or `./mvnw` on macOS and Linux.

Running `azd up` is outside this demo. It additionally requires Docker, Azure
authentication, a subscription, and permission to create resources.

### 9. Clean up

```powershell
Set-Location ..
Remove-Item $demo -Recurse
azd extension uninstall azure.springboot
```

This branch validates the packed extension against this scenario only. Other
scenario snapshots remain associated with the test repository's default
`azure-dev` revision.

## Agent

1. Set `AZD_CONFIG_DIR` to a new, empty temporary directory.
2. Verify the bundle hash against `artifacts/SHA256SUMS`.
3. Install the local ZIP with `azd extension install ...`.
4. Run `scripts/Invoke-Scenario.ps1` with
   `scenarios/petclinic-rest-noninteractive/scenario.json`.
5. Do not run `azd up` or require Azure credentials.
6. Remove the temporary azd configuration and report whether the reviewed
   generated output matched.

The checked-in application already uses runtime-only datasource password
placeholders, so initialization needs no credential-repair prompt.

## Bundle provenance

The bundle was built from `Azure/azure-dev` commit `f960e452c`:

```powershell
Set-Location cli/azd/extensions/azure.springboot
azd x pack --bundle --rebuild -o <test-repository>/artifacts
```
