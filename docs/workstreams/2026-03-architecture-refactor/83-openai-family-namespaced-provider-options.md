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

This bag is still a compatibility-layer implementation detail. It is not yet
the final stable public configuration design for the long-term API.

## 3. Landed Read/Write Rule

The transition rule for the OpenAI family is now:

- OpenAI-specific builder helpers write into `providerOptions.openai`
- OpenRouter-specific legacy search helpers write into
  `providerOptions.openrouter`
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
- the legacy `ProviderConfig` helper for OpenAI-family tuning, which now emits
  namespaced option bags instead of fresh flat OpenAI keys
- OpenRouter legacy search config through namespaced
  `providerOptions.openrouter.webSearchConfig`
- OpenAI and OpenAI-compatible factory reads
- OpenAI chat and Responses request shaping
- OpenAI-family compatibility provider adapters
- OpenAI / OpenRouter compatibility route allowlists

## 5. What Still Intentionally Falls Back

This change does not claim that every old OpenAI-family option is now bridge
compatible or newly stable.

Examples:

- unsupported OpenRouter legacy search helper keys still remain fallback-only
- flat keys still remain readable during the migration window
- the shared root `LLMBuilder.webSearch(...)` helper still writes the old flat
  compatibility search config because it is a cross-provider migration entry,
  not an OpenAI-owned stable option surface
- shared fields like `jsonSchema` are still not moved into provider namespaces
- other OpenAI-compatible providers still mainly rely on the old flat path

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
- decide whether any additional OpenAI-family option groups deserve typed
  helper accessors above the transitional bag
- keep pressure on moving long-term app-facing usage toward the stable package
  APIs instead of expanding the root compatibility builder surface
