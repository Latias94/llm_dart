# 125. Google Provider-Owned Image Edit Helper

## Decision

Google image editing and variation should gain a provider-owned modern helper in
`llm_dart_google`.

They should **not** be migrated by widening the shared `ImageModel` contract in
the current round.

## Why

The earlier Google residual-API classification showed that image editing was
the clearest remaining Google gap where:

- the root compatibility layer still exposed real user-facing value
- `llm_dart_google` still lacked an equivalent modern path
- `repo-ref/ai` already handled the workflow through the provider-owned Google
  image model path instead of keeping it trapped in a legacy root surface

At the same time, the current shared image contract is still intentionally
narrow:

- prompt
- count
- size
- generic call options

It does not yet model provider-neutral editing inputs such as:

- reference image files
- provider-supported file URLs
- provider-specific image-edit restrictions

So widening shared core first would have been the wrong sequencing.

## What Landed

The modern Google package now exposes provider-owned editing helpers on the
concrete `GoogleImageModel` type:

- `edit(GoogleImageEditRequest request)`
- `createVariation(GoogleImageVariationRequest request)`

New typed provider-owned request shapes:

- `GoogleImageEditInput`
- `GoogleImageEditRequest`
- `GoogleImageVariationRequest`

These helpers return the same shared `ImageGenerationResult`, so apps still get
the normal generated-image output surface without creating a second result
model.

## Boundary

### Shared core stays unchanged

No shared-core image contract changes were required:

- `ImageModel.generate(...)` stays as-is
- `ImageGenerationRequest` stays generation-oriented
- no provider-neutral edit/file input model was added

### The new helper is provider-owned

Editing remains intentionally Google-shaped:

- it lives on the concrete `GoogleImageModel`
- it accepts provider-owned typed request models
- it uses `GoogleImageOptions` through normal `CallOptions.providerOptions`

This matches the broader architecture rule already used elsewhere in the
repository:

- keep shared core honest and narrow
- add provider-owned helpers only for concrete provider-native workflows

## Current Capability Scope

The landed helper currently supports:

- Gemini image models only
- direct in-memory image bytes
- provider-supported file URIs through `fileData`
- Google aspect-ratio and safety shaping through `GoogleImageOptions`
- provider-owned variation convenience by routing through the edit helper with
  a default variation prompt

## Explicit Non-Goals

This helper intentionally does **not** add:

- Imagen editing support
- mask-based inpainting
- a broader shared image-edit contract
- compatibility-era `ImageEditRequest` or `ImageVariationRequest` reuse
- root compatibility API removal in the same round

Those are separate questions.

## Why This Is Better Than Reusing The Legacy Root API

Reusing the old root image-edit API directly would have preserved several
problems:

- OpenAI-shaped request types inside the modern Google package
- a misleading shared edit contract that the core still does not own
- another round of root-surface coupling hidden behind migration wording

The provider-owned helper path avoids that.

## Roadmap Consequence

This closes one of the three real remaining Google migration candidates:

- image editing / variation: now has a provider-owned modern path
- streamed TTS: still open
- provider-owned file-upload utility: still open

The next Google-specific decision should therefore focus on streamed TTS or
leave Google alone and move to Anthropic.
