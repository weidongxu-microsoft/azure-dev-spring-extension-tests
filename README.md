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
without modifying the checked-in application. Interactive prompt transcripts
will use a separate interaction fixture when those scenarios are added.

## Run a generation scenario

Install azd and build/register the extension under test, then run:

```powershell
pwsh ./scripts/Invoke-Scenario.ps1 `
  -Scenario scenarios/postgresql-managed-identity/scenario.json
```

To deliberately accept reviewed output changes:

```powershell
pwsh ./scripts/Invoke-Scenario.ps1 `
  -Scenario scenarios/postgresql-managed-identity/scenario.json `
  -UpdateExpected
```

Generation tests require no Azure credentials. Live scenarios are separate,
cost-gated, and must verify cleanup.
