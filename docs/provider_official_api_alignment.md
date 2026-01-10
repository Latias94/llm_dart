# Provider Official API Alignment (Gap Tracker)

This document is a *living* checklist to compare each shipped `llm_dart_*`
provider package against the provider's **official API surface** (excluding
deprecated/legacy features where practical).

Notes:

- “Official docs” are sometimes blocked by region/anti-bot in this environment.
  When that happens, this tracker records the limitation and relies on:
  - publicly available official OpenAPI specs (when available), and/or
  - live smoke checks (`tool/live_provider_alignment.dart`) using real keys.
- LLM Dart intentionally does **not** maintain a provider/model capability
  matrix. This tracker focuses on **API surface availability** and obvious
  implementation/typing gaps, not per-model behavior.

## Scope

- Included: providers shipped in this repo (`docs/providers/README.md`)
- Excluded: providers not supported in the umbrella package

## Legend

- ✅ Supported (implemented + covered by docs/tests)
- 🟡 Partial / best-effort / model-dependent
- ⬜ Not supported (non-deprecated feature exists in official API)
- 🚫 Out of LLM Dart scope (no standard surface yet)
- 🔒 Official docs not accessible from this environment

## Summary (by provider)

| Provider | Package | Official docs source(s) used | Doc access | Key surfaces in official API | LLM Dart coverage | Notable gaps (non-deprecated) |
|---|---|---|---|---|---|---|
| OpenAI | `llm_dart_openai` | OpenAPI spec: `https://app.stainless.com/api/spec/documented/openai/openapi.documented.yml` | ✅ | chat, responses, embeddings, images, audio, files, moderation, assistants, models | 🟡 | Realtime API (WebSocket), Batch, Fine-tuning, Vector stores management (beyond built-in tools) |
| Anthropic | `llm_dart_anthropic` | Live API + existing repo docs | 🔒 | messages, models, token count, files, tool use | 🟡 | Batches / additional endpoints (cannot confirm here due to docs access) |
| Google (Gemini) | `llm_dart_google` | `https://ai.google.dev/gemini-api/docs` | 🟡 | generateContent/stream, embeddings, file APIs, cached content, countTokens | 🟡 | Files API, cached contents, countTokens endpoint parity |
| Groq | `llm_dart_groq` | Live API + OpenAI-compatible baseline | 🔒 | OpenAI-compatible chat completions | 🟡 | Additional Groq-specific endpoints (docs blocked) |
| DeepSeek | `llm_dart_deepseek` | `https://api-docs.deepseek.com/` (+ sitemap) | ✅ | chat completions, completions, models, account/billing | 🟡 | Account/billing endpoints, completions/FIM guides as first-class APIs |
| xAI | `llm_dart_xai` | Live API + existing repo docs | 🔒 | OpenAI-compatible chat + Responses API + search | 🟡 | Official docs blocked (cannot enumerate extra endpoints) |
| OpenRouter | (config via) `llm_dart_openai_compatible` | `https://openrouter.ai/docs` | ✅ | OpenAI-compatible chat + routing/model APIs | 🟡 | OpenRouter model listing / credits endpoints (not exposed as first-class) |
| Ollama | `llm_dart_ollama` | `https://github.com/ollama/ollama/blob/main/docs/api.md` | ✅ | chat, generate, embeddings, model management | 🟡 | Pull/push/create/copy/delete/ps endpoints (not exposed) |
| MiniMax | `llm_dart_minimax` | `https://platform.minimax.io/docs/api-reference/text-anthropic-api` | 🟡 | Anthropic-compatible Messages API | ✅ | MiniMax OpenAI-compatible API surface (out of scope; provider targets Anthropic route) |
| ElevenLabs | `llm_dart_elevenlabs` | OpenAPI spec: `https://api.elevenlabs.io/openapi.json` | ✅ | TTS, STT, speech-to-speech, alignment, voices, history, workspace | 🟡 | Speech-to-speech, forced alignment, history/studio/workspace APIs, realtime session transport |

---

## Live smoke checks (this environment)

Ran:

- `dart run tool/live_provider_alignment.dart --providers=openai,anthropic,google,groq,deepseek,xai,xai.responses,openrouter,minimax,elevenlabs`

Results snapshot (no keys printed):

- OpenAI: `request_forbidden` (unsupported country/region/territory)
- Google: `QuotaExceededError` (free-tier quota limit reported as `0`)
- Groq: `Forbidden` (auth/region/account issue)
- MiniMax: `invalid api key` (for China region, set `MINIMAX_BASE_URL=https://api.minimaxi.com/anthropic/v1/`)
- OK: Anthropic, DeepSeek, xAI, xAI (Responses), OpenRouter, ElevenLabs (TTS)

