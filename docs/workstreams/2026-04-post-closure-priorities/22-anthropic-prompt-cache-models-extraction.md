# Anthropic Prompt Cache Models Extraction

## Why This Cut Was Worth Doing

`lib/src/compatibility/providers/anthropic/models.dart` mixed two unrelated
responsibility groups:

- prompt-cache message-builder helpers and provider-specific content blocks
- Anthropic model-listing capability orchestration

Both belonged to the Anthropic compatibility area, but they did not belong in
the same implementation file. The cache helpers are message-shaping extensions,
while `AnthropicModels` is an API capability module.

The better ownership boundary is:

- `anthropic_prompt_cache_models.dart` owns Anthropic prompt-cache message
  helpers
- `models.dart` keeps the model-listing capability and re-exports the cache
  helpers to preserve the legacy public import path

## What Changed

Added:

- `lib/src/compatibility/providers/anthropic/anthropic_prompt_cache_models.dart`

Kept as the public compatibility model-listing module:

- `lib/src/compatibility/providers/anthropic/models.dart`

The prompt-cache file now owns:

- `AnthropicCacheControl`
- `AnthropicCacheTtl`
- `AnthropicTextBlock`
- `AnthropicToolsBlock`
- `AnthropicMessageBuilder`
- `AnthropicMessageBuilderExtension`

The models file now stays focused on:

- `AnthropicModels`
- model-listing endpoint construction
- model retrieval
- preserving `package:llm_dart/providers/anthropic/models.dart` as the
  compatibility export path for prompt-cache helpers

## Why This Boundary Is Better

This keeps the root compatibility surface stable while reducing conceptual
coupling inside the Anthropic provider implementation.

It also matches the broader refactor rule:

- provider-specific message helpers stay provider-local
- API capability modules own endpoint orchestration
- legacy import paths can remain stable during the fearless refactor

## Validation

The refactor was validated with targeted checks:

- `dart analyze lib/src/compatibility/providers/anthropic/models.dart lib/src/compatibility/providers/anthropic/anthropic_prompt_cache_models.dart test/providers/anthropic/anthropic_prompt_cache_models_test.dart`
- `dart test test/providers/anthropic/anthropic_prompt_cache_models_test.dart`
- `dart test test/providers/anthropic`
- `dart run tool/check_workspace_dependency_guards.dart`
- `dart run tool/check_root_package_boundary_guards.dart`
