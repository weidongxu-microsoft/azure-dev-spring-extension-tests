# Test the packed Spring extension

This branch contains a self-contained `azure.springboot` extension bundle and
a non-interactive Petclinic REST generation scenario. It does not require an
extension registry or Azure credentials.

The scenario vendors the pinned Apache-2.0 application source. Maven still
requires either network access or a populated local dependency cache.

## Human

From the repository root:

```powershell
$bundle = "artifacts/azure-springboot_0.0.1.zip"
(Get-FileHash $bundle -Algorithm SHA256).Hash.ToLowerInvariant()
azd extension install $bundle --force
pwsh ./scripts/Invoke-Scenario.ps1 `
  -Scenario scenarios/petclinic-rest-noninteractive/scenario.json
```

The expected SHA-256 is:

```text
2b41cd01e98694f7cc22eea3876b676ef61358656b865430980e2826b3801df9
```

Success ends with:

```text
Scenario passed: Petclinic REST non-interactive PostgreSQL
```

The scenario runs `azd spring init` only. It does not provision Azure
resources. Do not use `-UpdateExpected` unless reviewing an intentional
generator change.

This branch validates the packed extension against this scenario only. Other
scenario snapshots remain associated with the test repository's default
`azure-dev` revision.

## Agent

1. Verify the bundle hash against `artifacts/SHA256SUMS`.
2. Install the local ZIP with `azd extension install ... --force`.
3. Run the exact scenario command above without adding interactive flags.
4. Do not run `azd up` or require Azure credentials.
5. Report whether the reviewed generated output matched.

The checked-in application already uses runtime-only datasource password
placeholders, so initialization needs no credential-repair prompt.

## Bundle provenance

The bundle was built from `Azure/azure-dev` commit `f960e452c`:

```powershell
Set-Location cli/azd/extensions/azure.springboot
azd x pack --bundle --rebuild -o <test-repository>/artifacts
```

To remove the local installation:

```powershell
azd extension uninstall azure.springboot --force
```
