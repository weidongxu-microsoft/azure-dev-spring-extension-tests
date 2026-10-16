# PostgreSQL managed identity

This scenario initializes a pinned Spring Petclinic application that has no
`azure.yaml`. It explicitly selects the `postgres` profile and PostgreSQL
managed-identity authentication.

The generation regression compares every extension-owned output with
`expected/`. `fixtures/bootstrap.sql` is the reviewed administrator-run schema,
seed-data, and least-privilege grant input used by the live scenario.

The initial live acceptance was completed on a disposable Corp subscription:
managed-identity JDBC authentication, HTTP mutation, exact grant checks,
negative permission checks, restart persistence, and cleanup all passed.
No Azure credentials or live evidence containing subscription details are
stored in this repository.

