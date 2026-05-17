# OpenAI-Family Option Resolver

## Decision

Move OpenAI-family model-settings, invocation-options, and request-model-id
policy out of the language model support path and into a dedicated resolver
strategy boundary.

This keeps the shared OpenAI-compatible codecs and transport path, but prevents
`openai_language_model_support.dart` from becoming the central conditional hub
for every compatible provider.

## Implemented Shape

- `openai_family_option_resolver.dart` owns family-specific option resolution.
- `openai_language_model_support.dart` delegates to
  `openAIFamilyOptionResolverFor(profile)`.
- OpenRouter owns online-model request id shaping through the resolver.
- DeepSeek owns its response-format conflict behavior through the resolver.
- xAI owns live-search invocation options through the resolver.
- Common OpenAI options remain accepted across OpenAI-family profiles when they
  target shared wire behavior.

## Typed Option Policy

- Direct provider facades keep typed model settings.
- Shared `GenerateTextOptions.responseFormat` and
  `OpenAIGenerateTextOptions.responseFormat` still conflict clearly.
- `DeepSeekGenerateTextOptions.responseFormat` still conflicts with shared or
  OpenAI JSON-schema response formats.
- Profile-specific invocation options fail before request encoding when used on
  the wrong family profile.
- Model-level built-in tools still provide defaults when invocation options do
  not set them.
- The provider registry does not own provider-specific model settings; direct
  provider facade methods remain the typed customization path.

## Verification

- `dart analyze` in `packages/llm_dart_openai`
- `dart test test/openai_family_profile_test.dart`
- `dart test test/openai_chat_completions_mainline_test.dart`
- `dart test test/openai_model_describer_test.dart`

These tests cover OpenRouter request-model shaping, wrong-provider option
rejection, DeepSeek options, xAI live-search options, and model capability
description behavior that depends on profile-specific settings.

## Remaining Risks

The previously noted class-level model-facet reporting risk is closed by
`10-openai-family-facet-support.md`: the shared `OpenAI` facade now declares
profile-specific model facet support to `ProviderRegistry`.

The remaining risk is data freshness, not architecture shape. Non-OpenAI
profiles are conservative language-only adapters until a compatible provider
has a tested non-text surface.
