# OpenAI Chat Migration Status

## Purpose

This note reconciles the current OpenAI-family chat migration status against `repo-ref/ai`, with a focus on the migrated chat-completions path in `llm_dart_openai`.

The goal is not to force package-count parity with the reference. The goal is to make the remaining gaps explicit so the refactor can proceed intentionally.

## Current State

The migrated OpenAI-family text path is split into two main lines:

- OpenAI proper defaults to the Responses API mainline.
- non-Responses OpenAI-family profiles such as DeepSeek, Groq, OpenRouter, xAI, and Phind use the migrated chat-completions mainline.
- OpenAI itself can also opt out of Responses and use the migrated chat-completions path through `useResponsesApi: false`.

The current Responses path now also covers the common user multimodal subset that the legacy OpenAI compatibility layer depends on:

- `ImagePromptPart` maps to `input_image`
- image-shaped `FilePromptPart` also maps to `input_image`
- byte-backed generic `FilePromptPart` maps to `input_file`
- common assistant function-tool replay and user tool-result replay already map through the migrated Responses codec
- provider-owned system-message shaping for `system`, `developer`, and `remove`
- provider-owned OpenAI reasoning-model request shaping for `reasoningEffort` and `forceReasoning`
- OpenAI-only reasoning-model parameter compatibility and `serviceTier` validation

The current chat-completions codec already covers:

- text prompt encoding
- provider-owned system-message role shaping for `system`, `developer`, and `remove`
- provider-owned OpenAI reasoning-model request shaping for `reasoningEffort`, `maxCompletionTokens`, and `forceReasoning`
- OpenAI-only reasoning-model parameter compatibility and `serviceTier` validation
- user image prompt encoding
- user file prompt encoding for image, audio, and PDF
- function-tool declaration and tool choice
- assistant function-call replay for the common subset
- tool-result replay for the common subset
- provider-owned `logprobs` request encoding and decode
- reasoning text decode
- streamed reasoning, text, and tool-input aggregation
- xAI citation decode

## `repo-ref/ai` Comparison

`repo-ref/ai/packages/openai/src/chat/convert-to-openai-chat-messages.ts` currently supports these user file-input shapes on the chat-completions path:

- image file parts mapped to `image_url`
- audio file parts mapped to `input_audio`
- PDF file parts mapped to `file`
- PDF file IDs on the OpenAI-specific path
- default PDF filenames when no explicit filename is provided

That means our migrated chat-completions path was still behind the reference in one concrete way:

- `FilePromptPart` was not yet encoded at all for user messages

## Scope Landed In This Slice

The migrated chat-completions path now supports `FilePromptPart` for user messages in the following safe subset:

- `image/*`
  - encoded as `image_url`
  - bytes become a data URL
  - URI-backed images remain allowed
- `audio/wav`
  - encoded as `input_audio.format = "wav"`
  - bytes are required
- `audio/mpeg`
- `audio/mp3`
  - both encode as `input_audio.format = "mp3"`
  - bytes are required
- `application/pdf`
  - encoded as `file.file_data`
  - bytes are required
  - default filename becomes `part-{index}.pdf` when not provided

The OpenAI-family codecs also now expose a provider-owned hint path for input shaping without widening the shared prompt model:

- `PromptPart.providerMetadata['openai']['fileId']`
- `PromptPart.providerMetadata['openai']['imageDetail']`

That provider-owned hint contract is frozen in `59-openai-provider-owned-input-hints.md`.

This keeps the mapping aligned with the reference without widening the shared prompt model.

The Responses path also now covers the user multimodal subset that the legacy compatibility route already relied on in the old provider implementation:

- `ImagePromptPart`
- image-shaped `FilePromptPart`
- byte-backed generic `FilePromptPart`

## Deliberate Limits

The following limits are still intentional for now:

- audio and PDF file parts with `uri` are rejected
  - this matches the reference direction for URL-backed audio/PDF on the chat-completions path
  - it avoids freezing a weak URL-handling contract before we decide whether provider-owned file handles need a typed path
- generic file prompt parts with `uri` are still rejected on the migrated Responses path
  - this keeps the Responses codec aligned with the old compatibility subset, which only ever carried file bytes
- assistant replay is still conservative
  - reasoning prompt parts, reasoning-file prompt parts, custom prompt parts, file prompt parts, image prompt parts, and approval prompt parts still downgrade to warnings or rejection where exact replay is not yet safe

## Compatibility Routing Conclusion

The legacy OpenAI compatibility provider is still Responses-first.

That is now acceptable for the current audited subset because:

- `buildCompatOpenAIProvider(...)` still builds the migrated OpenAI model with `useResponsesApi: true`
- the legacy chat adapter already converts legacy image/file messages into `ImagePromptPart` and `FilePromptPart`
- the migrated Responses codec now accepts that common user multimodal subset
- the OpenAI compatibility gate can now safely allow user image/file traffic without introducing dynamic mainline switching

The compatibility route should still stay conservative for:

- assistant-side multimodal replay beyond the common function-tool subset
- approval-gated continuation
- any future provider-owned file-handle contract

## Remaining Gaps Before `Complete OpenAI chat migration`

`Complete OpenAI chat migration` should still remain open after this slice.

The meaningful remaining gaps are now:

- optional richer provider-native or multimodal assistant replay on
  chat-completions beyond the now-aligned common text/tool-call/tool-result
  subset
- possible richer multimodal parity on the Responses request codec beyond the current user image/file subset, if app usage proves it is necessary
- any future OpenAI-owned helper surface above raw provider metadata if Flutter or app-level tooling later needs richer logprob/result inspection
- any later OpenAI-owned search-preview or other model-family request-shaping audit beyond the now-aligned chat-completions and Responses reasoning compatibility
- a decision on whether OpenAI compatibility should ever broaden beyond the current user multimodal plus common function-tool replay subset into richer replay-heavy histories

## Recommended Next Step

The next OpenAI-family step should focus on one of these two paths, not both at once:

1. add richer provider-native replay on chat-completions only if a real product history shape proves the current aligned common subset is insufficient
2. audit whether the Responses path needs any richer multimodal, persistence-owned request shaping, or replay support beyond the now-working user image/file plus common function-tool compatibility subset

That keeps the workstream incremental and prevents the OpenAI family from becoming another mixed-path bus layer.
