# Compatibility Test Retention

## Goal

Define which compatibility tests must stay in place until each planned removal
lands.

This prevents the repository from removing legacy leaves and their guardrails
in the same motion.

## Principle

Remove the API first.

Remove the compatibility test only after either:

- the symbol is gone and the test no longer compiles by design, or
- the test has been replaced by a narrower post-removal boundary test

## Wave 1 Removal Groups

### 1. Preset Helper Aliases

Keep until removal lands:

- provider-specific tests that still prove deprecated preset helpers behave as
  documented today
- example: `test/providers/ollama/ollama_thinking_test.dart`
  - still checks that `createOllamaReasoningProvider(...)` produces an
    `OllamaProvider`

What should replace them after removal:

- keep tests for the non-deprecated root provider constructors
- keep tests for the stable provider facades
- delete only the helper-specific assertions

### 2. Builder Web-Search Helpers

Keep until removal lands:

- `test/builder/web_search_builder_test.dart`
- `test/providers/xai/live_search_test.dart`
- the deprecated OpenRouter builder-ergonomics assertions in
  `test/builder/llm_builder_test.dart`

Why these stay:

- they currently prove the deprecated helpers still route into the intended
  compatibility shapes

What should replace them after removal:

- stable provider-owned search tests
- OpenRouter `onlineSearch()` coverage where that helper remains
- provider request-shaping tests that no longer depend on the removed shared
  helper API

### 3. `createProvider(..., extensions: ...)`

Keep until the signature change lands:

- `test/legacy_entrypoint_test.dart`
  - proves `legacy.createProvider(...)` still exists
- factory/config tests that still verify legacy extension routing, especially:
  - `test/providers/openai/openai_factory_test.dart`
  - provider factory/config tests under
    `test/providers/anthropic/`,
    `test/providers/deepseek/`,
    `test/providers/elevenlabs/`,
    `test/providers/ollama/`,
    `test/providers/xai/`

Why these stay:

- they prove that legacy extension data still routes correctly while the raw
  escape hatch remains supported

What should replace them after the signature change:

- keep internal compatibility-factory tests for reading legacy config bags
  where the repository still promises that support
- delete only the public helper-surface assumptions about passing raw
  `extensions` into `createProvider(...)`

### 4. `CancelToken`

Keep until removal lands:

- cancellation coverage in `test/core/cancellation_test.dart`
- root export coverage in `test/ai_entrypoint_test.dart` and any legacy import
  test that still asserts cancellation exports

Why these stay:

- they protect the replacement direction toward `TransportCancellation`

What should replace them after removal:

- only `TransportCancellation` assertions
- updated docs/examples that no longer mention `CancelToken`

## Surfaces That Must Keep Tests Longer

### 1. `ai()`

Even after soft deprecation, keep:

- `test/legacy_entrypoint_test.dart`

Why:

- it proves the deprecated alias still exists until a later removal window

After eventual removal:

- replace it with `LLMBuilder()` export coverage only

### 2. `LLMBuilder`

Keep the builder coverage broadly intact.

Examples:

- `test/builder/llm_builder_test.dart`
- integration tests that still exercise compatibility builder flows

Why:

- the builder trunk remains the real compatibility rail
- removing its test coverage early would be a policy mistake

### 3. `legacy.dart`

Keep:

- `test/legacy_entrypoint_test.dart`
- boundary tests that ensure compatibility exports remain intentionally
  separated from the modern root surface

Why:

- the explicit compatibility import is still a repository-level contract

## Practical Rule For Cleanup PRs

A removal PR should state:

1. which compatibility tests are intentionally deleted
2. which replacement tests remain
3. which trunk-level tests are deliberately preserved

If a PR cannot answer those three points, it is probably trying to remove too
much at once.

## Current Branch Status

On `refactor/architecture-foundation`, the wave-1 leaf-removal slice has
already deleted or narrowed the most directly coupled helper tests:

- the dedicated shared builder web-search test file is removed
- builder/OpenRouter assertions were narrowed to the retained APIs
- deprecated preset-helper-specific coverage was reduced where the helpers were
  removed

At the same time, the trunk guardrails remain:

- `test/legacy_entrypoint_test.dart`
- broad `LLMBuilder` coverage
- compatibility factory/config tests for residual legacy config routing
