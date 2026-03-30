# Legacy Compatibility Facade And Event Projection

## Goal

This document freezes how the root `llm_dart` package should keep old builder and provider APIs alive while the new package-owned language-model architecture takes over.

It also records the event-projection boundary for the compatibility layer after comparing our design with the Vercel AI SDK reference.

## 1. Why The Compatibility Layer Exists

The compatibility layer is not a temporary convenience wrapper. It is currently the safest migration bridge between:

- the old root-package provider classes and tests
- the new `LanguageModel`-based provider packages
- the future removal of the old builder-centric architecture

Returning a bare adapter from `LLMBuilder.build()` would create avoidable breakage:

- existing code often expects concrete provider subclasses such as `OpenAIProvider`
- old capability checks and typed convenience methods still rely on legacy provider types
- the root package still hosts non-chat provider APIs that are not fully migrated

The compatibility layer therefore needs to preserve old top-level types while routing eligible chat traffic into the new core.

## 2. Frozen Facade Shape

Phase-1 compatibility should use the following shape:

- `LLMBuilder.build()` returns compatibility provider subclasses for migrated providers
- the current migrated providers are OpenAI, Google, Anthropic, plus the audited OpenAI-family subset routes for DeepSeek, OpenRouter, Groq, and xAI
- each compatibility provider subclasses the old provider type
- each compatibility provider overrides only the legacy chat entry points first
- non-chat provider APIs continue to use the old implementation until their new package-owned paths are ready

This means the migration boundary sits inside the provider instance, not at the builder return type.

## 3. Runtime Routing Policy

Each compatibility provider should make the routing decision per request, not only at build time.

Frozen policy:

- create the compatibility provider whenever the builder has enough core config to instantiate the new package-owned model
- before each `chat(...)` or `chatStream(...)` call, evaluate whether the legacy request can be represented faithfully by the new bridge
- if the request is bridge-compatible, use the new `LanguageModel` path
- if the request is not bridge-compatible, fall back to the old provider implementation
- if the bridge throws a compatibility-shape error during conversion, fall back to the old provider implementation
- if the new path fails for a non-compatibility reason, surface the real error instead of silently falling back

The key rule is: no silent feature loss.

If a legacy request uses a provider feature that the new path does not preserve yet, the compatibility layer must reject the bridge and stay on the old implementation.

## 4. Provider Compatibility Snapshot

The bridge allowlists are intentionally conservative.

### OpenAI

Bridge-safe today:

- text-only legacy messages
- legacy common function tools
- OpenAI built-in tools for web search, file search, and computer use
- legacy structured output / `jsonSchema`
- system messages leading the conversation
- allowed HTTP-related extensions
- `useResponsesAPI`
- `previousResponseId`
- `parallelToolCalls`
- `verbosity`

Must fall back today:

- message `name`
- message `extensions`
- non-text legacy message types
- unknown OpenAI-specific root extensions

Reason:

- the new OpenAI path now covers the main text, function-tool, built-in-tool, and structured-output request shapes, but it still does not preserve every old root-package message or extension shape

### Google

Bridge-safe today:

- text messages
- user image messages and image URLs
- user files for the supported chat path
- assistant tool-call messages
- user tool-result messages
- text-only structured output via `jsonSchema`
- web-search configuration that can map into the new typed Google native tool options
- allowed HTTP-related extensions

Must fall back today:

- message `name`
- message `extensions`
- system messages after conversation messages
- unsupported response modalities
- structured output combined with image-generation style modalities
- unknown Google-specific root extensions

### Anthropic

Bridge-safe today:

- text messages
- user image messages
- user HTTP(S) image URLs
- user PDF and plain-text files
- assistant tool-call messages
- user tool-result messages
- legacy Anthropic prompt-cache markers produced by `MessageBuilder`
- legacy Anthropic tools blocks produced by `MessageBuilder` when they only carry common function tools
- legacy raw Anthropic text blocks inside `anthropic.contentBlocks` when they only use `type`, `text`, and optional `cache_control`
- legacy raw Anthropic user image blocks inside `anthropic.contentBlocks` when they use HTTP(S) URLs or supported base64 JPEG/PNG/GIF/WebP payloads
- legacy raw Anthropic user document blocks inside `anthropic.contentBlocks` when they use base64 PDF or inline `text/plain` payloads
- legacy raw Anthropic assistant tool-use replay blocks inside `anthropic.contentBlocks` when they use the re-encodable `tool_use`, `server_tool_use`, or `mcp_tool_use` wire shapes
- legacy raw Anthropic user tool-result replay blocks inside `anthropic.contentBlocks` when they use the currently approved replay-safe wire shapes: `tool_result`, `mcp_tool_result`, `web_search_tool_result`, or `web_fetch_tool_result`
- typed metadata, MCP server config, and web-search config that map into the new Anthropic options
- allowed HTTP-related extensions

