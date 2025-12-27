# ADP-0001: Make Provider-Native Tools First-Class (ProviderTool + ToolNameMapping)

Status: Accepted (MVP2 implemented for Anthropic/Google/OpenAI Responses)  
Date: 2025-12-21  
Scope: `llm_dart_core`, `llm_dart_ai`, provider packages

## Context

`llm_dart` is being split into multiple publishable packages (Vercel AI SDK style),
while keeping:

1. A convenient “suite” (`llm_dart`) for most users.
2. The ability to install only subpackages (`llm_dart_openai`, `llm_dart_google`, …).
3. A narrow, stable unified surface (capability traits + high-level `ai()`/task APIs).
4. An escape hatch for provider-only capabilities via `LLMConfig.providerOptions` and `ChatResponse.providerMetadata`.

In modern providers, “tools” come in **two different execution models**:

- **Client-executed function tools**: the SDK executes the tool locally and sends tool results back.
- **Provider-executed built-in tools** (provider-native tools): the provider runs the tool server-side
  (e.g. web search / file search / computer use / grounding) and returns results/citations/side-band data.

Vercel AI SDK treats these as separate concepts and uses a tool-name mapping layer to avoid collisions:

- Tool name mapping: `repo-ref/ai/packages/provider-utils/src/create-tool-name-mapping.ts`
- OpenAI Responses tool preparation: `repo-ref/ai/packages/openai/src/responses/openai-responses-prepare-tools.ts`

We have already started to move provider-native tool configuration into `providerOptions`,
and we added safeguards (e.g. reserved local tool names like `web_search` / `google_search`)
to prevent accidental execution in local tool loops.

## Problem

Right now, `llm_dart` models “tools” primarily as local function tools (`Tool` + `FunctionTool`),
and provider-native tools are handled via provider-specific injection and name-based heuristics.
This creates recurring problems:

1. **Wrong execution semantics**: local tool loops must never “execute” provider-native tools.
2. **Name collisions**: a user can define a local function tool with the same name as a provider-native tool.
3. **Brittle conventions**: “reserved names + throw” does not scale across providers and versions.
4. **Inconsistent response surface**: provider-native tool calls/results/citations are hard to represent
   uniformly without conflating them with local tool calls.
5. **Harder package split**: without a clear abstraction, each provider package reinvents special casing,
   increasing dependency tangles and maintenance burden.

Web search is a concrete example: its semantics vary widely across providers and cannot be standardized
meaningfully without losing important provider-specific behavior.

## Decision

Introduce a first-class abstraction for provider-native tools in `llm_dart_core` and make it the
canonical way to represent provider-executed tools across all provider packages.

### 1) Two tool kinds

Add a new tool definition type:

- `FunctionTool` (existing): local/client-executed.
- `ProviderTool` (new): provider-executed.

Key rule:

- **`llm_dart_ai` tool loops execute only `FunctionTool`.**
- `ProviderTool` is never executed locally; the SDK only configures it, sends it, and surfaces its results.

### 2) Stable IDs for provider-native tools

`ProviderTool` must have a stable identifier (versionable), separate from the provider’s request JSON name.

Recommended ID scheme (Vercel-style):

- `openai.web_search_preview`
- `openai.file_search`
- `openai.computer_use_preview`
- `anthropic.web_search_20250305` (example)
- `google.google_search`

### 3) ToolNameMapping (collision-safe name resolution)

Introduce a `ToolNameMapping` layer per request that maps:

- Local `FunctionTool.name` → provider request name (may be rewritten to avoid collisions)
- `ProviderTool.id` → provider request tool name/type (provider-specific)

This replaces long-term reliance on “reserved names + throw”:

- Users can keep their own local tool names.
- Provider-native tools can be enabled without forcing a fixed local name.
- We can safely support multiple provider-native tool versions simultaneously.

### 4) Response modeling: provider-executed tool calls/results are first-class

Extend response models to distinguish:

- `ToolCall` / `ToolResult` from local function tools
- Provider-native tool call/result events (providerExecuted), including citations/annotations where applicable

The minimal requirement:

- A tool call in the response must indicate whether it is **client-executed** or **provider-executed**.

Provider-specific output remains in `providerMetadata[providerId]`, but the *existence* and *identity*
of provider-executed tool calls should be representable in a structured way.

### 5) Configuration flow

We keep `providerOptions` as the escape hatch, but provide a typed path:

- **Typed**: `ProviderTool` objects (recommended for new code)
- **Untyped**: `providerOptions[providerId]` (escape hatch + migration path)

Provider packages may continue to accept untyped knobs during migration, but should gradually converge on:

- A small typed surface for widely used provider-native tools
- `providerOptions` for everything else

## Consequences

### Positive

- Correct execution semantics (no accidental local execution).
- Scales to more providers and tool versions (stable IDs + mapping).
- Cleaner provider packages (less ad-hoc injection and filtering).
- Better alignment with Vercel AI SDK design, improving long-term maintainability.
- Preserves “suite + composability” goals by keeping the standard surface narrow.

### Costs / Risks

- More types in the core model layer; migration needs careful sequencing.
- Streaming semantics differ by provider and will require provider-specific adapters.
- Some existing user code may rely on raw tool names; migration must be gradual and well documented.

## Migration Plan (MVPs)

### MVP1: Core modeling (no behavior change)

1. Add `ProviderTool` type(s) to `llm_dart_core` (no provider code required yet).
2. Add `ToolNameMapping` utilities to `llm_dart_provider_utils`.
3. Extend response models to carry a provider-executed marker (minimal fields first).

### MVP2: Provider adapters (incremental)

Migrate provider packages one-by-one to use the new modeling + mapping:

- OpenAI Responses built-in tools (`web_search_preview`, `file_search`, `computer_use_preview`)
- Anthropic Messages web search tool(s)
- Google Gemini grounding (`google_search`)

During this phase:

- Keep `providerOptions` keys working (compatibility).
- Keep “reserved name” checks temporarily, but prefer mapping when enabled.

### MVP3: Deprecate legacy heuristics

1. Remove or relax “reserved tool names” once mapping is the default path.
2. Standardize documentation around `ProviderTool` usage.
3. Provide a clear upgrade guide (before/after examples).

## Open Questions

1. Do we want a single unified `ToolDefinition` union type, or keep separate lists
   (`functionTools` + `providerTools`) in configs?
2. How should tool choice (`ToolChoice`) interact with provider-native tools?
3. How should we surface citations/annotations generically (standard fields vs providerMetadata)?
4. Do we want to allow a provider package to expose additional typed provider tools (beyond the “common ones”),
   or keep everything else behind `providerOptions`?

## References

- Vercel AI SDK tool name mapping:
  - `repo-ref/ai/packages/provider-utils/src/create-tool-name-mapping.ts`
- Vercel AI SDK OpenAI Responses tool preparation:
  - `repo-ref/ai/packages/openai/src/responses/openai-responses-prepare-tools.ts`
- MiniMax Anthropic-compatible API (tool-loop constraints and request field support):
  - https://platform.minimax.io/docs/api-reference/text-anthropic-api
