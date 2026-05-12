# Provider Utilities Policy

## Decision

`llm_dart_provider_utils` stays deferred for this breaking line.

There is no `packages/llm_dart_provider_utils` package in the current
workspace, and the first preview should not add one just to mirror the
reference architecture. Provider helper extraction must remain evidence-based.

## Extraction Criteria

A provider utility may become public only when all of these are true:

- at least two concrete provider packages need the same helper boundary
- the helper expresses provider implementation infrastructure, not runtime
  orchestration, UI projection, or root compatibility behavior
- the API can be named without leaking one provider's wire format into another
  provider's public contract
- the helper does not own HTTP transport concerns that belong in
  `llm_dart_transport`
- package-local helpers have already proven the shape through tests
- the extracted utility can be guarded by dependency policy

Until then, helpers stay package-local under provider `lib/src` code.

## What Remains Provider-Owned

Provider packages should keep their native product surfaces:

- OpenAI files, moderation, images, speech, transcription, Responses, hosted
  tools, and OpenAI-family profiles
- Anthropic files, token counting, MCP models, native tools, cache/replay
  helpers, and code execution replay
- Google files/cache, native tools, image, speech, and replay helpers
- Ollama model catalog, embedding, chat options, and local binary resolution
- ElevenLabs speech, transcription, voice catalog, and audio options

These are provider product features, not shared utilities.

## Non-Goals

- Do not extract a utility because two classes have similar names.
- Do not extract provider request builders into a shared package before the
  shared abstraction is stable.
- Do not move provider-native options into a lowest-common-denominator API.
- Do not use a future provider utility package to smuggle AI runtime, chat, UI,
  Flutter, root, or compatibility ownership back into provider packages.
