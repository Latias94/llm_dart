# OpenAI-Family Facade And Legacy Routing

## Goal

This note defines the boundary between:

- the new root `AI` facade as the primary refactored entry point
- the old `LLMBuilder` and compatibility-provider routing

The key rule is simple:

- a new facade constructor does not automatically imply a safe legacy bridge path

That distinction matters for the OpenAI-family providers because the transport protocol overlap is real, but the provider-specific behavior overlap is incomplete.

## 1. Current State

Today we have two different migration surfaces:

### New primary API

- `AI.openai(...)`
- `AI.openRouter(...)`
- `AI.deepSeek(...)`
- `AI.groq(...)`
- `AI.xai(...)`
- `AI.phind(...)`

These constructors all target the refactored `llm_dart_openai` package and differ only by profile selection plus optional base URL override.

### Legacy compatibility API

- `ai()`
- `LLMBuilder`
- old provider subclasses such as `OpenAIProvider`, `DeepSeekProvider`, `GroqProvider`, `XAIProvider`, and `PhindProvider`

The current compatibility resolver routes:

- OpenAI, Google, and Anthropic through their existing conservative compatibility paths
- DeepSeek through a narrower audited subset on top of the new OpenAI-family chat-completions mainline
- OpenRouter through a narrower audited plain-chat subset, while search-shaped traffic still falls back
- Groq through a narrower audited text-and-tool-definition subset, while tool replay and multimodal traffic still fall back
- xAI through a narrower audited text subset plus the audited legacy live-search migration subset, while prompt-side tool replay and unsupported search shapes still fall back

That is still intentional.

## 2. Why The OpenAI-Family Facade Can Move Faster Than Legacy Routing

The new facade only promises:

- a stable typed entry
- a transport-first model factory
- a profile-owned provider identity and default base URL

It does **not** promise:

- parity with every old root-provider convenience feature
- parity with every old `LLMConfig.extensions` path
- automatic support for every legacy request shape

Legacy routing has a stricter bar:

- the old request must be representable faithfully
- provider-specific options must survive conversion
- unsupported behavior must fall back instead of degrading silently

That means the facade can safely expose more providers before the legacy bridge can safely route them.

## 3. Current State In The Refactored Package

The refactored `llm_dart_openai` text path now has two mainlines:

- Responses API when `settings.useResponsesApi == true` and the selected profile says `supportsResponsesApi == true`
- chat-completions otherwise

That means the OpenAI-family profiles currently behave like this:

- OpenAI: can use Responses or chat-completions
- OpenRouter / DeepSeek / Groq / xAI / Phind: default to chat-completions because `supportsResponsesApi = false`

So the old hard blocker is gone:

- these providers are no longer runtime-blocked by a Responses-only package mainline

But the compatibility resolver should still stay conservative today.

The current blocker is now narrower and more important:

- a package mainline exists, but the bridge-safe legacy subset is still not frozen per provider
- provider-specific legacy request shaping still has to be audited explicitly
- compatibility routing must still reject or fall back for shapes that are not proven bridge-safe

So the correct current state is:

- "the refactored package can run these providers directly through the new facade"
- "the legacy resolver should only auto-route providers whose bridge-safe subset is explicit and tested"

## 4. Provider Routing Matrix

### OpenAI

- status: active compatibility route
- reason: the new request path already covers the current bridge-safe legacy subset

### OpenRouter

- status: conservative compatibility route for subset V1
- current blocker:
  - only the plain chat-completions subset is currently frozen
  - OpenRouter search-shaped traffic still remains fallback-only
- legacy-specific concerns:
  - OpenRouter builder behavior currently uses `webSearchConfig`, `searchPrompt`, `useOnlineShortcut`, and the `:online` model suffix shortcut
  - the old implementation mainly preserves search behavior by shaping the model to `:online`, which still does not have a frozen bridge contract
  - some OpenRouter model families such as DeepSeek R1 also rely on provider-specific request shaping such as `include_reasoning`
- current compatibility subset:
  - text-only OpenAI-compatible requests with no OpenRouter-specific search shaping
  - common function tools
  - common structured output
- current recommendation:
  - keep the new conservative OpenRouter subset enabled
  - keep search-shaped OpenRouter requests and OpenRouter DeepSeek R1 requests on legacy fallback

### DeepSeek

- status: conservative compatibility route for subset V1
- current blocker:
  - only the `deepseek-chat` subset is currently frozen
  - `deepseek-reasoner` and DeepSeek-specific legacy extensions still remain fallback-only
- legacy-specific concerns:
  - the old provider has `deepseek-reasoner` specific request restrictions
  - the old provider reads DeepSeek-only legacy extensions such as `logprobs`, `top_logprobs`, `frequency_penalty`, `presence_penalty`, and `response_format`
  - the refactored package now preserves the basic `reasoning_content` path, but not the full DeepSeek-specific legacy option surface
- current compatibility subset:
  - `deepseek-chat` only
  - no DeepSeek-only extensions
  - no `stopSequences`, `serviceTier`, or `user` overrides
  - no legacy message decorators
