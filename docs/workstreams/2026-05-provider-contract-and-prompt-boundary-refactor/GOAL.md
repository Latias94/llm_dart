# Goal

Deliver the next breaking architecture line for `llm_dart` by hardening model
contracts and prompt data boundaries after the first SDK-aligned package split.

## Primary Goal

Make provider contracts consistently implementation-facing and make prompt
input customization explicitly input-side.

This means:

- non-text model contracts use implementation-facing methods:
  - `EmbeddingModel.doEmbed`
  - `ImageModel.doGenerate`
  - `SpeechModel.doGenerate`
  - `TranscriptionModel.doGenerate`
- user-facing calls remain in `llm_dart_ai`:
  - `embed`
  - `embedMany`
  - `generateImage`
  - `generateSpeech`
  - `transcribe`
- prompt message and part customization moves from `ProviderMetadata` to an
  input-side provider options mechanism
- user-facing prompt inputs use `ModelMessage` and normalize into
  provider-facing `PromptMessage` before provider calls
- provider codecs no longer treat `ProviderMetadata` as request configuration
- output parts, stream events, final results, replay details, and UI mappings
  can still expose `ProviderMetadata`
- root and legacy compatibility surfaces stop shaping new contracts

## Non-Goals

This workstream should not:

- copy the full `repo-ref/ai` package graph
- add reranking, video, gateway, skills, or workflow abstractions just for
  reference parity
- flatten provider-native features into common lowest-denominator fields
- remove provider-owned helper clients
- publish `llm_dart_provider_utils` before repeated implementation code proves
  a stable helper boundary
- preserve legacy builder-era APIs as first-class design inputs

## Success Criteria

The workstream is complete only when:

- all provider model contracts use implementation-facing method names
- all AI runtime helper tests call user-facing helpers, not provider methods,
  except focused provider-contract tests
- guards reject old non-text provider method names in package `lib/` code
- `PromptPart.providerMetadata` is no longer the supported request
  customization path
- Anthropic cache control and similar input controls use input-side provider
  options
- provider codecs distinguish input-side options from output-side metadata
- prompt normalization validates missing tool results before provider calls
- migration docs provide before/after examples
- package-local analysis and tests pass for provider, AI runtime, provider
  packages, chat, Flutter, root, and compatibility tests that remain in scope
