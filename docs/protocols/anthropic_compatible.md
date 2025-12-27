# Anthropic-compatible Protocol Layer (Messages API baseline)

This document tracks how `llm_dart_anthropic_compatible` aligns with the
Anthropic **Messages API** wire format.

Scope:

- The **wire protocol** layer: request JSON compilation, streaming parsing, and
  best-effort passthrough for Anthropic-style optional params.
- Reused by multiple provider packages (Anthropic, MiniMax, and future
  Anthropic-compatible providers).

Non-goals:

- Maintaining provider/model support matrices (best-effort forwarding only).
- Hiding incompatibilities behind silent request “fixups” (prefer surfacing API errors).

## Official docs (baseline references)

Primary:

- Messages API: https://platform.claude.com/docs/en/api/messages
- Create message: https://platform.claude.com/docs/en/api/messages/create
- Streaming: https://platform.claude.com/docs/en/api/messages/streaming

Related:

- Tool use: https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview
- Prompt caching: https://platform.claude.com/docs/en/build-with-claude/prompt-caching
- Extended thinking: https://platform.claude.com/docs/en/build-with-claude/extended-thinking
- Beta headers: https://platform.claude.com/docs/en/api/beta-headers

Reference implementation (Vercel AI SDK):

- `repo-ref/ai/packages/anthropic`

## Package mapping (where things live)

Protocol config + options parsing:

- `packages/llm_dart_anthropic_compatible/lib/config.dart`

Request compilation:

- `packages/llm_dart_anthropic_compatible/lib/request_builder.dart`

HTTP client + SSE parsing:

- `packages/llm_dart_anthropic_compatible/lib/client.dart`
- `packages/llm_dart_provider_utils/lib/utils/sse_chunk_parser.dart`

Streaming → standard parts:

- `packages/llm_dart_anthropic_compatible/lib/chat.dart`

## Protocol constraint: assistant content replay

Anthropic-style multi-step tool use has a protocol constraint:

- Callers must preserve and replay the full assistant content blocks between
  turns for continuity (e.g. thinking/tool_use signatures).

LLM Dart models this via `ChatResponseWithAssistantMessage`, which task-level
tool loops (`llm_dart_ai`) will prefer when available.

Background:

- `docs/adp/0003-anthropic-compatible-protocol-reuse.md`

## Streaming semantics (content blocks)

Anthropic streaming is based on **content blocks** (`content_block_*` events).
LLM Dart supports two streaming surfaces:

- `chatStreamParts` (preferred): emits `LLMStreamPart` with block boundaries and
  preserves provider-native blocks for replay.
- `chatStream` (legacy): emits `ChatStreamEvent` deltas and returns a final
  `CompletionEvent` with provider metadata + content blocks.

Supported block types (best-effort):

- `text` → surfaced as text deltas/blocks
- `citations_delta` (within `text` blocks) → preserved on the final text block
  as `citations` (best-effort)
- `thinking` / `redacted_thinking` → surfaced as thinking deltas/blocks
- `tool_use` → surfaced as local tool calls **only** for non-provider-native tools
- `server_tool_use` / `*_tool_result` → preserved as assistant content blocks
  (provider-executed tools; not surfaced as local tool calls)
- `mcp_tool_use` / `mcp_tool_result` → preserved as assistant content blocks and
  exposed via `AnthropicChatResponse.mcpToolUses` / `mcpToolResults` (not surfaced
  as local tool calls)

Programmatic/deferred tool calling:

- `tool_use` blocks may include a non-empty `input` at `content_block_start` or
  even be pre-populated in `message_start.message.content`. LLM Dart preserves
  these blocks and exposes them as completed tool calls (non-provider-native only).

## Escape hatches and provider-specific deltas

Provider-only knobs are read from `LLMConfig.providerOptions[providerId]`.

Some Anthropic-compatible providers may support a fallback namespace to reduce
duplication (e.g. MiniMax reads `providerOptions['minimax']` first, then may
fall back to `providerOptions['anthropic']`).

Common escape hatches:

- `extraBody`: `Map<String, dynamic>`
- `extraHeaders`: `Map<String, String>`

Provider-native tools:

- Web search / web fetch are treated as **provider-executed** server tools and
  should be configured via `providerTools` (preferred) or `providerOptions`
  (legacy/best-effort).

## Conformance tests (offline/mocked)

Protocol conformance suite:

- `test/protocols/anthropic_compatible/README.md`
- `test/protocols/anthropic_compatible/request_builder_conformance_test.dart`

Providers that reuse this protocol layer should add thin wrapper tests under:

- `test/providers/<provider>/...` (example: MiniMax)