- current recommendation:
  - keep the new conservative DeepSeek subset enabled
  - keep `deepseek-reasoner` and DeepSeek-specific extensions on legacy fallback until their request policy is frozen

### Groq

- status: conservative compatibility route for subset V1
- current blocker:
  - only the text-and-tool-definition subset is currently frozen
  - tool replay, multimodal traffic, and ignored legacy extras still remain fallback-only
- legacy-specific concerns:
  - the old provider is close to OpenAI wire format, but it does not preserve full prompt-side tool replay and it ignores several root-builder fields such as `stopSequences`, `user`, and `serviceTier`
  - the old provider also carries model-family vision assumptions without a faithful multimodal request encoder
- current compatibility subset:
  - text-only prompts
  - common function tools
  - common tool choice
  - no named messages, no message decorators, and no duplicated system shaping
- current recommendation:
  - keep the conservative Groq subset enabled
  - keep tool replay, multimodal Groq requests, and ignored legacy extras on legacy fallback

### xAI

- status: conservative compatibility route for subset V2
- current blocker:
  - only the text subset and the legacy web/news live-search migration subset are currently frozen
  - xAI prompt-side tool replay and unsupported search shapes still remain fallback-only
- legacy-specific concerns:
  - the old provider exposes `liveSearch` and `searchParameters`
  - the root builder also maps shared `webSearchEnabled` and `webSearchConfig` into xAI-specific search behavior
  - the old provider also carries lossy prompt-side tool replay semantics for tool results
  - xAI also mixes chat, embeddings, and search-oriented capability assumptions in the legacy provider
- current compatibility subset:
  - text-only chat requests
  - common function tools
  - common tool choice
  - typed JSON-schema response format
  - audited legacy live-search migration inputs that normalize into xAI `search_parameters`
  - only the web/news source subset with valid date ranges and supported search modes
- current recommendation:
  - keep the new conservative xAI subset enabled
  - keep prompt-side tool replay, multimodal xAI requests, and unsupported search shapes on legacy fallback

### Phind

- status: new facade only for now
- current blocker:
  - the legacy Phind request body is not a plain chat-completions shape
  - the old response parsing contract is also provider-specific
- legacy-specific concerns:
  - the old Phind provider does not actually behave like a plain OpenAI-compatible chat-completions client
  - the old provider builds a provider-specific request body with fields such as `message_history`, `requested_model`, `user_input`, and extension-oriented flags
  - the old client reparses streaming-style text even for non-streaming requests
  - the legacy code also still carries historical endpoint assumptions that differ from the newer profile default base URL
- earliest safe compatibility subset:
  - none should be assumed without a dedicated Phind request-shape audit
- current recommendation:
  - treat Phind as facade-only in the new architecture
  - do not add a legacy compatibility route until a dedicated Phind audit proves that any subset is worth bridging at all

## 5. Summary Table

| Provider | New `AI` facade | Current legacy compat route | Why it stays off the compat resolver today | First prerequisite |
| --- | --- | --- | --- | --- |
| OpenAI | yes | yes | already has a migrated bridge-safe subset | keep expanding tests |
| OpenRouter | yes | yes, subset only | search-shaped OpenRouter traffic is not frozen | expand the OpenRouter subset only after explicit search audits |
| DeepSeek | yes | yes, subset only | `deepseek-reasoner` and DeepSeek-specific request shapes are still not bridged | expand the DeepSeek subset only after explicit audits |
| Groq | yes | yes, subset only | tool replay, multimodal requests, and ignored legacy extras are still not bridged | audit the next Groq subset explicitly |
| xAI | yes | yes, subset only | prompt-side tool replay and unsupported search shapes are still not frozen | audit the next xAI subset explicitly after the live-search migration subset |
| Phind | yes | no | legacy request format is not plain OpenAI-compatible | dedicated Phind request audit |

## 6. What Must Be Audited Before Expanding Legacy Routing

For each OpenAI-family provider we should freeze:

1. provider-specific legacy extensions that must survive
2. provider-specific model defaults that change request semantics
3. provider-specific response or stream behavior that the old API depends on
4. request shapes that must force fallback immediately
5. the minimal bridge-safe subset that is worth enabling first

If those five items are not explicit, adding a compatibility route is premature.

## 7. Recommended Sequence

1. Keep the root `AI` facade moving first, because it is the new primary API.
2. Keep Phind out of the compatibility resolver until its bridge-safe legacy subset is explicit and tested on top of the new chat-completions mainline.
3. Expand DeepSeek, OpenRouter, Groq, and xAI only one audited subset at a time instead of treating any provider as bridge-safe wholesale.
4. Add one short compatibility audit per OpenAI-family provider.
5. Introduce compatibility routing only for providers whose bridge-safe subset is explicit and tested.
6. Keep old provider subclasses alive for request shapes that remain provider-specific or bridge-incompatible.

## 8. Non-Goals

This document does not propose:

- immediate removal of legacy provider classes
- collapsing all provider-specific behavior into one OpenAI-compatible abstraction
- routing every OpenAI-family provider through the compatibility layer right now

The correct direction is controlled convergence, not forced flattening.