## OpenAI (`llm_dart_openai`)

Official surfaces (from OpenAPI spec):

- ✅ Chat Completions: `POST /v1/chat/completions`
- ✅ Responses: `POST /v1/responses` + lifecycle operations (get/delete/cancel, list items)
- ✅ Embeddings: `POST /v1/embeddings`
- ✅ Images: `POST /v1/images/*`
- ✅ Audio: `POST /v1/audio/speech`, `POST /v1/audio/transcriptions`, `POST /v1/audio/translations`
- ✅ Files: `POST/GET/DELETE /v1/files`, `GET /v1/files/{id}/content`
- ✅ Moderation: `POST /v1/moderations`
- ✅ Assistants: assistants/threads/runs/messages
- ✅ Models: `GET /v1/models`
- 🚫 Fine-tuning / Batch / Administration APIs (not currently in LLM Dart surface)
- ⬜ Realtime API (WebSocket) (LLM Dart has `LLMCapability.realtimeAudio` but OpenAI provider does not implement it yet)

Notes:

- LLM Dart supports both OpenAI Chat Completions and the OpenAI-only Responses API.
  Responses is opt-in via `providerOptions['openai']['useResponsesAPI']` or when
  OpenAI built-in tools are configured.

## Anthropic (`llm_dart_anthropic`)

Doc access:

- 🔒 `platform.claude.com/docs/*` is unavailable in this environment (region block).

Verified via implementation + live checks:

- ✅ Messages API (chat + streaming)
- ✅ Tool use (function calling)
- ✅ Vision / reasoning (model-dependent)
- ✅ Models listing (Anthropic models endpoint)
- ✅ Token counting endpoint support (provider method)
- 🟡 Files API (implemented; should be validated with live checks)

## Google (Gemini) (`llm_dart_google`)

Official docs:

- `https://ai.google.dev/gemini-api/docs`

LLM Dart coverage:

- ✅ `generateContent` / streaming generate content
- ✅ Embeddings
- ✅ Provider-native web search tool injection (grounding)
- 🟡 Image generation (model-dependent; enabled via provider options)
- 🟡 Audio output / TTS via Gemini audio modality (exposed via provider-agnostic `TextToSpeechCapability`; requires a TTS-capable Gemini model)
- ⬜ Files API (upload/manage referenced files) as a first-class capability
- ⬜ Cached contents / context caching endpoints as a first-class API
- ⬜ Token counting endpoint parity (if/when supported in official API)

## DeepSeek (`llm_dart_deepseek`)

Official docs:

- `https://api-docs.deepseek.com/`

LLM Dart coverage:

- ✅ OpenAI-compatible Chat Completions (+ streaming)
- ✅ Tool calling (OpenAI-compatible)
- ✅ Model listing (`/models`)
- ⬜ Account/billing/user balance endpoints (exist in docs; not surfaced)
- 🟡 Legacy completions / prefix/FIM flows (documented; not a first-class API in `llm_dart_deepseek`)

## Ollama (`llm_dart_ollama`)

Official docs:

- `https://github.com/ollama/ollama/blob/main/docs/api.md`

LLM Dart coverage:

- ✅ Chat
- ✅ Generate (completion)
- ✅ Embeddings
- ✅ Model listing (tags)
- ⬜ Model management endpoints (pull/push/create/copy/delete/ps/version)

## OpenRouter (config-only; OpenAI-compatible)

Official docs:

- `https://openrouter.ai/docs`

LLM Dart coverage:

- ✅ OpenAI-compatible Chat Completions via `llm_dart_openai_compatible`
- 🟡 OpenRouter-specific behaviors (routing/model suffix conventions) via provider options
- ⬜ OpenRouter-native “models/credits” endpoints (not surfaced as first-class APIs)

## ElevenLabs (`llm_dart_elevenlabs`)

Official spec:

- `https://api.elevenlabs.io/openapi.json`

LLM Dart coverage:

- ✅ Text-to-speech (including streaming)
- ✅ Speech-to-text (transcription)
- ✅ Voices listing + basic voice settings defaults
- ✅ Speech-to-speech endpoints (provider-specific)
- ✅ Forced alignment endpoint (provider-specific)
- 🟡 Provider-specific helpers (`getModels`, `getUserInfo`) exist but are not standardized
- ⬜ History / Studios / Workspace APIs (official API groups exist)
- ⬜ Realtime session transport (official products exist; provider currently throws `UnsupportedError`)
