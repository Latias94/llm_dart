# Compatibility Exit Plan

## Current Source Findings

Root `llm_dart` and `llm_dart_core` are compatibility surfaces after the
package split.

Current posture:

- root `llm_dart` is a modern convenience facade plus explicit compatibility
  bridge
- `llm_dart_core` re-exports owner-package APIs and should not own new
  implementation
- guard tooling already checks root boundary, core shell, provider replay
  metadata, transport boundary, example API, and dependency direction

The remaining risk is compatibility gravity: users can keep importing legacy
barrels, and those barrels can pressure future architecture decisions unless
their exit policy is explicit.

## Decisions Needed

### Root Facade

Classify every root export as:

- modern facade
- migration bridge
- removal candidate
- provider-native re-export
- legacy-only compatibility

Root can remain useful, but it must not become the place where new
implementation ownership hides.

### `llm_dart_core`

Classify every core export as:

- provider-owned contract re-export
- AI runtime re-export
- chat/UI re-export
- serialization compatibility re-export
- removal candidate

No new architectural API should be added to `llm_dart_core`.

### Registry

Decide the final posture:

- adapt `ModelRegistry` over provider-object registry
- deprecate `ModelRegistry` and introduce provider-object registry
- remove `ModelRegistry` in the breaking line

Previous rebaseline work favors provider-object registry lookup while keeping
direct provider facades for typed advanced settings.

## Migration Docs Needed

Migration docs should include before/after examples for:

- root import to focused package import
- `llm_dart_core` import to owner package import
- direct provider model calls to `llm_dart_ai` runtime helpers
- model registry lookup to provider-object registry lookup
- metadata-driven request customization to typed provider options
- prompt replay metadata to explicit replay prompt-part options

## Guard Updates Needed

Potential guard additions:

- reject new non-export implementation files under `llm_dart_core/lib/src`
- reject root exports that are not allowlisted as facade or compatibility
  bridge
- reject provider package production dependencies on root/core/chat/flutter/AI
  runtime
- reject provider-facing prompt APIs that accept `ProviderMetadata` as ordinary
  input customization
- reject runtime-only stream events in provider packages

## Proposed First Slice

Inventory root and `llm_dart_core` exports into a table with owner package,
status, and exit policy. Do not delete compatibility APIs until migration docs
and consumer smoke coverage are updated.

## Root Export Inventory

| Entrypoint | Owner | Status | Exit policy |
| --- | --- | --- | --- |
| `lib/llm_dart.dart` | root package | Modern default facade | Keep as a one-line export of `ai.dart`. It must not regain builder-era or implementation exports. |
| `lib/ai.dart` | root package plus focused packages | Modern aggregator facade | Keep as the convenience import that composes `llm_dart_ai`, focused provider entrypoints, transport, and the optional `AI` namespace. New root exports must go through the root boundary guard allowlist. |
| `lib/src/facade/ai.dart` | root package | Modern factory facade | Keep short provider factories and the optional `AI` namespace. Do not add model implementation logic here; delegate to focused provider packages. |
| `lib/core.dart` | `llm_dart_ai` / shared packages | Compatibility-focused convenience facade | Keep for root-package users who want a single shared-contract import. It is not the owner of core contracts; owner packages remain `llm_dart_provider` and `llm_dart_ai`. |
| `lib/transport.dart` | `llm_dart_transport` | Focused transport facade | Keep. Transport implementation ownership stays in `llm_dart_transport`; root only composes it with `core.dart`. |
| `lib/chat.dart` | `llm_dart_chat` | Focused chat facade | Keep as the only root entrypoint allowed to expose `llm_dart_chat`. Flutter remains out of root. |
| `lib/openai.dart` | `llm_dart_openai` | Focused provider facade | Keep provider-owned OpenAI-family surface plus the short `openai(...)` factory. |
| `lib/google.dart` | `llm_dart_google` | Focused provider facade | Keep provider-owned Google surface plus the short `google(...)` factory. |
| `lib/anthropic.dart` | `llm_dart_anthropic` | Focused provider facade | Keep provider-owned Anthropic surface plus the short `anthropic(...)` factory. |
| `lib/ollama.dart` | `llm_dart_ollama` | Focused provider facade | Keep provider-owned Ollama surface plus the short `ollama(...)` factory. |
| `lib/elevenlabs.dart` | `llm_dart_elevenlabs` | Focused provider facade | Keep provider-owned ElevenLabs surface plus the short `elevenLabs(...)` factory. |
| `lib/deepseek.dart`, `lib/openrouter.dart`, `lib/groq.dart`, `lib/xai.dart`, `lib/phind.dart` | `llm_dart_openai` profiles | Focused profile facades | Keep as profile-owned OpenAI-family entrypoints with restricted `show` exports. Do not widen them to all OpenAI native helper clients. |

The current root boundary guard already enforces this inventory by allowlisting
root files, exact public export directives, and the small `lib/src/facade`
implementation area. That guard is the compatibility policy, not just a smoke
test.

## `llm_dart_core` Export Inventory

| Entrypoint | Owner exports | Status | Exit policy |
| --- | --- | --- | --- |
| `llm_dart_core.dart` | `foundation.dart`, `model.dart`, `serialization.dart`, `ui.dart` | Historical compatibility barrel | Keep only as a compatibility umbrella. New code should import focused `llm_dart_core` entrypoints or owner packages directly. |
| `foundation.dart` | `llm_dart_provider` contracts plus approved aliases | Provider-owned contract re-export | Keep narrow and shell-only. Shared contract ownership stays in `llm_dart_provider`; `llm_dart_core` must not add implementation. |
| `model.dart` | `llm_dart_provider` model contracts and `llm_dart_ai` runtime helpers | Mixed model compatibility re-export | Keep for migration, but do not treat it as the canonical owner. New runtime behavior belongs in `llm_dart_ai`; model contracts belong in `llm_dart_provider`. |
| `serialization.dart` | provider prompt serialization and AI UI/stream serialization | Serialization compatibility re-export | Keep while migration examples exist. New serialization codecs should be added to the owning package and only re-exported here when compatibility requires it. |
| `ui.dart` | `llm_dart_ai` UI projection and shared stream types | UI compatibility re-export | Keep as a migration surface. UI behavior ownership stays in `llm_dart_ai` and package-specific adapters. |
| `lib/src/**` | owner-package re-export shims | Compatibility shell internals | Freeze. Files should remain exports or explicitly allowlisted aliases only. The core compatibility shell guard blocks new implementation. |

Final posture: `llm_dart_core` is a long compatibility shell for this breaking
line. It should not be removed yet because examples, migration docs, and
consumer smoke still need a staged path, but it must stay frozen and guarded.

## Registry Decision

Keep both registry types with a clear hierarchy:

- `ProviderRegistry` is the modern registry. It registers provider objects,
  discovers supported model facets, and matches the provider-owned architecture
  used by the focused packages.
- `ModelRegistry` is retained as a low-level compatibility adapter for callers
  that already own independent per-kind model factories.
- New root facades, examples, and migration docs should prefer provider objects
  or direct provider factories over `ModelRegistry`.

Do not remove `ModelRegistry` in this breaking line. The correct posture is
adapt/de-emphasize, not delete: keep it in `llm_dart_provider` for custom
factory-map integrations, keep it out of new architectural examples, and only
consider deprecation after migration docs and consumer smoke prove that
provider-object lookup fully covers current users.
