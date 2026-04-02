# Tool Definition Boundary

## Goal

This note freezes the phase-1 tool-definition boundary for the new architecture.

The main question is not whether tools matter. They do. The real question is:

- which parts of tool calling are stable enough to belong in `llm_dart_core`
- which parts are provider-native and should stay in provider packages

If this line is not frozen early, tool support quickly becomes the place where
provider-specific complexity leaks back into the core API.

## Frozen Conclusion

`llm_dart_core` should expose only the cross-provider function-tool contract:

- `FunctionToolDefinition`
- `ToolJsonSchema`
- `ToolChoice`

Provider-native tools should stay out of the common core request model for now.

That means the new core request shape is intentionally narrower than the full
surface of the Vercel AI SDK provider layer.

## What Enters The Core

The common request model now supports:

- declared client function tools
- object-rooted JSON input schemas
- four shared tool-choice states:
  - `AutoToolChoice`
  - `RequiredToolChoice`
  - `NoneToolChoice`
  - `SpecificToolChoice`

These concepts are stable across OpenAI-style function calling, Anthropic custom
tools, and Google function declarations.

## What Stays Out Of The Core

The following do not enter the common tool-definition model in phase 1:

- OpenAI built-in tools
- Anthropic versioned provider tools
- Google provider-native tools such as code execution, grounding, or search
- provider-only tool flags such as Anthropic parallel-tool controls
- provider-side tool management APIs

These features vary too much in naming, lifecycle, and request shape.

They should instead use the existing provider-feature channels:

- typed model settings
- typed invocation options
- provider metadata
- custom content or custom events
- provider-native extension APIs

## Why This Boundary Is Better For `llm_dart`

This project is not trying to clone the Vercel AI SDK package graph.

The useful lesson from `repo-ref/ai` is the separation between:

- a small shared tool contract
- provider-owned tool adaptation

The part that should not be copied directly is the temptation to keep growing the
shared tool model until it becomes a second provider surface.

For `llm_dart`, the better phase-1 tradeoff is:

- keep the shared request model focused on client function tools
- let provider packages map that model into their own wire formats
- keep provider-native tools behind typed provider APIs until their long-term
  shape is proven

This keeps Flutter integration simpler as well, because app code can rely on one
stable function-tool contract while still opting into provider-native features
explicitly when needed.

## Current Implementation Result

The current core request path now provides:

- `GenerateTextRequest.tools`
- `GenerateTextRequest.toolChoice`
- early validation for duplicate tool names
- early validation for `SpecificToolChoice` against declared tools

The current provider status is:

- `llm_dart_google`
  - maps common function tools into Google `functionDeclarations`
  - maps common `ToolChoice` into `toolConfig.functionCallingConfig`
- `llm_dart_anthropic`
  - maps common function tools into Anthropic `tools`
  - maps common `ToolChoice` into Anthropic `tool_choice`
  - keeps `NoneToolChoice` as “omit request-side tools”, matching Anthropic's
    actual API limitation

## Immediate Follow-Up

This freeze does not solve all tool work.

The next layers still need design and migration:

- provider-native tool entry APIs
- structured-output / JSON-output interaction with tools
- higher-level tool execution orchestration in `llm_dart_chat`, with
  Flutter-only adapters in `llm_dart_flutter`
- compatibility adapters from the old root package tool model

But the main boundary is now stable enough to migrate providers without pushing
provider-native tool semantics back into `llm_dart_core`.
