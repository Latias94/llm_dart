# 173 Cross-Provider Support Propagation Audit

## Why This Audit Exists

The recent OpenAI extraction rounds established a clearer internal shape:

- shared streaming support
- endpoint-local codec support
- language-model request-planning support

That shape is valuable, but it should not automatically become a symmetry rule
for every provider package. This audit checks whether the same extraction
pressure exists in Anthropic and Google before we propagate the pattern.

## Audit Scope

This pass looked at the currently active modern provider packages that are most
similar to the OpenAI-family text path:

- `packages/llm_dart_anthropic/lib/src/anthropic_language_model.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_result_codec.dart`
- `packages/llm_dart_anthropic/lib/src/anthropic_stream_codec.dart`
- `packages/llm_dart_google/lib/src/google_language_model.dart`
- `packages/llm_dart_google/lib/src/google_result_codec.dart`
- `packages/llm_dart_google/lib/src/google_stream_codec.dart`

The question is not whether every provider can be split. The question is where a
split would actually improve ownership and future maintenance.

## Key Decision

The OpenAI support split is a **reference pattern**, not a required provider
template.

We should only propagate support modules when all of the following are true:

- facade-level files still mix transport orchestration with pure preparation or
  projection helpers
- the extracted logic has a coherent local ownership boundary
- the resulting support file reduces future drift between at least two adjacent
  code paths
- the split does not create fake cross-provider symmetry with no practical gain

## Anthropic Findings

### Language Model

`anthropic_language_model.dart` is already relatively small and reads mostly as
a transport facade.

The remaining local helpers are narrow:

- `_resolveProviderOptions`
- `_buildRequestHeaders`
- `countTokens(...)`

That is not enough pressure to justify a dedicated
`anthropic_language_model_support.dart` right now.

### Codec Pair

`anthropic_result_codec.dart` and `anthropic_stream_codec.dart` do contain
repeated helper logic, especially around:

- `_decodeUsage`
- `_decodeContainer`
- `_providerMetadata`
- `_decodeCitationSource`

That repetition suggests a possible future codec-local support file, but the
value is still conditional. The repeated logic is real, yet it is not currently
the main architectural bottleneck.

### Anthropic Recommendation

- do **not** force an Anthropic language-model support split now
- only consider an Anthropic codec-local shared support module when a future
  feature or bug-fix touches both result and stream projection together
- keep Anthropic provider-local and pragmatic instead of aligning it to OpenAI
  for appearance alone

## Google Findings

### Language Model

`google_language_model.dart` still carries a visible preparation layer mixed
into the facade:

- `_resolveProviderOptions`
- `_buildRequestHeaders`
- `_decodeJsonObject`
- `_normalizedBaseUrl`
- `_resolveSharedResponseFormat`

This is a better match for the OpenAI language-model support extraction than
Anthropic is.

### Result And Stream Projection

The stronger structural signal is actually the Google result/stream pair.

`google_result_codec.dart` and `google_stream_codec.dart` repeat or closely
mirror logic around:

- thought-signature provider metadata
- `functionCall.id` provider metadata
- `code_execution` tool call and result projection
- grounding source extraction based on `extractGroundingSources(...)`

That shared projection pressure is more valuable than creating a perfectly
parallel provider folder layout.

### Google Recommendation

- prefer a `google_language_model_support.dart` extraction as the next small
  facade-thinning step
- then evaluate a Google codec-local shared projection support module for
  grounding, thought signatures, and `code_execution` ownership
- treat the Google codec projection support as structurally more valuable than a
  cosmetic provider-wide support split

## Event-Surface Implication

This audit does **not** justify widening shared core events.

The current Google and Anthropic gaps are mostly about provider-local request
preparation and provider-local projection reuse, not about missing shared event
families. Any richer provider-native projection should continue to stay
provider-owned unless two provider families prove the same stable shared
contract.

## Recommended Sequencing

1. Keep the OpenAI extraction result as the current mature reference.
2. Extract `google_language_model_support.dart`.
3. Evaluate Google shared projection support for result/stream codec reuse.
4. Revisit Anthropic codec-local support only when a real multi-file change
   creates pressure there.
5. Do not create an Anthropic language-model support file unless the current
   ownership profile materially changes.

## Non-Goals

This audit does not:

- require every provider package to expose the same file names
- introduce a generic cross-provider support framework
- widen the shared stream-event surface
- move provider-native behavior into the core only for consistency

## Frozen Outcome

The architecture direction is now clearer:

- OpenAI remains the most support-layered provider package because it needs it
- Google is the next justified target for selective propagation
- Anthropic should stay simpler until a concrete codec change proves otherwise
- cross-provider consistency should be measured by boundaries and dependency
  direction, not by identical file topology
