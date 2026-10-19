# Petclinic REST non-interactive PostgreSQL

This scenario vendors Spring Petclinic REST at
`afc8fc1d3b8ec8de69414482b3bd70a1da78cb95` under its Apache-2.0 license.
The MySQL and PostgreSQL properties use runtime-only password placeholders
without fallback credentials.

`azd spring init` therefore runs with `--yes --no-prompt`; no PTY or source
repair is required. The scenario reviews the generated `azure.yaml`, Bicep,
runtime assets, and unchanged datasource property files.

For a manual developer walkthrough, including prerequisites and direct
`azd spring init` commands, see
[`../../HOW-TO-TEST-OFFLINE.md`](../../HOW-TO-TEST-OFFLINE.md).

The automated snapshot check remains available for agents and regression
testing. Use a clean extension state or an empty temporary `AZD_CONFIG_DIR`:

```powershell
azd extension install artifacts/azure-springboot_0.0.1.zip
pwsh ./scripts/Invoke-Scenario.ps1 `
  -Scenario scenarios/petclinic-rest-noninteractive/scenario.json
```

This is generation-only validation and creates no Azure resources.
