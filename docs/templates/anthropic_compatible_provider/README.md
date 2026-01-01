# Anthropic-compatible Provider Template (Monorepo)

This folder is a **copy/paste template** for adding a new provider that speaks
the Anthropic Messages wire format (or a close compatibility layer), following
the pattern used by `llm_dart_minimax`.

## What you get

- A provider package skeleton: `PACKAGE/`
  - factory + registry (`registerXxx`)
  - `createXxxProvider(...)` convenience constructor
  - thin `XxxChat extends AnthropicChat` wrapper
- A root test skeleton: `ROOT_TESTS/`
  - factory tests
  - protocol conformance tests (shared suite)

## How to use

1. Copy the package template:
   - Copy `docs/templates/anthropic_compatible_provider/PACKAGE/`
   - Paste to `packages/llm_dart_<providerId>/`
2. Rename files and identifiers:
   - Replace `acme` → `<providerId>` (lowercase)
   - Replace `Acme` → `<ProviderName>` (PascalCase)
   - Update base URLs and default model in `<provider>.dart`
3. Add root tests:
   - Copy `docs/templates/anthropic_compatible_provider/ROOT_TESTS/test/providers/acme/`
   - Paste to `test/providers/<providerId>/`
4. Wire it into the monorepo (optional but recommended):
   - Root `pubspec.yaml`: add the dependency if the umbrella should include it
   - Root `pubspec.yaml`: add `packages/llm_dart_<providerId>` to `workspace:` so pub links the package locally
   - `packages/llm_dart_<providerId>/pubspec.yaml`: add `resolution: workspace` (required for workspace members)
   - Umbrella registration:
     - `lib/builtins/builtin_provider_registry.dart`: call `register<ProviderName>()`
     - `lib/src/builtin_llm_builder_extensions.dart`: add `LLMBuilder.<providerId>()`
     - `lib/llm_dart.dart`: export the provider package
   - Run `dart pub get` at the repo root (workspace) to update local linking
5. Run tests:
   - `dart test -j 1`

## Key decisions to make per provider

- **Provider options namespace**: keep it equal to `providerId` (e.g. `minimax`)
  and let the protocol layer fallback to `anthropic`.
- **Escape hatches**:
  - Read provider-only knobs from `providerOptions['<providerId>']` first,
    with a fallback to `providerOptions['anthropic']` for shared shapes.
  - Forward provider-only request fragments via `providerOptions[*]['extraBody']`
    and HTTP headers via `providerOptions[*]['extraHeaders']` (best-effort).
- **No provider constraints / matrices**:
  - LLM Dart intentionally does **not** enforce provider feature constraints,
    does **not** maintain per-model capability matrices, and does **not**
    silently strip “unsupported/ignored” request keys.
  - If a provider rejects a request, we surface the provider error.
