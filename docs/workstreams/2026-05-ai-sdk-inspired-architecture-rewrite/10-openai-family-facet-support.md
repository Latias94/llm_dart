# OpenAI-Family Facet Support

## Decision

Keep one shared OpenAI-family facade implementation, but make registry-visible
model facet support profile-specific.

The OpenAI-family adapter remains a deep module for shared OpenAI-compatible
wire behavior. Its registry interface now exposes a separate facet-support seam
so provider identity does not imply every OpenAI model kind is available.

## Problem

`OpenAI` is intentionally reused by OpenAI, OpenRouter, DeepSeek, Groq, xAI,
and Phind. That reuse preserved locality for codecs, transport, route
selection, typed options, and helper clients, but it made provider-registry
capability reporting too shallow: the class implemented language, embedding,
image, speech, and transcription provider interfaces, so every OpenAI-family
profile looked like it supported every model kind.

That was accurate for OpenAI, but misleading for compatible chat providers such
as OpenRouter, DeepSeek, Groq, xAI, and Phind.

## Implemented Shape

- `llm_dart_provider` now exposes `ProviderModelFacetSupport`.
- `ProviderRegistry` still detects legacy/custom providers by implemented
  model-provider interfaces.
- When a provider also implements `ProviderModelFacetSupport`, the registry
  respects the provider-declared support bits before listing providers or
  resolving a model reference.
- `OpenAI` implements `ProviderModelFacetSupport`.
- `OpenAIProfile` advertises language, embedding, image, speech, and
  transcription facets.
- OpenRouter, DeepSeek, Groq, xAI, and Phind currently advertise only the
  language facet through the shared OpenAI-family facade.
- Direct unsupported model-facet methods on a non-OpenAI family profile throw
  `UnsupportedError` with a profile-specific message.

## Registry Policy

The registry-facing interface remains intentionally narrower than concrete
provider facades:

- provider packages keep typed settings on direct methods
- provider-native clients remain available from concrete provider objects
- dynamic lookup uses shared model-reference strings and common model contracts
- unsupported model kinds fail before constructing a misleading model object

This gives application code leverage from dynamic lookup while preserving
locality for provider-specific behavior.

## Migration Notes

Code that registers OpenAI-family compatible providers in `ProviderRegistry`
may see provider lists become more precise:

- `openRouter`, `deepseek`, `groq`, `xai`, and `phind` remain language-model
  providers.
- Those profiles no longer appear in embedding, image, speech, or transcription
  provider lists unless their profile facet support is explicitly expanded.
- `registry.embeddingModel('openrouter:...')` now throws `UnsupportedError`
  instead of constructing an unsupported OpenAI embedding model.

If a compatible provider adds a real embedding, image, speech, or transcription
surface later, expand its `OpenAIFamilyModelFacetSupport` profile entry and add
provider-specific tests at the same seam.

## Verification

- `dart test` in `packages/llm_dart_provider`
- `dart test test/openai_entrypoint_test.dart` in `packages/llm_dart_openai`
- `dart test test/provider_registry_facade_test.dart` at the repository root
- `dart analyze` in `packages/llm_dart_provider`
- `dart analyze` in `packages/llm_dart_openai`
- `dart analyze` at the repository root

These tests cover provider-declared facet support, OpenAI-family entrypoint
behavior, root facade registry provider lists, and unsupported OpenRouter
embedding lookup.

## Remaining Risks

The facet map is deliberately conservative for non-OpenAI profiles. It avoids
false positives, but it may need to grow when a compatible provider exposes a
stable non-text API through the same OpenAI-compatible wire contract.
