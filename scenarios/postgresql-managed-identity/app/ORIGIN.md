# Fixture origin

- Source: <https://github.com/spring-projects/spring-petclinic>
- Revision: `500158f732419217507c7656904b8e6aa1bcc0d6`
- Upstream license: Apache License 2.0 (`LICENSE.txt`)

The fixture adds runtime dependency
`com.azure:azure-identity-extensions:1.2.10`, which is required by the
PostgreSQL JDBC managed-identity scenario. It also adds the
`postgres-managed-identity` Spring profile containing the JDBC authentication
plugin configuration. Deployment files are intentionally absent from the
application input.
