# Provider Utility Audit

## Scope

This audit covers the first M5 utility consolidation pass after the prompt and
replay boundary changes. The goal is to decide whether repeated provider helper
code has a stable shared owner, not to extract every small local helper by
default.

## Findings

`SerializationJsonSupport` is now provider-owned. `llm_dart_ai` reuses it for
provider contract values and keeps only UI-specific serialization in
`ChatUiJsonCodec`.

Provider metadata namespace extraction has one owner:
`ProviderMetadata.namespace()`. OpenAI Responses and Google GenerateContent no
longer carry duplicate namespace helper functions for replay metadata.

Strict JSON contract validation is already owned by `llm_dart_provider` through
`json_codec_common.dart`. These helpers are appropriate for serialized library
contracts, where invalid shapes should throw with a path.

Provider response projection helpers such as tolerant string/list/map coercion
still vary by provider and by endpoint. OpenAI, Google, Anthropic, Ollama, and
ElevenLabs all parse different vendor response shapes and use different
fallback behavior. These helpers are not yet a stable public utility contract.

## Decision

Do not publish `llm_dart_provider_utils` in this pass.

Use the existing provider foundation for stable cross-provider contracts:

- strict JSON serialization and validation helpers
- provider metadata namespace access
- provider references, warnings, errors, usage, prompt, content, tool, and
  stream contract serialization

Keep provider response projection package-local until the exact behavior is
stable across multiple providers. Package-local consolidation is acceptable
when several files inside one provider package share the same response shape.

Create a new public provider utility package only when helpers would otherwise
pollute `llm_dart_provider` foundation with concrete implementation behavior
and have a documented, provider-agnostic contract.

## Follow-Up Criteria

Revisit a utility package if at least three provider packages need identical
helpers for the same behavior, such as:

- tolerant vendor response projection with the same null/fallback semantics
- media type and data URL normalization shared by request codecs
- provider reference resolution shared by multimodal codecs
- stream event assembly shared by multiple provider implementations
- schema lowering that is not specific to one provider family

Until then, avoid public utility surface area and prefer small provider-local
helpers.
