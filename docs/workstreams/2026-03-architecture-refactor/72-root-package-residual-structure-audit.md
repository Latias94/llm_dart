# Root Package Residual Structure Audit

## Goal

This note narrows the next root-package refactor target after the provider
packages, Flutter layer, and OpenAI Responses work matured:

> Which remaining root `llm_dart` files still act like bus files, which of
> them are acceptable compatibility facades, and which should keep shrinking
> toward thin barrels over smaller implementation slices?

The main point is discipline. `repo-ref/ai` is useful here not because we
should mirror its package count, but because it keeps provider logic, model
contracts, and app-facing entrypoints from collapsing back into one file.

## 1. Current Residual Hotspots

The remaining root-package hotspots are now concentrated in four files:

- `lib/src/compatibility/compat_providers.dart` had reached 1,398 lines before
  the first decomposition slice in this round
- `lib/core/capability.dart` is still 980 lines
- `lib/builder/llm_builder.dart` is still 676 lines
- `lib/models/chat_models.dart` is still 652 lines

These files do not have the same problem.

- `compat_providers.dart` was mostly an implementation bus file
- `LLMBuilder` is a compatibility-heavy facade that also still owns too much
  mutation logic
- `capability.dart` mixes stable compatibility interfaces with optional
  convenience layers and provider-discovery declarations
- `chat_models.dart` mixes stable legacy message/value models with builder DSL
  and compatibility helpers

That difference matters because not every large file needs the same treatment.

## 2. Frozen Root-Package Rules

The root package should now follow these rules.

### 2.1 Keep The Root Package As A Compatibility Facade

The root package still needs to host:

- `LLMBuilder`
- legacy provider subclasses
- legacy capability interfaces
- legacy message/value models

But it should increasingly behave like a compatibility facade over smaller
modules, not like the implementation home for migrated provider logic.

### 2.2 Provider Routing Logic Stays In Compatibility Slices

Provider-specific chat bridge wiring belongs under `src/compatibility/`, not in
`builder/`, `core/`, or shared message files.

That keeps the modern package-owned language-model path and the legacy root
facade separated in the same way that `repo-ref/ai` separates provider wiring
from the common model layer.

### 2.3 Large Root Files Should Prefer Barrel Decomposition First

For the remaining root hotspots, the safest first move is:

- split implementation into smaller internal files
- keep public exports stable
- avoid widening the root surface while refactoring internals

This matches the current breaking strategy better than a second large public
rename wave.

## 3. File-By-File Decisions

### 3.1 `compat_providers.dart`

This file was the clearest bus-file smell.

It mixed:

- provider builders
- legacy provider subclasses
- OpenAI-family config mapping
- Google typed-option mapping
- Anthropic replay-specific adapter logic
- generic compatibility fallback behavior

That was too much unrelated ownership for one file.

### Decision

`compat_providers.dart` should stay only as a compatibility barrel.

The implementation should live in provider-family slices:

- `providers/openai_family_compat_provider.dart`
- `providers/google_compat_provider.dart`
- `providers/anthropic_compat_provider.dart`
- `providers/compat_provider_support.dart`

### Why This Matches The Reference Direction

This does not copy the reference package count, but it does copy the important
structural lesson:

- provider-family wiring lives near provider-family concerns
- shared routing helpers stay tiny and explicit
- the entrypoint file stops being both barrel and implementation bus

### Status

This first decomposition slice is now landed.

### 3.2 `LLMBuilder`

`LLMBuilder` is different. It is supposed to remain a public convenience facade,
so the answer is not “remove it immediately.”

The real issue is that it still mixes four responsibilities:

- provider selection and defaults
- common config mutation
- legacy string-extension mutation
- typed capability build methods

### Decision

`LLMBuilder` should stay public for the compatibility window, but its
implementation should be decomposed internally into smaller focused modules.

Recommended split:

- provider selection and default-config loading
- common generation config setters
- modality/search/provider-specific extension setters
- capability-specific `build*()` helpers

### Important Boundary

The builder should not become the long-term home for new provider-specific
product features. New stable features should continue landing in the modern
package-owned model APIs first.

### 3.3 `capability.dart`

`capability.dart` is large partly because it contains genuine stable public
surface. That means we should be more conservative than with the compatibility
provider file.

It currently mixes:

- stable legacy capability interfaces such as `ChatCapability`
- legacy stream event types
- provider capability enums
- optional convenience mixins or default implementations
- higher-level optional capability families such as assistants, moderation, and
  tool execution

### Decision

Keep the public exports stable, but internally split the file into smaller
barrel-managed modules grouped by concept rather than by historical growth.

Recommended grouping:

- chat capability and legacy stream events
- embedding and model-listing capability
- audio and realtime capability
- image capability
- file, moderation, and assistant capability
- provider-capability discovery enums and mixins

### Important Boundary

This split is about readability and ownership, not about inventing more
capability types. The current root capability surface is already broader than
the new package-owned API direction, so the refactor should reduce coupling
without expanding legacy API scope.

### 3.4 `chat_models.dart`

`chat_models.dart` still contains at least three different families:

- legacy message/value types that must stay stable for compatibility
- tool-call and media-related helpers
- the `MessageBuilder` DSL and provider-extension wrapper utilities

### Decision

Preserve the current public model names, but decompose the implementation into
smaller files and keep the builder DSL separate from the core legacy message
values.

Recommended grouping:

- base chat roles and message types
- media and MIME helpers
- tool call value models
- `ChatMessage`
- `MessageBuilder` and content-block compatibility DSL
- request metadata and reasoning-related enums

### Important Boundary

`MessageBuilder` is compatibility-oriented DSL, not the new canonical message
entrypoint. It should stay available during migration, but it should not keep
forcing unrelated legacy value types into the same source file.

## 4. Recommended Refactor Order

The safest next order is:

1. Decompose the compatibility provider bus file first.
2. Decompose `LLMBuilder` into smaller implementation modules without changing
   the builder API.
3. Decompose `capability.dart` and `chat_models.dart` into barrel-managed
   modules while keeping current public exports stable.
4. Only after that, decide whether more aggressive legacy builder or legacy
   message deprecations are worth doing before `1.0.0`.

This order keeps the highest-risk provider routing logic readable first, then
shrinks the public root facade internals without starting a new public-API
freeze fight.

## 5. What Should Not Happen Next

To keep this refactor disciplined, the next round should avoid:

- moving provider-specific request shaping back into `core/`
- turning `LLMBuilder` into the preferred home for new provider-owned features
- widening `capability.dart` just because the file is already large
- merging Flutter session concerns back into root compatibility APIs
- splitting the workspace into reference-style micro-packages only for symmetry

## Conclusion

The remaining root-package structure gap versus `repo-ref/ai` is no longer a
provider-package gap. It is now mostly a root-facade cleanup gap.

The correct direction is:

- keep the root package as a compatibility shell
- keep provider-owned logic in provider packages or compatibility slices
- keep large root files shrinking toward thin barrels over focused modules

The first slice of that cleanup is now clear and landed: the old
`compat_providers.dart` implementation bus has been decomposed into
provider-family modules while the public compatibility surface stayed stable.
