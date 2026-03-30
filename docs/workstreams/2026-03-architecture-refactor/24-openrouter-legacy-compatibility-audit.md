# OpenRouter Legacy Compatibility Audit

## Goal

This note freezes the initial OpenRouter compatibility position after the OpenAI-family chat-completions mainline landed in `llm_dart_openai`.

The goal is not to declare all OpenRouter legacy traffic bridge-safe.

The goal is to separate:

- the plain OpenAI-compatible chat subset that can now route safely
- the audited online-intent search subset that can now route safely
- the remaining OpenRouter-specific search-shaped legacy traffic that still needs fallback

## 1. Current Legacy OpenRouter Surface

The old OpenRouter path is implemented through the generic OpenAI-compatible provider stack, plus OpenRouter-specific builder helpers.

The legacy surface currently includes:

- plain OpenAI-compatible chat-completions requests
- common function tools
- common structured output
- search-shaped builder entry points such as:
  - `webSearchEnabled`
  - `webSearchConfig`
  - `searchPrompt`
  - `useOnlineShortcut`
  - `maxSearchResults`
- explicit `:online` model suffix usage
- OpenRouter-specific model catalog diversity, including routed third-party models

The important subtlety is that the old implementation does not have a rich OpenRouter-native request codec.

The main OpenRouter-specific shaping that is actually enforced today is:

- `webSearchEnabled` or `webSearchConfig` can trigger `:online` model suffix shaping
- some OpenRouter model families, such as DeepSeek R1 through OpenRouter, also use provider-specific request knobs like `include_reasoning`

So the old OpenRouter path is less expressive than the builder surface suggests.

## 2. Current Refactored Package Coverage

The refactored `llm_dart_openai` package now provides a usable OpenRouter direct path through `OpenRouterProfile` on top of the chat-completions mainline.

Current direct-package coverage includes:

- text generation
- streaming text deltas
- reasoning extraction from provider output when it appears in OpenAI-compatible fields
- common function tools
- common tool choice
- streamed tool-call aggregation
- typed JSON-schema response format
- OpenRouter provider metadata namespace

Current gaps relative to the old OpenRouter builder surface still include:

- no frozen compatibility mapping for richer OpenRouter search-shaped builder options beyond online-model intent
- no explicit request-side handling for OpenRouter-specific DeepSeek R1 `include_reasoning`
- no provider-specific audit yet for OpenRouter search result semantics

## 3. Bridge-Risk Inventory

### Safe enough today for compatibility subset V2

- plain text prompts
- assistant text
- common function tools
- common tool results
- common structured output
- common chat-completions streaming
- explicit `:online` model usage
- `webSearchEnabled`
- `webSearchConfig` when it only needs to preserve the legacy observable online-model shaping behavior

### Not bridge-safe yet for automatic legacy routing

- any search-shaped request that depends on:
  - `searchPrompt`
  - `useOnlineShortcut`
  - `maxSearchResults`
- OpenRouter requests that depend on provider-specific search semantics rather than plain chat-completions
- OpenRouter requests for DeepSeek R1 style models that depend on provider-specific request shaping such as `include_reasoning`
- any multimodal OpenRouter request, because the first subset is intentionally text-only

### Why `webSearchConfig` is now bridge-safe

The old OpenRouter implementation does not prove a richer OpenRouter-native search request body.

In the current repository, the observable request-side effect of `webSearchConfig` is still only:

- shape the model ID to `:online`

That means the compatibility bridge can now accept `webSearchConfig` without inventing new behavior, as long as it only preserves that exact online-model shaping effect.

The bridge still must not pretend that fields such as `searchPrompt` or `maxSearchResults` have a frozen wire contract.

## 4. Frozen Bridge-Safe Subset V2

The active OpenRouter compatibility subset now includes:

- provider: `openrouter`
- model:
  - plain chat model IDs
  - explicit `:online` model IDs
- prompt shape:
  - system text
  - user text
  - assistant text
  - assistant common function tool calls
  - tool results for common function tools
- common request controls:
  - `maxTokens`
  - `temperature`
  - `topP`
  - `topK`
  - `stopSequences`
  - `serviceTier`
- provider options that already map cleanly through the new chat-completions codec:
  - `parallelToolCalls`
  - `verbosity`
  - typed JSON-schema response format
- audited online-intent search migration inputs:
  - `webSearchEnabled`
  - `webSearchConfig`

The active subset still explicitly excludes:

- standalone OpenRouter legacy-only extension keys such as:
  - `searchPrompt`
  - `useOnlineShortcut`
  - `maxSearchResults`
- OpenRouter DeepSeek R1 style requests
- `user` override, because the current refactored OpenAI-family path does not preserve it
- provider-native or Responses-only options
- multimodal request shapes

## 5. Routing Rule Recommendation

The OpenRouter subset V2 is now the active compatibility rule.

Current routing rule:

- if the request matches the OpenRouter subset V2 exactly, it routes to `llm_dart_openai` with `OpenRouterProfile`
- otherwise it stays on the legacy OpenRouter path automatically

This is intentionally a per-request rule, not a declaration that OpenRouter search features are now migrated.

## 6. Follow-Up Work Needed Before Expansion

1. Decide whether any richer OpenRouter search request contract exists beyond model shaping in this repository.
2. Decide whether standalone legacy extension keys such as `searchPrompt`, `maxSearchResults`, and `useOnlineShortcut` should stay rejected forever or be explicitly documented as legacy no-ops.
3. Decide whether OpenRouter DeepSeek R1 requests deserve a dedicated audited subset with explicit request-side reasoning toggles.
4. Keep compatibility tests that prove:
   - plain text-and-tool OpenRouter requests route safely
   - online-intent migration inputs route safely
   - standalone legacy-only search extension keys force fallback
   - OpenRouter DeepSeek R1 requests force fallback

## 7. Current Conclusion

OpenRouter has now crossed:

- the package-mainline threshold
- the initial compatibility-routing threshold for the plain text subset
- the first audited compatibility-routing threshold for the online-intent search subset

That is still a conservative intermediate state.

The next safe step is not to broaden routing by default.

The next safe step is to audit whether OpenRouter actually has any richer stable search contract in this repository beyond online-model shaping before broadening the bridge again.
