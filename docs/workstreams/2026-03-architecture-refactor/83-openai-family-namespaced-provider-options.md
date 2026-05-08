# OpenAI Family Namespaced Provider Options

## Goal

This note records the first concrete migration step away from the flat
compatibility-era `LLMConfig.extensions` pattern for the OpenAI family.

The goal is not to remove the old keys immediately. The goal is to introduce a
safer internal transition toward a `repo-ref/ai`-style `providerOptions`
boundary while preserving current root-package behavior.

## 1. Why Start With The OpenAI Family

The OpenAI family is the highest-value place to start because it has:

- the largest concentration of flat extension-backed provider options
- the most overlap between builder helpers, request encoders, factories, and
  compatibility routing
- the closest conceptual match to the `providerOptions` shape in `repo-ref/ai`

That makes it the best provider family for proving the transition pattern
before considering other namespaces.

## 2. Landed Transitional Shape

The compatibility root package now has an internal staged bag:

- `extensions['providerOptions']['openai'][key]`
- `extensions['providerOptions']['openrouter'][key]`
- `extensions['providerOptions']['deepseek'][key]`
- `extensions['providerOptions']['xai'][key]`
- the same provider-owned bag shape is also used by the remaining
  provider-specific compatibility builders such as Google, Anthropic, Ollama,
  and ElevenLabs

This bag is still a compatibility-layer implementation detail. It is not yet
the final stable public configuration design for the long-term API.

## 3. Landed Read/Write Rule

The transition rule for the OpenAI family is now:

- OpenAI-specific builder helpers write into `providerOptions.openai`
- OpenRouter-specific legacy search helpers write into
  `providerOptions.openrouter`
- DeepSeek-specific builder helpers write into `providerOptions.deepseek`
- xAI-specific builder helpers write into `providerOptions.xai`
- readers in factories, request shaping, and compatibility providers read
  namespaced options first
- those readers still fall back to the old flat extension keys

This keeps the migration low-risk:

- new internal writes stop widening the flat key surface
- old direct `extensions['someKey']` callers still work during the migration
- compatibility routing can accept only the audited namespaced subset instead
  of blindly allowing any bag contents

## 4. Landed Coverage

The first namespaced migration slice now covers these OpenAI-family areas:

- OpenAI builder options such as `useResponsesAPI`, `previousResponseId`,
  `parallelToolCalls`, `builtInTools`, `verbosity`, `frequencyPenalty`,
  `presencePenalty`, `logitBias`, `seed`, `logprobs`, `topLogprobs`, and
  OpenAI `webSearchConfig`
- OpenRouter legacy search config through namespaced
  `providerOptions.openrouter.webSearchConfig`
- OpenRouter and Ollama structured-output compatibility builder callbacks
- DeepSeek builder options such as `logprobs`, `top_logprobs`,
  `frequency_penalty`, `presence_penalty`, and `response_format`
- xAI builder options such as `liveSearch`, `searchParameters`,
  structured output, and embedding dimensions
- OpenAI and OpenAI-compatible factory reads
- OpenAI chat and Responses request shaping
- OpenAI-family compatibility provider adapters
- OpenAI / OpenRouter compatibility route allowlists
- removal of the broad root `LLMBuilder.legacyExtension(...)` write path in
  favor of provider-specific callback methods

## 5. What Still Intentionally Falls Back

This change does not claim that every old OpenAI-family option is now bridge
compatible or newly stable.

The old `ProviderConfig` map builder was later removed during the architecture
foundation cleanup. Provider-specific builder callbacks and typed provider
options now own these knobs instead of a broad raw-extension shell.

Examples:

- unsupported OpenRouter legacy search helper keys still remain fallback-only
- flat keys still remain readable during the migration window
- the shared root `LLMBuilder.webSearch(...)` helper still writes the old flat
  compatibility search config because it is a cross-provider migration entry,
  not an OpenAI-owned stable option surface
- generic legacy adapter fallback can still read flat `jsonSchema` so it can
  normalize old structured-output requests into shared `responseFormat`
- Groq and Phind still do not have provider-specific callback surfaces because
  their current root compatibility adapters do not expose stable extra knobs

## 6. Why This Matches The Reference Better

The important alignment with `repo-ref/ai` is boundary direction, not package
count:

- provider-specific invocation options start moving under provider-owned
  namespaces
- compatibility gating can reason about provider-owned option subsets
- request encoders stop depending on scattered string literals alone

This is still only a transition layer, but it meaningfully reduces one of the
root package's structural coupling hotspots.

## 7. Recommended Next Step

After this migration slice, the next valuable OpenAI-family steps are:

- audit whether more OpenRouter legacy search controls should stay fallback-only
  forever or be removed entirely
- decide whether the remaining flat `jsonSchema` fallback should stay as a
  generic legacy adapter input or move behind a provider-aware response-format
  resolver
- keep pressure on moving long-term app-facing usage toward the stable package
  APIs instead of expanding the root compatibility builder surface
