# 188 Ollama Migration Closure Audit

## Goal

Decide whether `Migrate Ollama` should remain open in the workstream TODO, or
whether the remaining Ollama items are now better classified as:

- intentional residual provider-owned surfaces
- compatibility-only fallback cases
- already-frozen provider wire limitations

This matters because keeping a broad migration item open after its real scope is
already complete creates false architecture debt and distracts from the actual
remaining blocker: broader community-provider decoupling in the root
compatibility layer.

## What Was Reviewed

Current package-owned modern Ollama coverage already includes:

- `Ollama(...).chatModel(...)`
- `Ollama(...).embeddingModel(...)`
- request encoding for replay-safe shared chat traffic
- assistant reasoning replay through Ollama `thinking`
- assistant tool-call replay through Ollama-shaped `tool_calls`
- tool-result replay through `tool_name`
- URI-backed user image inputs through data URIs or
  `OllamaBinaryResolver`

Current root compatibility behavior already does the intended shell role:

- delegates replay-safe chat requests into the modern model path
- delegates embeddings into the modern model path
- keeps explicit fallback for legacy-only edge cases such as named messages and
  duplicate system-prompt shaping
- keeps completion and model listing as residual provider-owned or
  compatibility-only concerns

Relevant files:

- `packages/llm_dart_community/lib/src/ollama_language_model.dart`
- `packages/llm_dart_community/lib/src/ollama_embedding_model.dart`
- `packages/llm_dart_community/README.md`
- `lib/src/compatibility/providers/ollama/provider_compat.dart`
- `lib/src/compatibility/providers/ollama/shell_support.dart`
- `test/providers/ollama/ollama_provider_bridge_test.dart`

## Frozen Closure Decision

`Migrate Ollama` should now be considered complete for the current workstream
scope.

## Why It Can Close

### 1. The shared-capability modern surface is already real

The current workstream did not promise to migrate every Ollama endpoint into
`llm_dart_community`.

It promised to establish truthful package-owned modern shared-capability
surfaces.

That is now already true for:

- chat generation
- embeddings

### 2. The remaining gaps are no longer migration gaps

The previously open fidelity questions are now already frozen honestly:

- stronger shared `toolChoice` forcing remains warning-degraded because the
  current chat wire contract has no truthful forcing field
- replay-time tool error state remains warning-degraded because the current
  chat wire contract has no dedicated native replay field
- URI-backed user image input support is now already covered through data URIs
  and `OllamaBinaryResolver`

Those are not "unfinished migration" items anymore.

### 3. Residual Ollama APIs are intentionally outside the shared modern target

The remaining non-shared Ollama APIs are already frozen as residual ownership:

- `/api/generate` completion
- model listing

Those should stay provider-owned or compatibility-only instead of being treated
as blockers for the shared-capability migration item.

### 4. Compatibility fallback is not evidence of failed migration

The root shell still keeps fallback for named messages and duplicate
system-prompt shaping.

That is correct.

It means:

- the modern package owns the truthful shared overlap
- the compatibility shell preserves old edge-case behavior where needed

That is exactly the architecture target, not proof that migration is
incomplete.

## What Stays Open After Closing This Item

Closing `Migrate Ollama` does **not** mean Ollama-related work is finished
everywhere.

The remaining real item is broader:

- `Decouple Ollama and ElevenLabs from root-local compatibility imports before
  moving real implementation weight into llm_dart_community`

That is a root compatibility ownership problem, not an Ollama shared-capability
migration problem.

## Non-Goals

This decision does **not**:

- move completion into the shared modern package
- move model listing into the shared modern package
- remove compatibility fallback behavior
- claim that the entire root Ollama shell is gone

It only closes the specific migration item at the correct scope.

## Conclusion

Ollama shared-capability migration is now complete for the current workstream:

- modern chat exists
- modern embeddings exist
- remaining wire limitations are already frozen honestly
- residual provider-specific APIs are already frozen outside the shared target
- remaining work now belongs to community-provider decoupling, not to
  `Migrate Ollama`

So the TODO item should close.
