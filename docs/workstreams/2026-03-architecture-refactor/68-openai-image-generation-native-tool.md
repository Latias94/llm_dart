# OpenAI Image Generation Native Tool

## Purpose

This note records the first follow-up implementation after the OpenAI Responses
persistence subset landed.

The goal was to pick one OpenAI-native tool family that improves structural
alignment without dragging the provider package into agent-runtime complexity.

The selected first slice is:

- `image_generation`

## What Landed

`llm_dart_openai` now exposes a first-class provider-owned OpenAI native tool
surface for image generation:

- `OpenAIImageGenerationTool`
- `OpenAIImageGenerationInputFidelity`
- `OpenAIImageGenerationModeration`
- `OpenAIImageGenerationSize`
- `OpenAIImageMask`
- `OpenAIBuiltInTools.imageGeneration(...)`

The OpenAI package also now aligns better with the repository-wide native-tool
entry rule:

- model defaults can carry built-in tools through `OpenAIChatModelSettings.builtInTools`
- per-call overrides still use `OpenAIGenerateTextOptions.builtInTools`
- call-level provider options override model defaults instead of merging

## Why `image_generation` Was Chosen First

This tool family has a good value-to-complexity ratio:

- it is clearly OpenAI-native
- its declaration shape is stable and request-side only
- it does not require widening shared `ToolChoice`
- it does not require immediate replay of execution-heavy provider-owned results

That makes it a better first tool-surface candidate than `mcp`, `shell`,
`apply_patch`, or `tool_search`.

## What Did Not Land

This slice does **not** add:

- provider-owned native-tool forcing or selection APIs
- richer replay contracts for image-generation result items
- shared-core changes for tool-result typing
- any `mcp` declaration surface

The current implementation is only about provider-owned declaration and request
encoding.

## Remaining OpenAI Tool Question

The next OpenAI native-tool decision is now narrower:

- whether `mcp` deserves a first-class provider-owned declaration surface soon
- or whether it should stay deferred until a concrete continuation-heavy use
  case appears

## Bottom Line

`image_generation` is now the first OpenAI-native tool family that follows the
provider-owned entry direction more cleanly in `llm_dart_openai`.

This improves structural alignment without widening the shared core or dragging
the package into premature execution-runtime abstractions.
