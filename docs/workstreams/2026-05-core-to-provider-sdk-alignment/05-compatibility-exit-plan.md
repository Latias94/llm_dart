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
