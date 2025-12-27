# Provider Alignment Progress (Living Tracker)

This document tracks our ongoing effort to align each `llm_dart_*` provider
package with the provider's official API documentation (and to follow the
package split / “standard surface” philosophy of the Vercel AI SDK).

Scope:

- **Providers**: shipped provider packages in `packages/`
- **Protocol reuse layers**: `*_compatible` packages
- **Outputs**: provider guides, option references, conformance tests

Non-goals:

- Maintaining a provider/model “support matrix” (best-effort forwarding only)
- Enforcing provider-specific constraints client-side

References:

- ADPs index: `docs/adp/README.md`
- Standard surface: `docs/standard_surface.md`
- Architecture / MVPs: `docs/llm_dart_architecture.md`
- Vercel AI SDK reference code: `repo-ref/ai/`

---

## Workflow (per provider package)

For each provider `llm_dart_<name>`:

1) Link official docs (auth, baseUrl, endpoints, request/response schema, streaming)
2) Create/refresh provider guide: `docs/providers/<name>.md`
3) Update `docs/provider_options_reference.md` (namespaced keys + escape hatches)
4) Implement missing behaviors (request compilation, streaming parsing, metadata passthrough)
5) Add conformance tests (offline/mocked) for:
   - request JSON compilation (including `providerOptions`/`providerTools` bridges)
   - streaming part ordering + tool call semantics
   - providerMetadata namespacing stability
5.5) (Optional, local) run live smoke checks with real keys:
   - `dart run tool/live_provider_alignment.dart --all`
6) Record notable changes in `CHANGELOG.md`

---

## Status Overview

Legend:

- ✅ done
- 🟡 in progress
- ⬜ not started

| Provider | Package(s) | Protocol reuse | Official docs | Vercel ref | Guide | Options ref | Conformance tests | Notes |
|---|---|---|---|---|---|---|---|---|
| OpenAI | `llm_dart_openai` | (provider-specific) | ✅ | `repo-ref/ai/packages/openai` | ✅ `docs/providers/openai.md` | ✅ | ✅ | Responses is OpenAI-only (`docs/adp/0007-openai-responses-openai-only.md`) |
| OpenAI-compatible baseline | `llm_dart_openai_compatible` | (baseline) | ✅ | `repo-ref/ai/packages/openai-compatible` | ✅ `docs/protocols/openai_compatible.md` | ✅ | ✅ | Targets Chat Completions only |
| Anthropic | `llm_dart_anthropic` | `llm_dart_anthropic_compatible` | ✅ | `repo-ref/ai/packages/anthropic` | ✅ `docs/providers/anthropic.md` | ✅ | ✅ | Messages + thinking + caching + web_search/web_fetch server tools |
| Anthropic-compatible baseline | `llm_dart_anthropic_compatible` | (baseline) | ✅ | `repo-ref/ai/packages/anthropic` | ✅ `docs/protocols/anthropic_compatible.md` | ✅ | ✅ | Reused by MiniMax |
| Google (Gemini) | `llm_dart_google` | (provider-specific) | ✅ | `repo-ref/ai/packages/google` | ✅ `docs/providers/google.md` | ✅ | ✅ | Grounding/web search tools |
| MiniMax | `llm_dart_minimax` | `llm_dart_anthropic_compatible` | ✅ | (community provider) | ✅ `docs/providers/minimax.md` | ✅ | ✅ | Anthropic-compatible route only |
| Groq | `llm_dart_groq` | `llm_dart_openai_compatible` | ✅ | `repo-ref/ai/packages/groq` | ✅ `docs/providers/groq.md` | ✅ | ✅ | OpenAI-compatible deltas |
| DeepSeek | `llm_dart_deepseek` | `llm_dart_openai_compatible` | ✅ | `repo-ref/ai/packages/deepseek` | ✅ `docs/providers/deepseek.md` | ✅ | ✅ | Reasoning deltas |
| xAI | `llm_dart_xai` | `llm_dart_openai_compatible` | ✅ | `repo-ref/ai/packages/xai` | ✅ `docs/providers/xai.md` | ✅ | ✅ | Chat Completions + Responses (`xai.responses`) |
| OpenRouter | `llm_dart_openai_compatible` | (config-only) | ✅ | (N/A) | ✅ `docs/providers/openrouter.md` | ✅ | ✅ | Web search via `:online` model suffix |
| Ollama | `llm_dart_ollama` | (provider-specific) | ✅ | (not in Vercel core) | ✅ `docs/providers/ollama.md` | ✅ | ✅ | JSONL streaming |
| ElevenLabs | `llm_dart_elevenlabs` | (provider-specific) | ✅ | `repo-ref/ai/packages/elevenlabs` | ✅ `docs/providers/elevenlabs.md` | ✅ | ✅ | Audio-only provider |

---

## Next Up (recommended order)

1) Options reference polish: keep provider option namespaces complete + stable
2) Expand coverage: add more offline conformance tests for edge streaming cases as they appear

---

## Recent changes (log)

- 2025-12-24: Anthropic-compatible request builder now avoids applying
  `cache_control` to provider-native server tools (`web_search_*` / `web_fetch_*`),
  aligning with Vercel Anthropic provider behavior.
- 2025-12-24: OpenAI-compatible request builder now treats `*-openai` provider ids
  (e.g. `groq-openai`, `deepseek-openai`, `xai-openai`) the same as their provider
  package counterparts for provider-specific deltas.
- 2025-12-24: Anthropic streaming no longer emits a premature “finish” event at
  `message_start`; the Anthropic provider now exposes `chatStreamParts` for
  correct delta streaming via `llm_dart_ai` (`streamText`/`streamChatParts`).
- 2025-12-24: Anthropic-compatible `chatStreamParts` now preserves additional
  content block types (`server_tool_use`, `*_tool_result`, `mcp_tool_*`) and
  supports `tool_use` blocks that include non-empty `input` at
  `content_block_start` (deferred tool calling); MCP tool blocks are no longer
  surfaced as local `toolCalls` to avoid accidental execution in tool loops.
- 2025-12-24: Anthropic-compatible legacy `chatStream` (ChatStreamEvent) no
  longer emits premature `CompletionEvent` at `message_delta`; it now preserves
  content blocks for the final response and supports both pre-populated tool
  uses at `message_start` and progressive `partial_json` tool input deltas.
- 2025-12-24: Anthropic-compatible streaming now preserves `citations_delta`
  events by attaching citations to the corresponding text content blocks.
- 2025-12-24: OpenAI-compatible streaming now captures trailing `usage` chunks
  that may arrive after the `finish_reason` chunk (common with Azure).
- 2025-12-24: Google providerOptions `safetySettings` now accepts JSON-like maps
  (in addition to typed `SafetySetting` objects).
- 2025-12-24: Added xAI Responses API provider id `xai.responses` (streaming
  parts + offline fixture replays).
- 2025-12-24: Anthropic docs are accessible via `platform.claude.com/docs/*`.
  For scripted extraction, use `curl -H 'RSC: 1'` against pages like:
  - `https://platform.claude.com/docs/en/api/beta-headers`
  - `https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-search-tool`
  - `https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-fetch-tool`
- 2025-12-24: Added `docs/providers/anthropic.md` and aligned `web_fetch` beta
  header injection with official docs (`anthropic-beta: web-fetch-2025-09-10`).
- 2025-12-24: Added provider/protocol guides for OpenAI-compatible providers and
  standardized protocol docs under `docs/protocols/`.
- 2025-12-24: OpenAI provider now supports `providerOptions['openai']['extraBody']`
  and `extraHeaders` consistently across Chat Completions and Responses.
