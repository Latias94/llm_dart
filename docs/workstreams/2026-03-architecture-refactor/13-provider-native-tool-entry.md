# Provider-Native Tool Entry

## Goal

This note freezes where provider-native tools should be declared in the new
architecture.

The common core request path already supports shared function tools. The
remaining question is how provider-native tools should enter the system without
reintroducing a giant provider-shaped core API.

## Frozen Conclusion

Provider-native tool declarations belong in provider packages, not in
`llm_dart_core`.

That means:

- common function tools use `GenerateTextRequest.tools`
- provider-native tools use typed provider settings or invocation options
- provider-native tool classes live in the owning provider package

## Current Entry Model

Phase-1 native tool entry now follows this rule:

- model defaults live in provider model settings
- per-call overrides live in provider invocation options
- invocation options override model defaults instead of merging implicitly

That is the same precedence already used by other provider-specific knobs such as
safety settings.

## Google

The current minimal provider-native tool surface is:

- `GoogleSearchTool`
- `GoogleCodeExecutionTool`

These tools live in `llm_dart_google` and are passed through:

- `GoogleChatModelSettings.tools`
- `GoogleGenerateTextOptions.tools`

Current behavior:

- Google native tools are encoded into Google-native `tools` payloads
- Gemini 3 can combine Google native tools and common function-tool
  declarations when the provider-owned
  `includeServerSideToolInvocations` contract is enabled
- outside that model-gated path, common function-tool declarations are ignored
  with warnings when native Google tools are active
- outside that model-gated path, common `toolChoice` is also ignored with
  warnings when native Google tools are active

This remains provider-owned because Google's mixed-tool circulation contract is
model-gated and still not a good basis for widening the shared core.

## Anthropic

The current minimal provider-native tool surface is:

- `AnthropicWebSearchTool20250305`
- `AnthropicCodeExecutionTool20260120`
- `AnthropicToolSearchRegexTool20251119`
- `AnthropicToolSearchBm25Tool20251119`

These tools live in `llm_dart_anthropic` and are passed through:

- `AnthropicChatModelSettings.tools`
- `AnthropicGenerateTextOptions.tools`
- `AnthropicChatModelSettings.deferredToolNames`
- `AnthropicGenerateTextOptions.deferredToolNames`

Current behavior:

- Anthropic native tools are encoded into the same request-side `tools` array as
  common function tools
- provider-owned `deferredToolNames` now also let Anthropic mark shared
  function-tool declarations with `defer_loading` without widening the common
  `FunctionToolDefinition`
- common `AutoToolChoice` and `RequiredToolChoice` apply across the full tool
  set
- `SpecificToolChoice` still only validates against common function-tool
  declarations in phase 1

This is acceptable for now because Anthropic's wire format supports mixing
custom tools and provider-defined tools much more naturally than Google.

## Why This Boundary Matters

Without this rule, every new provider-native tool family would try to widen the
common core request model.

That would recreate the old problem:

- the core surface would start reflecting provider catalogs
- versioned provider tool IDs would leak into shared APIs
- Flutter integration would become provider-shaped again

By keeping provider-native tools in provider packages:

- the common core stays stable
- provider-native evolution stays local
- the library can still offer a unified request path for the real cross-provider
  overlap

## Immediate Follow-Up

This freeze still leaves open work:

- Anthropic custom tool-reference helpers for user-defined tool-search flows
- broader Google grounding and retrieval tool families
- provider-specific forcing/selection APIs for native tools
- compatibility adapters from the old extension-based tool flags

But the entry boundary is now stable enough for the next migration passes.
