# Petclinic REST credential repair

This scenario clones the Apache-2.0 Petclinic REST application at a pinned
commit. A PTY interaction confirms replacement of packaged datasource password
defaults. Reviewed output includes both repaired properties files and the
generated PostgreSQL deployment.

## Manual interactive initialization

In Git Bash:

```bash
git clone https://github.com/spring-petclinic/spring-petclinic-rest.git /c/github_lab/spring-petclinic-rest
cd /c/github_lab/spring-petclinic-rest
git checkout --detach afc8fc1d3b8ec8de69414482b3bd70a1da78cb95
AZD_NON_INTERACTIVE=false azd spring init --profiles postgres,spring-data-jpa
```

Answer `y` to these confirmations:

| Prompt | Purpose |
|---|---|
| Trust this project's Maven wrapper and build extensions? | Allow project-controlled Maven inspection. |
| Replace packaged datasource password defaults with runtime-only placeholders? | Repair both MySQL and PostgreSQL properties files, including the inactive profile. |
| Create these deployment files? | Write the generated azd project. |

No database URL or password input is required. `--yes` skips the first and last
confirmations, but never authorizes credential repair. Do not use `--no-prompt`.

Manual initialization was verified on October 18, 2026 with extension commit
`b08c6fa327114106bf0f25fa7824fa46149fec95`. Both repaired properties files and all
generated outputs matched `expected/` (ignoring line endings); Bicep compiled.
This records initialization only, not live deployment. The scenario explicitly
sets `AZD_NON_INTERACTIVE=false` so the PTY-backed repair prompt remains enabled
in agent and CI environments.
