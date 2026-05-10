# TODO

## Workstream Setup

- [x] Create the modern unified interface workstream scaffold
- [x] Define the product goal and non-goals
- [x] Document first-pass interface gaps
- [x] Document the `ModelRegistry` design

## Model Registry

- [x] Add a provider-agnostic `ModelRegistry` to `llm_dart_provider`
- [x] Support language, embedding, image, speech, and transcription model kinds
- [x] Resolve model references in `provider:modelId` form
- [x] Allow model IDs to contain additional colons after the provider separator
- [x] Reject invalid references and provider IDs with clear errors
- [x] Expose registered provider IDs for diagnostics and UI selection
- [x] Add focused tests for registry resolution and failure cases

## Modern Interface Audit

- [x] Record that the modern surface lacks first-class dynamic model selection
- [x] Record that object generation and stream object APIs are not yet
  first-class
- [x] Record that transport serialization needs a `CallOptions` and
  `providerOptions` follow-up
- [x] Record that examples still need a final legacy import pass
- [x] Record that stream part alignment needs a dedicated design pass

## Follow-Up Implementation

- [x] Add first-class `generateObject` and `streamObject` helpers if the
  current structured-output support is not ergonomic enough
- [x] Align `HttpChatTransport` protocol serialization with serializable
  `CallOptions`
- [x] Audit stream events against app-level UI and provider-native custom parts
- [x] Update root README and example index docs to teach `ModelRegistry` and
  object-first structured output
- [x] Update structured-output examples to prefer `generateObject` and
  `streamObject`
- [x] Update examples to prefer `ModelRegistry` where dynamic provider
  selection is the actual use case
- [x] Keep `LLMBuilder` examples behind explicit legacy positioning

## Validation

- [x] Run focused `llm_dart_provider` tests after registry implementation
- [x] Run `llm_dart_provider` analysis after registry implementation
- [x] Run focused `llm_dart_chat` protocol and transport tests after call
  options serialization
- [x] Run `llm_dart_chat` analysis after call options serialization
- [x] Run focused `llm_dart_ai` structured output tests after
  `generateObject` and `streamObject`
- [x] Run `llm_dart_ai` analysis after `generateObject` and `streamObject`
- [x] Run focused structured-output example analysis after object-first update
- [x] Run focused provider-comparison example analysis after `ModelRegistry`
  update
- [x] Run no-key consumer smoke for updated getting-started and structured
  output examples
- [x] Re-run docs and examples review before release readiness is claimed
- [x] Run full release readiness with tests, consumer smoke, publish dry-run,
  and pub version availability before release readiness is claimed
