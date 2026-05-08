# Breaking Changelog And Migration Matrix

## Goal

Turn the already-landed refactor slices into release-facing guidance:

1. a concise breaking changelog draft
2. a migration matrix for current public surfaces
3. a compatibility note for the remaining `llm_dart_core` shell

This document is not trying to invent a new architecture. It records the
breaking line that is already being assembled in code and tells users how to
move.

## Current Branch Status

The following slices are already landed on this branch:

- `llm_dart_core.dart` is now a compatibility barrel over focused entrypoints
- production consumers have moved to focused `llm_dart_core` imports
- prompt and generated-file shapes now store required `FileData` instead of
  dual `uri`/`bytes` storage
- the root `lib/core.dart` entrypoint exports focused sub-entrypoints instead
  of the old broad `llm_dart_core` barrel
- the root package no longer has a runtime dependency on `llm_dart_core`; it
  keeps `llm_dart_core` only as a dev dependency for compatibility-shell tests
- the shared `llm_dart_test` helper package now depends on
  `llm_dart_provider` rather than `llm_dart_core`
- core no longer carries duplicate JSON codec helper implementations; those
  helpers live only in `llm_dart_provider`
- `packages/llm_dart_core/lib` is now protected by a compatibility-shell guard
  that rejects new concrete implementation ownership outside approved legacy
  aliases
- `llm_dart_transport` now keeps its public cancellation surface transport-
  owned instead of re-exporting provider legacy aliases
- foundational test directories now reject broad `legacy.dart` imports so
  compatibility coverage stays explicit
- `example/06_mcp_integration` now declares local overrides for the full
  workspace package set it needs
- the old `deepseek-openai`, `google-openai`, `xai-openai`, `groq-openai`,
  and `phind-openai` OpenAI-compatible aliases are no longer registered by
  default, exposed as `LLMBuilder` convenience methods, or kept as typed
  generic-compatible registration targets; use the dedicated provider IDs
  instead. The generic-compatible shell stays only for OpenRouter and explicit
  non-dedicated endpoints such as GitHub Copilot or Together AI.
- the legacy map-based `OpenAICompatibleDefaults` catalog is removed; typed
  `OpenAICompatibleConfigs` owns compatible provider profiles, while
  dedicated provider endpoint/model defaults live beside their providers.
- generic OpenAI-compatible endpoint defaults for OpenRouter, GitHub Copilot,
  and Together AI moved out of `ProviderDefaults` and now live only in typed
  compatible profiles.
- `ProviderDefaults.getCapabilities(...)` is removed; provider factories and
  provider instances own capability declarations.
- OpenAI audio and image compatibility catalogs moved out of `ProviderDefaults`
  into OpenAI compatibility provider modules.
- `ProviderDefaults.getDefaults(...)` is removed; provider factories return
  typed `LLMConfig` defaults through `getDefaultConfig()`.
- `ProviderDefaults` and `package:llm_dart/core/provider_defaults.dart` are
  removed; dedicated provider defaults now live in provider-owned defaults
  classes such as `OpenAIDefaults`, `GoogleDefaults`, and `PhindDefaults`.
- `BaseProviderFactory.getProviderDefaults()` is removed; the registry-facing
  default configuration surface is the typed `getDefaultConfig()`.
- The public `ConfigUtils` compatibility utility is removed; provider Dio
  strategies use an internal compatibility HTTP header helper instead.
- The public `utils/reasoning_utils.dart` utility path is removed; reasoning
  and thinking-tag heuristics are internal provider compatibility details.
- The public `utils/dio_client_factory.dart` wrapper is removed; provider
  clients use the transport-owned `ProviderDioClientFactory` directly.
- The public `utils/http_response_handler.dart` wrapper is removed; shared
  compatibility response handling is internal HTTP infrastructure.
- The unused public `utils/log_sanitizer.dart` re-export is removed; internal
  code imports transport logging helpers from `llm_dart_transport`.
- The legacy/root `utils/utf8_stream_decoder.dart` re-export is removed; import
  `Utf8StreamDecoder` from `package:llm_dart_transport/llm_dart_transport.dart`.
