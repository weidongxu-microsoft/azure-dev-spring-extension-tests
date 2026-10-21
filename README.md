# azd Spring extension tests

Regression scenarios for the `azure.springboot` extension.

Each scenario keeps these inputs and expectations separate:

- A trusted Spring application.
- Optional process environment and explicit `azd spring init` arguments.
- The expected generated `azure.yaml`, Bicep, and runtime files.
- Fixtures and assertions for an optional live Azure validation.

The repository depends on a selected `azure-dev` revision for CI. The
`azure-dev` repository does not depend on this suite.

The workflow currently defaults to the Spring extension PR commit. After that
change merges, update the default source to `Azure/azure-dev` and `main`.

Scenario `init.environment` values are applied only to the `azd spring init`
child process. This supports explicit ambient-environment regression cases
without modifying the checked-in application. Interactive scenarios use a
PTY-backed fixture so azd sees a terminal rather than redirected standard
input. A scenario may also pin a public Git repository and exact commit instead
of vendoring its source. Interactive scenarios use the Python standard library
on POSIX; Windows runs require `pywinpty`.

## Run a generation scenario

Install azd and build/register the extension under test, then run:

```powershell
pwsh ./scripts/Invoke-Scenario.ps1 `
  -Scenario scenarios/postgresql-managed-identity/scenario.json
```

Run every scenario with:

```powershell
pwsh ./scripts/Invoke-AllScenarios.ps1
```

Run every non-interactive scenario that generates and compares `azure.yaml`:

```powershell
pwsh ./scripts/Invoke-NonInteractiveGeneration.ps1
```

To deliberately accept reviewed output changes:

```powershell
pwsh ./scripts/Invoke-Scenario.ps1 `
  -Scenario scenarios/postgresql-managed-identity/scenario.json `
  -UpdateExpected
```

Generation tests require no Azure credentials. Live scenarios are separate,
cost-gated, and must verify cleanup.

`external-scenarios/` records reproducible evaluations of public applications
without vendoring their source. Each record pins the upstream repository and
commit, documents required interaction or adaptation, and preserves validation
and cleanup evidence.
