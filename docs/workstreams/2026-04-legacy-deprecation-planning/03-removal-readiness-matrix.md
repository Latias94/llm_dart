# Removal Readiness Matrix

## Goal

Turn the policy into a concrete readiness table for the main remaining legacy
surface groups.

## Matrix

| Surface | Current posture | Earliest next action | Earliest removal window | Blockers |
| --- | --- | --- | --- | --- |
| `package:llm_dart/legacy.dart` | Frozen compatibility host | Keep and document as migration-only | Later breaking window | Builder and root constructor migration still incomplete |
| `ai()` helper | Soft-deprecated | Keep deprecated and move all first-party executable code to `LLMBuilder()` or the stable `AI` facade | Later than the first already-prepared leaf-removal window | Needs one explicit migration cycle before removal review |
| `LLMBuilder` | Frozen compatibility host | Keep as the explicit builder trunk while the `ai()` alias deprecates | Later than the first breaking window | Still the broadest root migration rail and should not be weakened by accident |
| `HttpConfig` | Frozen compatibility host | Keep tied to the builder decision | Same window as any future builder removal | Builder posture unresolved |
| `AudioConfig` | Removed from the legacy builder shell | Use shared audio request fields plus provider-owned typed options | Removed in the architecture foundation branch | It had no runtime consumer and duplicated provider-owned audio options |
| `ImageConfig` and legacy media builder extension | Removed from the legacy builder shell | Use `ImageGenerationRequest` or image capability method parameters | Removed in the architecture foundation branch | It had no runtime consumer and duplicated request-level image fields |
| `ProviderConfig` | Removed from the legacy builder shell | Use provider-specific builder callbacks or typed provider options | Removed in the architecture foundation branch | It was an unconsumed raw extension map builder that duplicated provider-owned APIs |
| Root provider constructors | Frozen compatibility host | Keep | Later breaking window | Still the most direct bridge for old root-package users |
| Preset helper aliases | Soft-deprecated | Keep deprecated and link provider-family migration notes in docs/changelog | Next deliberate breaking window | Migration notes now exist; remaining blocker is release timing, not replacement clarity |
| Builder web-search helpers | Soft-deprecated | Keep deprecated and keep all new docs/examples on provider-owned search APIs | Next deliberate breaking window | Replacement notes now exist; remaining blocker is release timing, not replacement clarity |
| `createProvider(...)` generic helper | Frozen compatibility host | Keep as the generic legacy-shell helper for runtime-selected providers | Later breaking window | No equally short shared replacement exists for dynamic provider selection |
| `createProvider(..., extensions: ...)` raw escape hatch | Soft-deprecated | Tighten migration guidance toward typed APIs and provider-owned option surfaces | Next deliberate breaking window | The function stays; only the raw extension bag is a removal candidate |
| Root cancellation alias guidance | Soft-deprecated | Continue steering users toward transport-owned types | Next deliberate breaking window | None beyond release-note clarity |
| Registry/bootstrap glue | Frozen compatibility infrastructure | Keep out of default docs | No removal target yet | Still needed by builder/legacy routing |
| `ToolCallAggregator` and similar independent helpers | Stable useful utility | Move or duplicate documentation into modern guidance if needed | No deprecation target in this phase | Utility has value beyond legacy flows |

## Reading The Matrix

The matrix deliberately separates:

- "soft-deprecated now"
- "keep frozen for now"
- "not part of deprecation at all"

This prevents the repository from confusing three different actions:

1. stop recommending something
2. add deprecation and prepare removal
3. actually remove it

Those actions should not happen in the same release by default.

## Current Branch Status

On `refactor/architecture-foundation`, the first conservative leaf-removal
slice is now already landed in code:

- deprecated preset helper aliases removed
- deprecated shared builder web-search helpers removed
- deprecated OpenRouter builder search ergonomics removed
- `createProvider(..., extensions: ...)` reduced to `createProvider(...)`
- deprecated `CancelToken` alias removed

The larger compatibility trunks remain intentionally untouched:

- `legacy.dart`
- `LLMBuilder`
- `createProvider(...)`
- root provider constructors
- `ai()` removal itself
