# Priority Map

## P0 - Publish Handoff Stop Condition

Do not start broad provider-internal decomposition while the local alpha line is
still waiting on a maintainer publish action.

Required evidence before implementation slices:

- final release readiness passes locally
- packages are published in dependency order or publishing is explicitly
  deferred by the maintainer
- clean consumer smoke can run against local packages and has a documented
  published-package follow-up

This workstream may document plans before publish, but implementation should
not destabilize the release handoff unless a release blocker appears.

## P1 - Provider Codec Hotspot Reduction

Start with the largest and most actively risky provider implementation files:

1. `packages/llm_dart_openai/lib/src/openai_responses_codec.dart`
2. `packages/llm_dart_anthropic/lib/src/anthropic_messages_codec.dart`
3. `packages/llm_dart_openai/lib/src/openai_assistants.dart`
4. `packages/llm_dart_openai/lib/src/openai_chat_completions_codec.dart`
5. `packages/llm_dart_anthropic/lib/src/anthropic_stream_codec.dart`
6. `packages/llm_dart_google/lib/src/google_generate_content_codec.dart`
7. `packages/llm_dart_ollama/lib/src/ollama_language_model.dart`

Default decomposition order:

- request encoding / body builders
- response decoding / result projection
- stream parser state
- provider-native tool and replay support
- provider-native custom parts and metadata projection
- facade orchestration only after helpers exist

Stop condition:

- if a split would mostly rename private functions without lowering ownership
  coupling, document the reason and leave the file intact for now.

## P1 - Fixture-Based Provider Tests

Every provider-internal split should strengthen tests rather than rely on line
movement.

Preferred tests:

- request body snapshots or structural JSON assertions
- response fixture decoding
- stream event fixture decoding
- replay continuation fixture encoding
- provider option mapping warnings/errors
- provider metadata namespace assertions

Stop condition:

- do not split a codec module unless tests prove the new helper boundary through
  public or package-private behavior.

## P2 - Internal Provider Implementation Kit

Introduce shared helpers only after duplication is concrete.

Candidate helper categories:

- JSON-safe normalization and validation
- schema normalization
- provider-reference resolution
- media-type and file-data helpers
- warning and error mapping support
- streaming tool-call accumulation
- fixture and mock transport helpers for tests

Excluded helper categories:

- Dio, retry, SSE, multipart, or HTTP transport ownership
- AI runtime orchestration
- chat or Flutter state
- provider-native lifecycle APIs
- broad provider base classes

## P2 - Public `llm_dart_provider_utils` Decision

Keep `llm_dart_provider_utils` unintroduced until there is enough evidence.

Public extraction can be considered only when:

- at least two provider packages need the same stable helper contract
- the helper has no transport/runtime/chat/Flutter ownership
- the helper is tested independently
- the migration cost of keeping duplicate provider-local helpers is higher than
  the cost of publishing and supporting another package

Default decision:

- keep helpers package-private or provider-local during this workstream unless
  the evidence is strong.

## P3 - Provider-Native Feature Expansion

Provider-native features should remain provider-owned.

Prefer:

- typed provider options
- provider-owned helper clients
- custom parts and summaries
- capability descriptors
- focused provider package docs

Avoid:

- common abstractions for one-provider features
- widening shared stream events for isolated provider needs
- hiding provider-specific request semantics behind generic maps
