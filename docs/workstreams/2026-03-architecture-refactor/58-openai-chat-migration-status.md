# OpenAI Chat Migration Status

## Purpose

This note reconciles the current OpenAI-family chat migration status against `repo-ref/ai`, with a focus on the migrated chat-completions path in `llm_dart_openai`.

The goal is not to force package-count parity with the reference. The goal is to make the remaining gaps explicit so the refactor can proceed intentionally.

## Current State

The migrated OpenAI-family text path is split into two main lines:

- OpenAI proper defaults to the Responses API mainline.
- non-Responses OpenAI-family profiles such as DeepSeek, Groq, OpenRouter, xAI, and Phind use the migrated chat-completions mainline.
- OpenAI itself can also opt out of Responses and use the migrated chat-completions path through `useResponsesApi: false`.

The current chat-completions codec already covers:

- text prompt encoding
- user image prompt encoding
- function-tool declaration and tool choice
- assistant function-call replay for the common subset
- tool-result replay for the common subset
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

This keeps the mapping aligned with the reference without widening the shared prompt model.

## Deliberate Limits

The following limits are still intentional for now:

- audio and PDF file parts with `uri` are rejected
  - this matches the reference direction for URL-backed audio/PDF on the chat-completions path
  - it avoids freezing a weak URL-handling contract before we decide whether provider-owned file handles need a typed path
- provider-owned PDF file-ID replay is still not exposed on the migrated chat-completions path
  - the shared `FilePromptPart` model should not be stretched into an OpenAI-only file-handle transport by accident
  - if we later need this, it should be frozen as a provider-owned hint contract, not as an implicit reinterpretation of `uri`
- assistant replay is still conservative
  - reasoning prompt parts, reasoning-file prompt parts, custom prompt parts, file prompt parts, image prompt parts, and approval prompt parts still downgrade to warnings or rejection where exact replay is not yet safe

## Why Compatibility Routing Stays Conservative

The legacy OpenAI compatibility provider is still Responses-first.

That matters because:

- `buildCompatOpenAIProvider(...)` currently builds the migrated OpenAI model with `useResponsesApi: true`
- the legacy chat adapter already converts legacy image/file messages into `ImagePromptPart` and `FilePromptPart`
- the migrated Responses codec still only accepts text user parts today

So even though the migrated chat-completions path is now better aligned, that change alone does not make the compatibility route safe for multimodal OpenAI traffic.

Until either:

- the Responses codec gains equivalent user multimodal support, or
- the compatibility provider becomes request-shape aware and can switch mainlines safely,

the OpenAI compatibility gate should stay conservative.

## Remaining Gaps Before `Complete OpenAI chat migration`

`Complete OpenAI chat migration` should still remain open after this slice.

The meaningful remaining gaps are now:

- broadened assistant replay fidelity on chat-completions
- a frozen provider-owned contract if OpenAI chat-completions later needs file-ID hints
- a decision on whether the OpenAI compatibility route should stay Responses-first or become request-shape aware
- possible multimodal parity on the Responses request codec, if compatibility or app usage proves it is necessary

## Recommended Next Step

The next OpenAI-family step should focus on one of these two paths, not both at once:

1. finish more assistant replay on chat-completions if replay fidelity is the blocker
2. clarify the Responses-vs-chat-completions compatibility routing policy if legacy multimodal migration becomes the blocker

That keeps the workstream incremental and prevents the OpenAI family from becoming another mixed-path bus layer.
