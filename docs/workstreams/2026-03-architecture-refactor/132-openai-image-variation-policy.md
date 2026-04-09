# 132. OpenAI Image Variation Policy

## Decision

OpenAI image variation should remain compatibility-only for now.

It should **not** gain a provider-owned modern helper in `llm_dart_openai`
during the current refactor round.

If the project later needs a modern variation path, it should be added as a
narrow provider-owned helper on `OpenAIImageModel` rather than by widening the
shared `ImageModel` contract.

## Why This Needed To Be Explicit

The previous OpenAI residual classification identified image editing and image
variation together as the last meaningful image-shaped gap versus the root
compatibility provider.

That was enough to justify a second explicit decision, because grouping them
together too loosely would encourage the wrong next move:

- image editing already had a strong modern signal and real product value
- image variation looked similar on paper, but not in architectural priority
- without a freeze, the new provider package could easily keep growing by
  endpoint symmetry instead of by stable ownership rules

## Why Edit And Variation Are Not The Same

### Image editing still fits the modern provider-owned image surface

Image editing was worth landing because:

- `repo-ref/ai` already treats `/images/edits` as part of the modern OpenAI
  image model
- the root compatibility layer still exposed real user-facing editing value
- Flutter and app integrations can reasonably need multipart editing with
  masks, fidelity, and shared generated-image result decoding

### Image variation has a weaker modern signal

Image variation is different:

- it is a narrower endpoint with a more legacy-shaped product story
- it is not a core Flutter-chat-first capability
- it does not currently carry the same structural pressure as image editing
- adding it now would mostly be a parity move rather than a boundary-driven
  move

In other words, variation is not blocked by missing shared abstractions. It is
blocked by missing proof that it deserves a modern surface at all.

## Reference Signal From `repo-ref/ai`

The reference package gives a strong signal for modern OpenAI image editing.

It does **not** currently create the same implementation pressure to mirror a
separate modern image-variation helper in this repository. That makes
variation a poor candidate for "keep adding it because it is nearby."

The right lesson from the reference is restraint:

- copy ownership patterns when they clarify the main modern path
- do not copy every residual endpoint just because it exists on the same
  provider family

## Boundary Consequence

After this decision:

- shared `ImageModel` stays unchanged
- `llm_dart_openai` keeps the provider-owned modern edit helper only
- root `OpenAIProvider.createVariation(...)` remains part of the compatibility
  surface
- future OpenAI thinning can treat image variation as an explicit residual API,
  not as hidden unfinished migration work

## What Would Reopen This Decision

Revisit variation only if at least one of these becomes true:

- a concrete Flutter or app flow needs typed modern variation support
- the provider package gains multiple image-editing-adjacent helpers and the
  variation contract becomes obviously stable
- the reference surface or OpenAI product direction makes variation part of the
  clear mainline image model again

Until then, the better architectural move is to leave it in the compatibility
layer and avoid growing `llm_dart_openai` by inertia.