- Legacy `CapabilityUtils` and `ProviderRegistry` are removed. Use
  `ProviderCapabilities` for coarse compatibility checks, `LLMProviderRegistry`
  for provider factories, and model capability profiles for modern discovery.
- The public `utils/http_config_utils.dart` re-export is removed. HTTP
  configuration shaping remains internal compatibility infrastructure.
- `ToolCallAggregator` moved from the root `utils` directory to
  `core/tool_call_aggregator.dart`; `legacy.dart` still exports it as an
  explicit compatibility bridge.

## Suggested Breaking Changelog Draft

Use this as the starting point for the next explicit breaking release.

```md
## [next-breaking-release] - TBD

### Changed

- `package:llm_dart_core/llm_dart_core.dart` is now a compatibility barrel
  over focused entrypoints. New code should import
  `package:llm_dart_core/foundation.dart`, `model.dart`, `serialization.dart`,
  or `ui.dart` directly, or use `package:llm_dart/core.dart` for the modern
  facade.
- Prompt and generated-file shapes now store a single required `FileData`
  union. Legacy `uri`/`bytes` JSON is still accepted on decode, but new code
  should construct `FileUrlData`, `FileBytesData`, `FileTextData`, or
  `FileProviderReferenceData` explicitly.
- OpenAI input-side file IDs now resolve through `FileProviderReferenceData`;
  `providerMetadata.openai.fileId` is no longer accepted as an input file
  identity hint.
- The root `package:llm_dart/core.dart` entrypoint now re-exports the focused
  contracts instead of the old broad `llm_dart_core` barrel.
- The root package runtime dependencies no longer include `llm_dart_core`.
  Compatibility coverage may still use `llm_dart_core` from dev/test
  dependencies while the shell exists.
- The MCP example package now depends on the full local workspace override set
  it actually uses, so it no longer relies on unpublished sibling packages
  resolving from pub.dev.
- `llm_dart_provider_utils` is not part of the first public preview; helper
  extraction stays internal until a stable cross-provider helper contract
  exists.
- `llm_dart_core` is guarded as a compatibility shell. New shared contracts
  belong in `llm_dart_provider`, and new runtime helpers belong in
  `llm_dart_ai`.
- OpenAI-family default entrypoints now prefer dedicated provider IDs plus the
  audited OpenRouter bridge. Provider-owned legacy `*-openai` aliases are no
  longer a supported migration path; non-dedicated generic endpoints must use
  their own explicit compatible profile.
- OpenAI-compatible provider profile metadata is no longer duplicated in
  `OpenAICompatibleDefaults`; use typed `OpenAICompatibleConfigs`.
- `ProviderDefaults` and `package:llm_dart/core/provider_defaults.dart` are
  removed. Dedicated provider defaults live in provider-owned defaults classes
  and generic OpenAI-compatible profiles live in `OpenAICompatibleConfigs`.
- Capability lookup is no longer duplicated through `ProviderDefaults`; ask the
  factory/provider instead.
- OpenAI voice/audio/image catalog details are no longer exposed through
  `ProviderDefaults.getDefaults('openai')`; use the OpenAI provider APIs.
- Dynamic provider default lookup is removed. Factories remain the
  compatibility source for typed default configs through `getDefaultConfig()`.

### Kept

- `llm_dart_core.dart` remains available as a compatibility shell during the
  breaking window.
- `package:llm_dart/legacy.dart` remains in root as the explicit compatibility
  bridge for older builder and broad provider shell APIs.
- `packages/llm_dart_core/test` keeps broad imports as compatibility-shell
  coverage for now.

### Migration summary

- Replace broad `package:llm_dart_core/llm_dart_core.dart` imports with the
  focused entrypoint that matches the contract you need.
- Prefer `package:llm_dart/core.dart` for modern app code that only needs the
  stable facade.
- Replace OpenAI input file IDs previously passed through provider metadata
  with `FileProviderReferenceData(ProviderReference.forProvider('openai', id))`.
- Keep test-only broad imports only where the compatibility shell itself is
  under test.
```

