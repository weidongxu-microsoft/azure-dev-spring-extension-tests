# Foundry chat with managed identity

This scenario overlays the licensed Foundry chat fixture with:

```properties
spring.application.name=foundry-chat
spring.ai.azure.openai.endpoint=${AZURE_OPENAI_ENDPOINT}
spring.ai.azure.openai.chat.options.deployment-name=${AZURE_OPENAI_DEPLOYMENT_NAME}
```

The extension has three pieces of evidence:

1. The Maven runtime graph contains
   `org.springframework.ai:spring-ai-starter-model-azure-openai`.
2. Active standard endpoint and deployment-name properties establish the
   Foundry chat binding.
3. `spring.ai.azure.openai.api-key` is absent. Spring AI 1.0.0 therefore builds
   its client with `DefaultAzureCredential`, so the extension selects managed
   identity instead of API-key authentication.

Expected infrastructure disables local authentication, grants the bootstrap
Container App identity `Cognitive Services OpenAI User` on the Foundry account,
and creates no key lookup, Foundry secret, or API-key environment variable.

Live acceptance was completed on October 20, 2026 with extension commit
`c3889b5e00fd6e9f0990bda82754cf0e9d2be41c` in East US 2:

- Corp policy accepted the account with local authentication disabled.
- The role assignment was scoped to the Foundry account.
- The Container App had no Foundry key secret or API-key environment variable.
- The default-deny ACL matched the Container Apps outbound IP.
- `GET /` returned HTTP 200 with a non-empty model response.
- An external user-token request was denied.
- Azure confirmed the disposable resource group was deleted.
