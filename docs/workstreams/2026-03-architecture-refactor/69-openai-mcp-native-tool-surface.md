# OpenAI MCP Native Tool Surface

## Purpose

This note records the second OpenAI-native tool declaration slice after
`image_generation`.

The main question was:

- can `llm_dart_openai` expose OpenAI `mcp` as a first-class provider-owned
  built-in tool without widening the shared core or pulling local MCP client
  dependencies into the main package graph?

The answer is now:

- yes, as a declaration-only provider-owned surface that builds on the existing
  Responses continuation subset

## What Landed

`llm_dart_openai` now exposes a first-class OpenAI `mcp` declaration surface:

- `OpenAIMcpTool`
- `OpenAIMcpAllowedTools`
- `OpenAIMcpApprovalPolicy`
- `OpenAIBuiltInTools.mcp(...)`

The declaration surface intentionally stays request-side and provider-owned:

- `serverLabel` is required
- one of `serverUrl` or `connectorId` is required
- allowed-tool filtering stays typed and provider-specific
- approval policy stays typed and provider-specific

## Why This Was Safe To Add

Unlike a brand-new hosted tool family, `mcp` did not start from zero in this
repository.

The OpenAI Responses codec already had provider-owned continuation support for:

- `mcp_approval_request`
- `mcp_call`
- approval-response request replay through `mcp_approval_response`

That means the real gap was not a missing shared continuation model.

The real gap was a missing public declaration entry for the built-in tool
itself.

## What Did Not Land

This slice does **not** add:

- shared `ToolChoice` widening for native-tool forcing
- shared runner ownership for approval-driven continuation
- a local MCP protocol client
- any `mcp_dart` dependency in `llm_dart_openai`
- new shared `TextStreamEvent` families

This stays aligned with the repository-wide architecture rules:

- provider-native tools stay provider-owned
- provider-executed continuation stays provider-owned
- shared core does not absorb one-provider execution semantics

## Dependency Direction Verdict

This addition does not change the dependency policy.

`OpenAI mcp` in Responses is server-side tool declaration, not a local MCP
runtime inside the Dart package.

Therefore:

- `llm_dart_openai` still must not depend on `mcp_dart`
- any future local MCP client integration still belongs in examples or a
  separate integration package

## Event And Projection Verdict

This slice does not justify new shared events.

The current shared event model already covers the meaningful continuation
semantics through:

- `ToolCallEvent`
- `ToolApprovalRequestEvent`
- `ToolResultEvent`
- provider-namespaced `CustomEvent`

That remaining OpenAI-specific output gap has now also been closed through the
provider-owned output/helper layer:

- `mcp_list_tools` now has provider-owned parser, summary, and mapper helpers
- image-generation partial-image stream chunks now also surface through shared
  `CustomEvent` / `CustomUiPart` projection rather than new shared event types

In other words:

- the next OpenAI event work, if any, should still be provider-owned projection
  helpers
- not a wider shared `TextStreamEvent`

## Bottom Line

`mcp` is now a first-class OpenAI provider-owned built-in tool declaration in
`llm_dart_openai`.

This closes the public request-side gap on top of an already-existing
provider-owned continuation subset, while keeping shared abstractions, local MCP
runtime dependencies, and Flutter/session architecture boundaries unchanged.