## Migration Matrix

| Current surface | New surface | Status | Notes |
| --- | --- | --- | --- |
| `package:llm_dart_core/llm_dart_core.dart` | `foundation.dart`, `model.dart`, `serialization.dart`, `ui.dart`, or `package:llm_dart/core.dart` | Compatibility shell | This is the main public import to shrink in the breaking line. |
| Root compatibility consumers that still used the broad barrel | Focused `llm_dart_core` entrypoints | Landed in production code | New code should not reintroduce the broad barrel as a dependency. |
| Root runtime dependency on `llm_dart_core` | Direct `llm_dart_provider` and `llm_dart_ai` runtime dependencies | Landed | `llm_dart_core` remains only in dev/test coverage for the compatibility shell. |
| `packages/llm_dart_test` helper package dependency on `llm_dart_core` | `llm_dart_provider` and `llm_dart_transport` | Landed | Shared test fakes should exercise provider contracts directly. |
| Duplicate JSON codec helper implementations in core | Provider-owned helpers only in `llm_dart_provider` | Landed | Core no longer maintains its own parallel JSON helper copies. |
| New implementation declarations in `llm_dart_core/lib` | Owning package plus core re-export | Guarded | `tool/check_core_compatibility_shell_guard.dart` rejects concrete declarations unless they are approved compatibility aliases. |
| Provider legacy aliases on `llm_dart_transport` public barrel | Transport-owned `TransportCancellation` surface | Guarded | `tool/check_transport_boundary_guards.dart` keeps the transport barrel on transport-owned names. |
| Broad `legacy.dart` imports in foundational tests | Focused root/package entrypoints | Guarded | `tool/check_test_legacy_import_guards.dart` keeps core/model/builder/utils tests from depending on the legacy barrel. |
| `packages/llm_dart_core/test` broad imports | Keep for compatibility coverage | Deliberately retained | These tests exercise the shell itself until the shell disappears. |
| `example/06_mcp_integration` path dependencies | Full local workspace overrides | Landed | The example must resolve all unpublished workspace siblings locally. |
| OpenAI input file IDs in `ProviderMetadata` | `FileProviderReferenceData` | Breaking migration | Provider metadata remains for output observation/replay details, not input file identity. |
| `llm_dart_provider_utils` public package | Deferred | Not in first preview | Keep provider helper extraction internal until repeated cross-provider helper needs are stable. |
| `package:llm_dart/legacy.dart` | Keep in root for first preview | Compatibility bridge | Move to `llm_dart_legacy` only in a later release if root dependency shrink requires it. |
| `LLMBuilder.deepseekOpenAI()` and other provider-owned `*-openai` builder aliases | Dedicated providers such as `deepseek`, `google`, `xai`, `groq`, `phind` | Removed | These aliases are no longer kept as explicit generic-compatible registration targets. Use the dedicated provider ID so provider-specific behavior stays on the provider-owned path. |
| Default registry entries for `deepseek-openai`, `google-openai`, `xai-openai`, `groq-openai`, `phind-openai` | Dedicated provider entries plus `openrouter` | Removed | Default app discovery should not show duplicate lower-fidelity aliases, and the explicit compatible registrar now only covers OpenRouter plus non-dedicated generic endpoints. |
| `OpenAICompatibleDefaults` map catalog | `OpenAICompatibleConfigs` for typed profiles; provider-owned defaults classes for coarse dedicated provider defaults | Removed | Avoids maintaining a second untyped profile catalog beside the typed provider-compatible config list. |
| `ProviderDefaults.getDefaults('openrouter'/'github-copilot'/'together-ai')` | `OpenAICompatibleConfigs.getConfig(...)` | Removed | Generic compatible endpoints are profile-owned, not root default-owned dedicated providers. |
| `ProviderDefaults.getCapabilities(...)` | Factory/provider `supportedCapabilities` or typed compatible profile capabilities | Removed | Removes a stale parallel capability catalog from the root defaults class. |
| OpenAI audio/image catalog keys from `ProviderDefaults.getDefaults('openai')` | OpenAI provider compatibility audio/image APIs | Removed | Keeps provider-owned model, voice, format, and image-size catalogs with OpenAI implementation code. |
| `ProviderDefaults.getDefaults(...)` | Factory `getDefaultConfig()` | Removed | Removes the root string-switch map and keeps default configs at the factory boundary that consumes them. |
| `package:llm_dart/core/provider_defaults.dart` and `ProviderDefaults.*` constants | Provider-owned defaults classes or factory `getDefaultConfig()` | Removed | Removes the remaining root defaults catalog so endpoint/model ownership stays with the provider that consumes it. |
| `BaseProviderFactory.getProviderDefaults()` | `LLMProviderFactory.getDefaultConfig()` | Removed | Avoids string-keyed default maps in factory code; provider defaults now become typed `LLMConfig` values. |
| `ConfigUtils` | Provider-owned Dio strategies or internal compatibility HTTP helpers | Removed | Header construction is an implementation detail, not a public root utility. |
| `package:llm_dart/utils/reasoning_utils.dart` | Provider-owned reasoning events and response surfaces | Removed | Reasoning-field and `<think>` tag parsing is provider implementation detail, not a stable root utility contract. |
| `package:llm_dart/utils/dio_client_factory.dart` | `package:llm_dart_transport` `ProviderDioClientFactory` | Removed | The root wrapper no longer has production callers; provider clients pass typed Dio overrides to the transport-owned factory directly. |
| `package:llm_dart/utils/http_response_handler.dart` | Provider-owned clients and internal compatibility HTTP helpers | Removed | Response parsing/error mapping is shared implementation infrastructure, not a stable root utility path. |
| `package:llm_dart/utils/log_sanitizer.dart` | `package:llm_dart_transport` logging helpers | Removed | The root file was an unused re-export of transport-owned implementation. |
| `package:llm_dart/utils/utf8_stream_decoder.dart` and `legacy.Utf8StreamDecoder` | `package:llm_dart_transport` `Utf8StreamDecoder` | Removed | UTF-8 stream decoding is transport-owned and should not be surfaced through the root compatibility barrel. |
| `CapabilityUtils`, `ProviderRegistry`, `globalProviderRegistry` | `ProviderCapabilities`, `LLMProviderRegistry`, and model capability profiles | Removed | The provider-level dynamic utility registry was legacy-only and conflicts with the model-centric capability discovery direction. |
| `package:llm_dart/utils/http_config_utils.dart` and `legacy.HttpConfigUtils` | Provider-owned clients and internal compatibility HTTP config helpers | Removed | HTTP client configuration shaping is a compatibility implementation detail, not a stable root utility path. |
| `package:llm_dart/utils/tool_call_aggregator.dart` | `package:llm_dart/core/tool_call_aggregator.dart` or `package:llm_dart/legacy.dart` | Moved | The helper remains stable, but the root `utils` directory is no longer a public ownership boundary. |
| `LLMBuilder.githubCopilot()` and `LLMBuilder.togetherAI()` | Explicit provider registration or provider-owned OpenAI-family profile composition | Removed from default builder surface | These methods only selected unregistered provider IDs. For generic compatible endpoints, construct a provider-owned OpenAI-family model/profile explicitly or register a concrete factory. |

## Compatibility Policy

- Keep the compatibility barrel for the breaking window only.
- Do not add new implementation ownership to the broad barrel.
- Run `dart run tool/check_core_compatibility_shell_guard.dart` when touching
  `packages/llm_dart_core/lib`.
- Keep test-only broad imports as legacy coverage until the shell is removed.
- Prefer focused entrypoints in docs, examples, and new code.

## Release Note Reminders

The release note should make the following points explicit:

- this is a breaking architecture line, not a routine patch release
- the new default surfaces are focused entrypoints, not the compatibility
  barrel
- provider-owned features still stay provider-owned
- examples that need unpublished workspace siblings should use local path
  overrides
