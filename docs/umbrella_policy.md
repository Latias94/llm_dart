# Umbrella `llm_dart` policy (exports + registration)

This repo is a multi-package monorepo. You can either:

- depend on the umbrella package `llm_dart` (all-in-one), or
- pick subpackages (Vercel AI SDK style): `llm_dart_ai` + `llm_dart_builder` + one or more provider packages.

This document defines what the umbrella package exports and what it registers by default.

## 1) Export policy

`package:llm_dart/llm_dart.dart` re-exports:

- Standard layers:
  - `llm_dart_core` (types + shared models)
  - `llm_dart_ai` (task APIs; the recommended stable surface)
  - `llm_dart_builder` (builder + config helpers)
- Provider packages shipped in the umbrella:
  - Standard providers: `llm_dart_openai`, `llm_dart_anthropic`, `llm_dart_google`
  - Additional providers: `llm_dart_deepseek`, `llm_dart_groq`, `llm_dart_xai`, `llm_dart_minimax`, `llm_dart_ollama`, `llm_dart_elevenlabs`
- Protocol reuse layers:
  - `llm_dart_openai_compatible` (OpenAI-compatible protocol + preset factories)
  - `llm_dart_anthropic_compatible` (Anthropic Messages-compatible protocol)

Notes:

- `llm_dart_provider_utils` is intentionally **not** re-exported by the umbrella to keep the default surface provider/transport-agnostic.
- Phind is not shipped (provider removed from this repository).
- Provider packages should not re-export protocol reuse layers; depend on the protocol packages directly when you need protocol-level types.
- Provider packages also keep low-level HTTP implementation details opt-in:
  - If you need a provider's internal HTTP client or Dio strategy, import it via a subpath
    library (e.g. `package:llm_dart_google/client.dart`, `package:llm_dart_google/dio_strategy.dart`)
    instead of relying on `<provider>.dart` default exports.

## 2) Registration policy

### 2.1 Automatic registration

Umbrella entrypoints like `ai()` call `BuiltinProviderRegistry.ensureRegistered()` so users can start quickly without manually calling `register*()`.

By default, `ensureRegistered()` registers:

- Standard providers: `openai`, `anthropic`, `google`
- Additional providers: `deepseek`, `groq`, `xai`, `xai.responses`, `ollama`, `minimax`, `elevenlabs`
- OpenAI-compatible preset: `openrouter`

### 2.2 Opt-in presets (OpenAI-compatible)

OpenAI-compatible presets can be duplicates of first-party providers (example: `deepseek` vs `deepseek-openai`), so they are treated as opt-in unless you select them explicitly.

You can enable presets via:

- `registerOpenAICompatibleProvider('<id>')` (single preset), or
- `registerOpenAICompatibleProviders()` (all presets).

Presets shipped in `llm_dart_openai_compatible` currently include:

- `deepseek-openai`
- `groq-openai`
- `xai-openai`
- `google-openai`
- `openrouter`
- `github-copilot`
- `together-ai`

The umbrella builder extensions (e.g. `LLMBuilder().deepseekOpenAI()`) register their preset on demand.

### 2.3 Standard-only mode

If you only want the Vercel-style “standard provider set”, call:

- `BuiltinProviderRegistry.registerStandard()` / `BuiltinProviderRegistry.ensureStandardRegistered()`

## 3) Recommended usage

- For “pick subpackages” users: prefer `llm_dart_ai` + `llm_dart_builder` + provider package(s) and call `register*()` explicitly.
- For “all-in-one” users: use `llm_dart`, rely on automatic registration, and treat provider-specific features as escape hatches via `providerOptions` / `providerTools` / `providerMetadata`.
