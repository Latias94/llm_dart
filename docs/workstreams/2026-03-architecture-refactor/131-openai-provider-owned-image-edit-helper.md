# 131. OpenAI Provider-Owned Image Edit Helper

## Decision

OpenAI image editing should gain a provider-owned modern helper in
`llm_dart_openai`.

It should **not** widen the shared `ImageModel` contract in the current round.

OpenAI image variation should stay explicitly deferred for now.

## Why

The residual OpenAI review showed that image editing was the clearest remaining
provider-owned gap where:

- the root compatibility layer still exposed real user-facing value
- `llm_dart_openai` still lacked an equivalent modern path
- `repo-ref/ai` already treated `/images/edits` as part of the modern OpenAI
  image-model surface

At the same time, the current shared image contract remains intentionally
narrow:

- prompt
- count
- size
- generic `CallOptions`

It still does not define a truthful provider-neutral model for:

- uploaded image files
- masks
- multipart-specific edit controls

So widening shared core first would still be the wrong sequencing.

## What Landed

The modern OpenAI package now exposes a provider-owned editing helper on the
concrete `OpenAIImageModel` type:

- `edit(OpenAIImageEditRequest request)`

New typed provider-owned request shapes:

- `OpenAIImageEditInput`
- `OpenAIImageEditRequest`
- `OpenAIImageInputFidelity`

The helper returns the same shared `ImageGenerationResult`, so app code still
uses the normal generated-image result surface instead of a second image-edit
result model.

## Request Boundary

### Shared request controls stay where they already belong

Editing reuses:

- shared `CallOptions`
- provider-owned `OpenAIImageOptions` for common OpenAI image knobs such as
  `background`, `quality`, `outputFormat`, `responseFormat`, and `user`

### Edit-only knobs stay on the provider-owned edit request

The helper keeps multipart-specific controls on `OpenAIImageEditRequest`:

- input images
- optional mask
- `inputFidelity`
- `partialImages`
- `outputCompression`

That keeps the existing OpenAI image invocation options reusable without
pretending that every edit-only control belongs in a shared invocation surface.

## Transport And Dependency Direction

This helper intentionally reuses the existing
`packages/llm_dart_openai/lib/src/openai_multipart_body.dart` utility.

That means:

- multipart stays provider-owned above the transport boundary
- `llm_dart_openai` does not need a new direct runtime dependency on `dio`
- the frozen dependency direction still holds

## Explicit Non-Goals

This slice intentionally does **not** add:

- a shared image-edit contract in `llm_dart_core`
- a new shared file-upload abstraction
- automatic remote-URL download support for image inputs
- a provider-owned OpenAI image-variation helper
- removal of the compatibility-era root image-edit APIs in the same round

## Why Variation Stayed Deferred

The reference package gives a clear modern signal for `/images/edits`, but not
the same strong signal for a separate modern variation helper.

The old root compatibility surface still has `createVariation(...)`, but that
endpoint is:

- narrower than the edit path
- more legacy-shaped
- less important for Flutter chat integration than direct provider-owned image
  editing

So the clean near-term move is:

- land the provider-owned edit helper now
- keep variation as an explicit follow-up decision instead of silently growing
  the modern provider package by symmetry

## Event Surface Note

Re-checking the current shared stream layer against `repo-ref/ai` did not
reveal a new image-edit-specific event gap.

The current event work remains the right boundary:

- shared event families stay in `llm_dart_core`
- provider codecs decide which of those families to emit
- richer UI/session chunking stays above `TextStreamEvent`

This image-edit helper therefore did not require any event-model expansion.

## Verification

- `dart analyze packages/llm_dart_openai`
- `dart test packages/llm_dart_openai`

## Roadmap Consequence

This closes the clearest remaining OpenAI provider-owned modern image gap:

- image editing: now has a package-owned modern helper

The next OpenAI decision is narrower now:

- keep image variation compatibility-only
- or add a later provider-owned variation helper only if a concrete app need
  appears
