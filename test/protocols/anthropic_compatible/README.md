# Anthropic-compatible Protocol Conformance Suite

This directory contains protocol-level regression tests (conformance) for the
**Anthropic Messages API wire format**.

Goals:

- Provide guardrails for fearless refactors in `llm_dart_anthropic_compatible`
- Allow providers that reuse the protocol (e.g. MiniMax) to share the same
  assertions, avoiding duplicated test logic

## How to reuse for a new provider

Typical workflow:

1. Create a thin wrapper test under the provider folder
   (e.g. `test/providers/<providerId>/`).
2. Call `register*ConformanceTests(...)` from this directory, passing:
   - an `AnthropicConfig` (pay attention to `providerId` and option namespace)
   - a `createChat` factory (returns `ChatCapability` or `ChatStreamPartsCapability`)
   - the expected `providerMetadata` namespace key (usually equals `providerId`)

Examples:

- MiniMax streaming: `test/providers/minimax/minimax_streaming_conformance_test.dart`
- MiniMax tool_use streaming: `test/providers/minimax/minimax_tool_use_streaming_conformance_test.dart`
- MiniMax tool loop persistence: `test/providers/minimax/minimax_tool_loop_persistence_conformance_test.dart`

## Coverage (growing)

- streaming parts: thinking/text ordering, tool_use parts, provider-native web_search filtering
- request builder: web_search injection, ToolNameMapping collision avoidance, cache_control behavior
- tool loop: assistantMessage replay (thinking/tool_use/tool_result)
- MCP connector: mcp_tool_use/mcp_tool_result parsing and exposure
- redacted thinking: placeholder output + replay safety
  - replay safety via `assistantMessage`
