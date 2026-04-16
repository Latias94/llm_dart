# Removal Readiness Matrix

## Goal

Turn the policy into a concrete readiness table for the main remaining legacy
surface groups.

## Matrix

| Surface | Current posture | Earliest next action | Earliest removal window | Blockers |
| --- | --- | --- | --- | --- |
| `package:llm_dart/legacy.dart` | Frozen compatibility host | Keep and document as migration-only | Later breaking window | Builder and root constructor migration still incomplete |
| `ai()` helper | Frozen compatibility host | Ready for an explicit soft-deprecation decision now that task recipes and legacy leaf migration notes exist | Later than the first breaking window | Need a policy call on whether keeping both `legacy.dart` and `ai()` still adds enough migration value |
| `LLMBuilder` | Frozen compatibility host | Review only after the `ai()` posture is frozen | Later than the first breaking window | Still the broadest root migration rail and should not be weakened by accident |
| `HttpConfig`, `AudioConfig`, `ImageConfig`, `ProviderConfig` | Frozen compatibility host | Keep tied to the builder decision | Same window as any future builder removal | Builder posture unresolved |
| Root provider constructors | Frozen compatibility host | Keep | Later breaking window | Still the most direct bridge for old root-package users |
| Preset helper aliases | Soft-deprecated | Keep deprecated and link provider-family migration notes in docs/changelog | Next deliberate breaking window | Migration notes now exist; remaining blocker is release timing, not replacement clarity |
| Builder web-search helpers | Soft-deprecated | Keep deprecated and keep all new docs/examples on provider-owned search APIs | Next deliberate breaking window | Replacement notes now exist; remaining blocker is release timing, not replacement clarity |
| `createProvider(..., extensions: ...)` raw escape hatch | Soft-deprecated | Tighten migration guidance toward typed APIs | Next deliberate breaking window | Need examples to show typed replacement patterns |
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