Must fall back today:

- message `name`
- legacy message extensions on non-text messages
- message `extensions` outside the supported `anthropic.contentBlocks` raw-text, raw-user-media, raw-tool-replay, cache-marker, and tools-block subset
- raw image or document blocks on non-user messages
- raw tool-use blocks on non-assistant messages
- raw tool-result blocks on non-user messages
- system messages after conversation messages
- `disable_parallel_tool_use` overrides on legacy tool choice
- ambiguous tool-cache policies across cached legacy messages in the same bridged request
- raw document URL blocks and other unsupported raw source shapes inside `anthropic.contentBlocks`
- execution-oriented raw provider-native result blocks inside `anthropic.contentBlocks` that the new Anthropic request codec cannot re-encode yet, such as `code_execution_tool_result`, `bash_code_execution_tool_result`, and `text_editor_code_execution_tool_result`
- unsupported media URLs or file types
- unknown Anthropic-specific root extensions

Important routing rule:

- Anthropic bridge gating must follow request-side re-encoding fidelity, not decode breadth
- a provider-native result block stays bridge-incompatible if the new Anthropic request codec cannot emit the same wire block back out, even if the result codec can decode it

## 5. Event Projection Boundary

The Vercel AI SDK keeps a clear separation between:

- model stream parts
- UI-message chunks

That split is useful and should be preserved in Dart.

The new `llm_dart_core` stream layer already carries a richer model-stream vocabulary such as:

- stream start and warnings
- response metadata
- text and reasoning boundaries
- tool input lifecycle
- tool approval requests
- source references
- files and reasoning files
- step markers
- finish metadata

The old `ChatStreamEvent` API cannot represent most of those concepts.

Frozen compatibility rule:

- the legacy adapter only projects what the old stream API can express safely
- legacy projection keeps `TextDeltaEvent`
- legacy projection keeps `ThinkingDeltaEvent`
- legacy projection keeps `ToolCallDeltaEvent`
- legacy projection keeps `CompletionEvent`
- legacy projection keeps `ErrorEvent`
- start markers, response metadata, step markers, source/file events, approval events, denied events, custom events, and raw chunks stay out of the old stream API

This is intentional lossiness, not an implementation gap.

The richer stream semantics remain available through:

- `llm_dart_core` `TextStreamEvent`
- `ChatUiAccumulator`
- `llm_dart_flutter` chat/session/transport layers
- the typed package-owned provider APIs

## 6. Why We Should Not Mirror The AI SDK UI Chunk Protocol Into Legacy APIs

The reference UI chunk protocol is valuable for transport and UI concerns, but it should not be backported into the old root-package chat stream surface.

Reasons:

- the old API has no stable message/chunk transport contract
- adding many legacy-only event classes would expand a surface we already intend to deprecate
- Flutter integration already has a better long-term home in `llm_dart_flutter`
- the compatibility layer should shrink migration risk, not become a second architecture

The correct long-term direction is:

- keep the rich event model in the new core and Flutter layers
- keep the old stream projection deliberately minimal
- deprecate the old stream API instead of trying to teach it every new concept

## 7. Next Expansion Priorities

The compatibility layer is useful only if it keeps reducing the amount of legacy traffic over time.

Recommended next steps:

1. Expand OpenAI bridge coverage beyond text-only inputs, especially if the root package still needs richer non-text message compatibility.
2. Expand Google bridge coverage for the remaining modality combinations, especially image-generation-adjacent request shapes that should not share the text structured-output path.
3. Expand Anthropic bridge coverage beyond the current lossless raw text, user media/document, prompt-caching, legacy tools-block, and raw tool replay subset into provider-native result replay and broader provider-managed tool-execution flows.
4. Start marking old root-package chat extension entry points as deprecated once the bridge coverage is wide enough.
5. Keep all bridge expansions behind route-compatibility tests so unsupported legacy shapes never degrade silently.
