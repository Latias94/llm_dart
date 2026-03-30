# xAI Legacy Compatibility Audit

## Goal

This note freezes the current xAI compatibility position after the OpenAI-family chat-completions mainline gained:

- typed xAI live-search invocation options in `llm_dart_openai`
- exact `search_parameters` encoding
- shared citation projection through source parts and source events
- audited legacy live-search compatibility routing for the web/news subset

The goal is still not to declare all xAI legacy traffic bridge-safe.

The goal is to separate:

- the text-and-function-tool subset that is already safe
- the audited legacy live-search migration subset that is now also safe
- the remaining xAI-specific legacy surface that must still fall back

## 1. Current Legacy xAI Surface

The old root xAI provider is not just a plain OpenAI-compatible alias.

Its legacy request behavior includes:

- endpoint: `chat/completions`
- common request fields:
  - `model`
  - `messages`
  - `stream`
  - `max_tokens`
  - `temperature`
  - `top_p`
  - `top_k`
  - `tools`
  - `tool_choice`
  - typed `response_format`
- xAI-specific search shaping:
  - `liveSearch`
  - `searchParameters`
  - shared `webSearchEnabled`
  - shared `webSearchConfig`

The old provider also carries xAI-specific behavior:

- shared web-search builder config is converted into xAI-native `search_parameters`
- explicit `liveSearch` can synthesize default web-search parameters
- search can target `web` or `news` sources with date filtering and blocked domains
- prompt-side tool-result replay is lossy:
  - only `message.content` is serialized as tool output
  - only the first tool-call ID is preserved
- named messages are not part of the old xAI request codec

So the old xAI provider is only partly OpenAI-compatible at the wire level.

The search path is provider-owned, and the prompt replay path is not fully lossless.

## 2. Current Refactored Package Coverage

The refactored `llm_dart_openai` package now provides a usable xAI direct path through `XAIProfile` on top of the chat-completions mainline.

Current direct-package coverage now includes:

- text generation
- streaming text deltas
- common function tools
- common tool choice
- typed JSON-schema response format
- typed `XAIGenerateTextOptions(search: ...)`
- exact `search_parameters` request encoding
- citation projection through shared `SourceContentPart` / `SourceEvent`
- OpenAI-family provider metadata namespace

Current gaps relative to the old xAI root-provider behavior still include:

- no compatibility route for prompt-side tool replay
- no compatibility route for multimodal xAI traffic
- no compatibility route for unsupported search shapes beyond the audited web/news subset
- no request-side compatibility contract yet for the old lossy tool-result replay behavior
- no provider-owned bridge contract yet for future xAI provider-defined search tools

So the package mainline exists, and one audited search subset is now safe, but the xAI legacy bridge must still stay selective.

## 3. Bridge-Risk Inventory

### Safe enough today for compatibility subset V2

- plain text prompts
- assistant text
- common function tools declared on the request
- common tool choice
- typed JSON-schema response format
- common chat-completions streaming
- legacy live-search migration inputs that normalize into audited xAI `search_parameters`
- only web/news search sources
- only supported search modes:
  - `auto`
  - `always`
  - `never`
  - compatibility aliases `on` / `off`
- valid `YYYY-MM-DD` date ranges
- search result counts within the typed xAI option contract

### Not bridge-safe yet for automatic legacy routing

- prompt replay that uses:
  - `ToolUseMessage`
  - `ToolResultMessage`
- any request that depends on xAI-specific search result semantics beyond shared citations
- any request that depends on richer or unsupported search source kinds
- any request that depends on invalid or out-of-contract search values that the typed bridge now validates
- named legacy messages
- any multimodal xAI request
- any request that depends on ignored legacy-only controls such as:
  - `stopSequences`
  - `user`
  - `serviceTier`
  - OpenAI-family extras like `parallelToolCalls` or `verbosity`

## 4. Frozen Bridge-Safe Subset V2

The active xAI compatibility subset is now V2.

It includes:

- provider: `xai`
- prompt shape:
  - system text
  - user text
  - assistant text
- common request controls:
  - `maxTokens`
  - `temperature`
  - `topP`
  - `topK`
  - one system-shaping path only:
    - either `systemPrompt`
    - or explicit system messages
- common tool support:
  - common function tools only
  - common `ToolChoice`
- structured output:
  - typed JSON-schema response format only
- audited legacy live-search migration inputs:
  - `liveSearch`
  - `searchParameters`
  - `webSearchEnabled`
  - `webSearchConfig`
- audited search normalization rules:
  - only web/news sources
  - empty sources normalize to default web search
  - legacy `always` / `never` normalize to typed xAI `on` / `off`
  - invalid dates, invalid source kinds, and unsupported modes force fallback instead of bridge-time errors

The active subset still excludes:

- prompt-side tool replay in prompt history
- named messages
- legacy message extensions
- multimodal prompt parts
- unsupported search source kinds
- invalid search date ranges or out-of-range result counts
- `stopSequences`
- `user`
- `serviceTier`
- OpenAI-family extension-only controls that the old xAI provider ignored

## 5. Routing Rule Recommendation

The xAI subset V2 is now the active compatibility rule.

Current routing rule:

- if the request matches the xAI subset V2 exactly, it routes to `llm_dart_openai` with `XAIProfile`
- otherwise it stays on the legacy xAI provider path automatically

This is intentionally a per-request rule, not a declaration that all xAI search or replay behavior is now migrated.

## 6. Why The Search Expansion Is Safe Enough

The search expansion is now acceptable because the compatibility bridge no longer needs to invent a new interpretation.

It now has all of the following frozen:

- provider-owned typed xAI live-search options
- exact `search_parameters` encoding in the package mainline
- shared citation projection for the currently observed xAI output
- compatibility mapping that reuses `XAIConfig.fromLLMConfig(...)` before narrowing to the audited typed subset

That means the bridge now preserves the old builder semantics for:

- `liveSearch == true` default web search enablement
- `webSearchEnabled == true` default web search enablement
- `webSearchConfig` conversion into the legacy xAI search-parameter subset
- explicit legacy `searchParameters` when they stay inside the audited web/news contract

The bridge still refuses unsupported or invalid search shapes instead of silently widening the typed contract.

## 7. Follow-Up Work Needed Before Further Expansion

1. Decide whether xAI prompt-side tool replay deserves a provider-owned replay adapter later, or should stay fallback-only for the migration window.
2. Decide whether any multimodal xAI subset is worth bridging at all.
3. Decide how future xAI provider-defined search tools should surface beside the current chat live-search options.
4. Keep compatibility tests that prove:
   - plain text-and-tool-definition xAI requests route safely
   - audited legacy live-search migration inputs route safely
   - unsupported search shapes force fallback
   - tool replay forces fallback
   - multimodal xAI requests force fallback

## 8. Current Conclusion

xAI has now crossed:

- the package-mainline threshold
- the initial compatibility-routing threshold for the text subset
- the first audited compatibility-routing threshold for the legacy live-search migration subset

That is still a conservative intermediate state.

The next safe step is not to broaden routing by default.

The next safe step is to audit the next xAI subset explicitly, most likely prompt-side tool replay or any additional search-source family, before broadening the bridge again.
