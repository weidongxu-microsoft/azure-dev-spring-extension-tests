# Foundry chat

This scenario initializes a licensed Spring AI Azure OpenAI chat application
that has no `azure.yaml`. Runtime placeholders establish the Foundry endpoint,
credential, and model deployment requirements.

The generation regression compares every extension-owned output with
`expected/`.

Live acceptance was completed on October 20, 2026 with extension commit
`125914566`. In East US 2, the application returned HTTP 200 with a non-empty
`gpt-5.4-nano` response. The Foundry ACL matched only the Container Apps
outbound IP, an external caller received HTTP 403, the API key was not
persisted, and all disposable Azure resources were deleted.

The same deployment was blocked in the Corp subscription because policy
requires local authentication to be disabled. That policy result is expected
for this initial API-key scenario.
