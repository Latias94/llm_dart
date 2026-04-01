# Config Decomposition

## Goal

This note records the decomposition of the shared `core/config.dart` file
without changing the public configuration API.

The goal was narrow:

- keep `LLMConfig`, `OpenAICompatibleProviderConfig`, and transformer types
  stable
- separate the unified config model, private config helpers,
  OpenAI-compatible provider configuration, and transformer contracts
- reduce one of the remaining root-package coupling hotspots without changing
  runtime behavior

## 1. Why `core/config.dart` Was Worth Doing Next

After the builder, compatibility bridge, and shared model decompositions,
`core/config.dart` was still one of the highest-value residual hotspots.

Before this slice it mixed:

- the shared `LLMConfig` model
- JSON serialization and tool-choice parsing logic
- equality helper logic
- OpenAI-compatible provider profile configuration
- model-capability overrides
- provider request/header transformer contracts

Those concepts are tightly related, but they do not belong in one source block.

## 2. Frozen Decomposition Rule

This slice keeps the public configuration surface stable:

- no rename of public configuration types
- no constructor or factory signature changes
- no JSON key changes
- no change to `copyWith`, extension handling, or equality behavior
- no movement of provider-specific request shaping back into the shared config
  layer

The change is purely an internal source decomposition.

## 3. Landed Split

The main `core/config.dart` file is now reduced to the library shell plus
same-library parts:

- `config_llm_config.dart`
- `config_llm_config_support.dart`
- `config_openai_compatible_provider.dart`
- `config_transformers.dart`

This maps better to the actual ownership boundaries:

- shared config state stays separate from private codec/equality helpers
- OpenAI-compatible provider profiles stop competing with `LLMConfig`
- model-capability override objects stay near provider-profile definitions
- transformer contracts stay isolated from config value-model concerns

## 4. Why This Matters Architecturally

`LLMConfig` is one of the most widely referenced compatibility-era types in the
root package. Keeping it readable matters because it sits at the intersection
of:

- builder composition
- provider factory validation
- request-shaping utilities
- OpenAI-compatible profile defaults
- compatibility bridging

This split reduces local coupling while preserving the current compatibility
surface, which is consistent with the broader “shrink the root package without
breaking callers” strategy.

## 5. Validation

This slice was validated with:

- `dart analyze lib/core/config.dart lib/core/config_llm_config.dart lib/core/config_llm_config_support.dart lib/core/config_openai_compatible_provider.dart lib/core/config_transformers.dart test/core/config_test.dart test/core/tool_validator_test.dart test/builder/llm_builder_test.dart`
- `dart test test/core/config_test.dart test/core/tool_validator_test.dart test/builder/llm_builder_test.dart`

## 6. Next Step

After `core/config.dart`, the remaining root-package cleanup is less about bus
files and more about semantic tightening:

- continue auditing config-adjacent helper placement
- revisit remaining shared/legacy model hotspots such as `image_models.dart`
  and `file_models.dart`
- keep pushing provider-owned shaping out of generic compatibility layers
