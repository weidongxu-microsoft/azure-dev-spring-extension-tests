# MySQL password authentication

This scenario initializes a pinned Spring Petclinic application that has no
`azure.yaml`. It selects the application-owned `mysql` profile. The datasource
configuration and MySQL driver establish the database requirement; password
authentication is inferred without an authentication override.

The generation regression compares every extension-owned output with
`expected/`. The live contract verifies secret-reference wiring, non-disclosure,
application mutation, restart persistence, and cleanup.

