# Provider Registry And OpenAI-Family Rebaseline

## Decision

Reopen this workstream as the active fearless refactor line for the provider
object model, provider registry, and OpenAI-family boundary. Do not start a
parallel workstream for the same architecture topic.

The package split is already mostly aligned with the lessons from
`repo-ref/ai`. The next useful breaking change is not more package chopping.
The next useful change is to make provider identity, provider-owned model
facets, registry lookup, OpenAI-compatible provider profiles, typed provider
options, and compatibility barrels explicit enough that the architecture can
keep evolving without central coupling.

## Source Findings

- `llm_dart_provider` already owns provider-facing model contracts such as
  `LanguageModel`, `EmbeddingModel`, `ImageModel`, `SpeechModel`, and
  `TranscriptionModel`.
- `ModelRegistry` is currently a per-capability factory registry. It can
  resolve `provider:modelId` references, but it does not model a provider as a
  first-class object with all of its model facets and native capabilities.
- Concrete provider packages already have provider-shaped facades. For example,
  `OpenAI` can create language, embedding, image, speech, transcription,
  moderation, files, assistants, and responses lifecycle clients.
- The reference AI SDK models provider identity as a provider object with model
  factory methods, then builds a registry over provider instances. That shape is
  useful even though Dart should not copy TypeScript overloads or generic tricks
  literally.
- The OpenAI-family implementation deliberately reuses one adapter for OpenAI,
  OpenRouter, DeepSeek, Groq, xAI, Phind, and future compatible providers. That
  reuse is valuable, but profile-specific option routing is now concentrated in
  shared OpenAI resolver code.
- Typed Dart provider options are a library strength. The gap is not that they
  exist. The gap is that composition, precedence, and profile-specific rejection
  need to be standardized so provider-specific features do not turn into a
  central conditional hub.
- `llm_dart_core` is now a compatibility barrel. It should not receive new
  architectural ownership.

## Target Architecture

### Provider Object Model

Add a provider object contract to `llm_dart_provider`.

The Dart shape should favor explicit capability interfaces over TypeScript-style
optional methods:

```dart
abstract interface class Provider {
  String get providerId;
}

abstract interface class LanguageModelProvider implements Provider {
  LanguageModel languageModel(String modelId);
}

abstract interface class EmbeddingModelProvider implements Provider {
  EmbeddingModel embeddingModel(String modelId);
}
```

Direct provider facades can keep richer typed settings on their concrete
methods. The shared registry-facing contract intentionally stays narrower so it
does not force `GoogleChatModelSettings`, `AnthropicChatModelSettings`, and
other typed settings to collapse into untyped base options.

The ownership rule should not change: provider contracts belong in
`llm_dart_provider`, concrete providers implement the facets they support, and
provider-native product clients stay provider-owned unless a stable
cross-provider contract is proven.

### Provider Registry

Replace or wrap `ModelRegistry` with a provider-object registry.

The registry should:

- register provider instances by validated provider id
- resolve `provider:modelId` references using one shared parser
- expose model lookups such as `languageModel('openai:gpt-4.1-mini')`
- fail with precise unsupported-provider or unsupported-model-kind errors
- leave provider-specific model settings on direct provider facade methods
- keep runtime middleware, tool-loop orchestration, and output parsing outside
  the provider foundation

`ModelRegistry` should either become a compatibility adapter over the new
registry or be removed in the same breaking line with a migration entry.

### OpenAI-Family Boundary

Keep the shared OpenAI-compatible wire implementation, but stop making one
central resolver own every family-specific decision.

The preferred direction is:

- each family facade has a stable provider identity, even if it reuses the
  common OpenAI-compatible transport and codecs
- profile-specific model settings and invocation options resolve through a
  profile-owned strategy instead of a growing `if providerId == ...` switch
- shared OpenAI options remain common only when they are truly supported by the
  shared wire contract
- OpenRouter, DeepSeek, xAI, and future family-specific options remain typed and
  provider-owned
- route selection between Responses and Chat Completions stays an OpenAI-family
  implementation detail, not a registry concern

This keeps the useful "OpenAI-compatible family" reuse while preventing the
OpenAI package from becoming the central policy engine for every compatible
provider.

### Provider Options Policy

Keep typed provider options. Standardize how they compose.

Rules to enforce during the refactor:

- shared runtime options own cross-provider semantics
- provider model settings own model construction defaults
- provider invocation options own request-specific provider-native behavior
- provider prompt-part options own provider-specific encoding of individual
  prompt parts and replay metadata
- when shared options and provider options target the same provider wire field,
  either define one canonical owner or throw a clear conflict error
- profile-specific options must be rejected by the wrong provider before request
  encoding
- raw map escape hatches should not become the default extension mechanism

### Compatibility And Core

`llm_dart_core` stays a compatibility shell:

- no new architectural APIs are added there
- new provider and registry contracts are exported from their owning package
- root `llm_dart` may re-export modern convenience APIs, but must not own the
  provider object model
- migration docs must state whether `ModelRegistry` and `llm_dart_core` are
  deleted, adapted, or frozen for the next breaking line

## What To Preserve

- unified model-first runtime helpers
- direct provider model construction for advanced users
- typed provider model, invocation, and prompt-part options
- provider capability profiles
- provider-native helper clients
- OpenAI-compatible provider reuse
- runtime/provider stream separation
- framework-neutral chat and Flutter adapters staying independent from concrete
  provider packages

## Non-Goals

- Do not copy TypeScript provider overloads literally.
- Do not split every OpenAI-compatible provider into a separate package just to
  mirror another repository.
- Do not flatten provider-native clients into weak shared abstractions before a
  real common contract exists.
- Do not publish `llm_dart_provider_utils` as part of this rebaseline unless a
  stable public utility contract is separately proven.
- Do not add new APIs to `llm_dart_core`.

## Implementation Slices

1. Add provider object contracts and focused tests in `llm_dart_provider`.
2. Introduce a provider-object registry and migrate `ModelRegistry` behavior or
   deprecate/remove it explicitly.
3. Implement provider facets in concrete provider facades, starting with OpenAI,
   Anthropic, Google, and Ollama.
4. Refactor OpenAI-family option/profile resolution into profile-owned strategy
   objects or small provider-owned resolvers.
5. Update root facade and examples to prefer provider-object registry usage
   where dynamic model lookup is needed.
6. Add dependency and import guards so provider packages do not depend on AI
   runtime, root, chat, Flutter, or compatibility barrels.
7. Update migration docs for the new registry, `ModelRegistry`, and
   `llm_dart_core` posture.

## Acceptance Criteria

- A shared `Provider` object model exists in the provider foundation.
- Dynamic model lookup registers provider instances, not independent
  per-capability factory maps.
- Provider-native helper clients remain available from concrete provider
  facades.
- OpenAI-family providers retain shared wire-code reuse while moving
  family-specific option policy out of one central resolver.
- Typed provider options have documented conflict and precedence rules.
- `ModelRegistry` has a deliberate compatibility, deprecation, or removal
  outcome.
- `llm_dart_core` remains frozen or receives a documented exit path.
- Tests and guards prevent the old registry and OpenAI-family coupling from
  silently returning.
