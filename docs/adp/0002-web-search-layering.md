# ADP 0002: Web Search Layering (Provider-native First)

## Status

Accepted

## Context

`llm_dart` aims to be both:

- an “all-in-one suite” for convenience, and
- a set of composable subpackages users can pick and combine.

At the same time, we want a stable “standard surface” (unified APIs) that
doesn’t bloat every time a provider adds a new feature.

## Problem

Web search is a common user need, but its semantics vary significantly:

- Some providers offer **provider-native tools** (server-executed), e.g.
  Anthropic `web_search_*`, OpenAI Responses web search, Google built-in search.
- Some providers can only support web search via a **local tool loop**
  (SDK/app executes HTTP fetch/search and returns results).
- Result structures, citations, billing semantics, and available knobs
  (domain allow/deny lists, location, context size, etc.) are not compatible.

If we elevate web search into the unified “standard surface”, we risk:

- abstraction leakage and inconsistent behavior across providers,
- a growing standard API that becomes hard to keep stable long-term
  (Vercel AI SDK keeps the “standard” surface intentionally narrow).

## Decision

1. **Web search is not part of the unified standard surface.**
   We do not add a cross-provider `webSearch` capability/task.
2. **For providers that support provider-native web search, we treat it as a
   first-class `ProviderTool`:**
   - Configure via `LLMConfig.providerTools`.
   - `LLMBuilder.enableWebSearch()/webSearch()` were removed; use explicit
     `providerTools` and typed catalogs.
   - `ToolNameMapping` prevents collisions between local function tools and
     provider-native tools (e.g. `web_search`).
3. **For providers that do NOT support provider-native web search (e.g. MiniMax
   Anthropic-compatible today):**
   - The provider API may return an error response for unsupported tools.
   - We do not require SDK-side prevalidation; use a local `FunctionTool` when
     you need web search in these environments.
   - Keep the actual HTTP scraping/search implementation **out of the SDK**
     (examples/apps only), to avoid bloating responsibilities and dependencies.

## Consequences

### Pros

- A smaller, more stable standard surface (aligned with Vercel AI SDK style).
- Provider-native web search stays “native” (server-executed) and can expose
  provider metadata such as `server_tool_use` stats.
- No built-in network scraping/search dependencies shipped as part of the SDK.

### Cons

- Users must understand the two modes:
  - provider-native (configure `providerTools`)
  - local tool loop (custom `FunctionTool` + executor)

## Related Implementation Notes

- Provider-native tools first-class: `docs/adp/0001-provider-tools-first-class.md`
- We intentionally keep “local web search” implementations out of the SDK
  (examples/apps only).
- Conformance guardrails:
  - provider-native `web_search` is filtered and not surfaced as a local tool call
  - collision-safe renaming for a local tool named `web_search`
