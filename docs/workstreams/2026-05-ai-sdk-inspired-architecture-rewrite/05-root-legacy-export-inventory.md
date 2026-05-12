# Root Legacy Export Inventory

## Scope

This inventory covers the current public exports from
`package:llm_dart/legacy.dart`. The goal is to keep the compatibility shell
explicit and frozen while the modern `llm_dart.dart` and focused package
entrypoints remain the default surface.

## Decision Summary

| Export group | Current exports | Decision | Replacement direction |
| --- | --- | --- | --- |
| Compatibility facade | `AI` | Freeze | `package:llm_dart/ai.dart` for modern code |
| Registry bootstrap | `ensureRootRegistryBootstrap` | Freeze | Internal migration glue until builder routing is retired |
| Builder trunk | `legacy_builder_helpers.dart`, `LLMBuilder`, `HttpConfig` | Freeze | Modern model factories and `AI.<provider>(...)`; keep builder only for migration |
| Legacy provider config adapters | `createLegacy*Config`, `createLegacyDioClientOverrides` | Freeze | Provider-owned typed settings and invocation options |
| OpenAI-compatible config model | `OpenAICompatibleProviderConfig` and transformer typedefs | Freeze | Provider-owned OpenAI-family profiles for modern code |
| Root core compatibility barrels | `core/*` exports | Relocate later or freeze until root legacy exit | `package:llm_dart/core.dart` and focused provider packages |
| Root model compatibility barrels | `models/*` exports | Relocate later or delete with legacy builder | Provider-owned contracts and `llm_dart_provider`/`llm_dart_ai` contracts |
| Root provider compatibility barrels | `providers/*` exports | Relocate later or delete with legacy shell | Focused provider packages such as `llm_dart_openai`, `llm_dart_google`, and root focused entrypoints |
| Base factory compatibility | `providers/factories/base_factory.dart` | Freeze | Provider facades or explicit runtime-selected factory APIs |
| Tool-call aggregator | `core/tool_call_aggregator.dart` | Relocate later | Modern utility entrypoint if it remains independently useful |
| Transport compatibility re-exports | selected `llm_dart_transport` types | Freeze | `package:llm_dart/transport.dart` or `llm_dart_transport` |

## Removed Leaves

| Removed surface | Replacement direction | Notes |
| --- | --- | --- |
| `CompatWebSearchPresets` | Use provider-owned typed search options for modern code, or construct `WebSearchConfig` directly while staying on the compatibility builder. | Removed because it preserved a fake cross-provider preset abstraction after builder web-search helpers already moved to the removal path. |

## Freeze Rule

`legacy.dart` is a compatibility barrel, not a growth point. New exports are
allowed only when a migration blocker requires them and the export decision is
recorded here first.

The root package boundary guard now freezes the exact public directives in
`legacy.dart`. Any change to that barrel must update this inventory and the
guard intentionally.

## Removal Order

1. Remove or relocate compatibility leaves that already have typed provider
   replacements, such as search presets and old root provider option shortcuts.
2. Keep the builder trunk until dynamic provider migration guidance no longer
   depends on `LLMBuilder` or `createProvider(...)`.
3. Decide whether root provider compatibility barrels are deleted directly or
   moved to a separate compatibility package.
4. Remove `legacy.dart` only after the builder trunk, provider barrels, and
   migration docs have a single coherent exit path.

## Non-Goals For This Slice

- Do not delete `legacy.dart` in the same slice that freezes it.
- Do not move compatibility code into a new package before the migration
  surface is stable.
- Do not add replacement APIs in the root package just to preserve old import
  ergonomics.
