# Dentalcare backend

Reference-only live evaluation of
[`anthonygrr/dentalcare-backend`](https://github.com/anthonygrr/dentalcare-backend).
The upstream source is not copied because no license was detected.

## Source

```text
Repository: https://github.com/anthonygrr/dentalcare-backend.git
Commit:     0bd88ccc4a19ed532101f545475dfae0dbecaa74
```

Clone and pin the source:

```powershell
git clone https://github.com/anthonygrr/dentalcare-backend.git
Set-Location dentalcare-backend
git checkout 0bd88ccc4a19ed532101f545475dfae0dbecaa74
```

## Generate the azd project

Run interactively:

```powershell
$env:AZD_NON_INTERACTIVE = "false"
azd spring init --yes
```

At `Enter deployment value for DB_URL`, enter:

```text
jdbc:postgresql://localhost:5432/dentalcare
```

The value is used to infer PostgreSQL and database name `dentalcare`. Generated
runtime configuration replaces the local host and credentials with Azure
bindings.

## Add the application JWT secret

The application requires `JWT_SECRET`, which is outside the extension's current
recognized binding contract. Apply the focused patch after generation:

```powershell
git apply <test-repo>\external-scenarios\dentalcare-backend\jwt-secret.patch
az bicep format --file infra\main.bicep
az bicep format --file infra\application.bicep
```

Create an azd environment, then store a random signing key only in local azd
state:

```powershell
azd env new <environment> --subscription <subscription-id> --location westus3 --no-prompt

$bytes = [byte[]]::new(48)
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$secret = [Convert]::ToBase64String($bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
azd env set JWT_SECRET $secret

azd up --no-prompt
```

The patch declares the value as a secure Bicep parameter, stores it as a
Container Apps secret, and exposes only a `secretRef` as `JWT_SECRET`.

## Validated behavior

Validated October 17, 2026 against the referenced commit and Spring extension
commit `deb6e745faef42dc2ffb4905affe2d6f1ae4c3a3`.

- Generated one Container App and one PostgreSQL `dentalcare` database.
- Deployed successfully in `westus3`.
- `/v3/api-docs` returned HTTP 200.
- Seeded-user login returned a JWT.
- `POST /patients` created a unique patient.
- `GET /patients/{id}` returned the persisted PostgreSQL record.
- `azd down --force --purge --no-prompt` completed.
- Azure confirmed the resource group no longer existed.

The live environment was `dental-e2e-5c207f`; it has been deleted.
