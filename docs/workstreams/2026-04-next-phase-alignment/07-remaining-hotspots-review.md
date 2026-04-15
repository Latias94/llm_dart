# Remaining Hotspots Review

## Goal

Record which remaining large files still matter architecturally after the
OpenAI text-path split and the core serialization cleanup.

This note is intentionally about internal boundary pressure, not package-count
symmetry with `repo-ref/ai`.

## Context

As of 2026-04-15, the repository has already completed the highest-value
alignment work in this phase:

- focused `llm_dart_core` entrypoints exist and are adopted
- OpenAI text generation now has a clear facade / request / response / stream
  split
- shared serialization JSON support is extracted inside `llm_dart_core`

That changes the next question from “what is still big?” to “what is still big
and architecturally mixed?”

## Findings

### 1. OpenAI Non-Text Models Are Not The Same Problem As The Text Codec

The remaining OpenAI capability files are:

- `packages/llm_dart_openai/lib/src/openai_image_model.dart`
- `packages/llm_dart_openai/lib/src/openai_embedding_model.dart`
- `packages/llm_dart_openai/lib/src/openai_speech_model.dart`
- `packages/llm_dart_openai/lib/src/openai_transcription_model.dart`

Compared with `repo-ref/ai`, the important signal is **not** that these should
all be split into many files immediately.

The reference implementation does separate capabilities into dedicated folders,
but its non-text models are still mostly thin request/response wrappers, not a
four-layer parser architecture like streamed text generation.

### Decision

Do **not** copy the OpenAI text-codec split mechanically into embedding,
speech, or transcription.

The right move is smaller:

- keep capability ownership inside `llm_dart_openai`
- extract repeated internal support only when at least two non-text models need
  the same behavior
- reserve codec-style splitting for the specific models that truly mix multiple
  transports or multiple payload shapes

## 2. `openai_image_model.dart` Is The Only Non-Text File That Looks Split-Worthy

`openai_image_model.dart` currently combines:

- provider shell setup
- JSON request building for image generation
- multipart request building for image editing
- edit-specific validation
- JSON response decoding
- media-type and filename helpers

This is broader than the other non-text model files because image generation
and image editing are two different outbound shapes with different validation
and decoding concerns.

### Decision

`openai_image_model.dart` is the strongest candidate for a later internal split,
but the split should stay modest:

- request building and validation
- response decoding
- shared image/media helper support

This still does **not** justify a new package or a `provider-utils` style
published boundary.

### Update After Follow-On Refactor

That modest split is now complete:

- request building is separated from the facade
- response decoding is separated from the facade
- shared validation, response-format, and media helpers are separated into a
  small internal support layer

So the file now follows the same architectural direction as the text-path work
at a much smaller scale: a thin capability facade over internal request,
response, and support responsibilities.

Just as importantly, this stopped **before** introducing a fake codec stack or
a new published package boundary.

## 3. Embedding, Speech, And Transcription Should Stay Simpler For Now

`openai_embedding_model.dart`, `openai_speech_model.dart`, and
`openai_transcription_model.dart` currently have some repeated structure:

- `apiKey` / `baseUrl` / `profile` / `transport` / `settings`
- `defaultHeaders`
- typed provider-options validation
- narrow response decoding helpers

That repetition is real, but each file is still conceptually single-purpose.

### Decision

The next worthwhile seam here is a **shared internal OpenAI model shell
support**, not per-capability file explosion.

If extracted later, that support should cover only repeated infrastructure such
as:

- default header assembly
- provider-options casting helpers
- JSON / bytes response normalization
- media-type or filename helpers when truly shared

It should **not** become a generic new package or a cross-provider runtime
layer.

### Update After Follow-On Refactor

That shared internal shell support is now extracted at a deliberately small
scope:

- repeated OpenAI-family default header assembly
- typed model-settings validation
- typed provider-options validation
- shared JSON-object decoding helpers for non-text response paths

This means embedding, speech, image, and transcription can now stay as
capability-owned files while reusing the same low-level shell helpers.

The repository still intentionally does **not** have a published
`provider-utils` style package. The support remains private implementation
infrastructure inside `llm_dart_openai`.

## 4. The Next Real Core Hotspot Is `chat_ui_accumulator.dart`, Not `StreamTextRunner`

`StreamTextRunner` is still intentionally narrow, but it is no longer the main
internal concentration point by file structure.

The more mixed file is now:

- `packages/llm_dart_core/lib/src/ui/chat_ui_accumulator.dart`

It currently owns several concerns at once:

- text and reasoning part lifecycle projection
- tool input / call / result / approval state projection
- finish / abort / metadata projection
- raw-chunk capture policy
- state hydration from an existing seeded UI message

That is still a valid package boundary, but it is the clearest remaining
internal “many concerns meet here” point inside `llm_dart_core`.

### Decision

If the next core refactor continues, `chat_ui_accumulator.dart` should be
treated as the primary internal seam.

The right split is **by projection responsibility**, not by public API:

- text / reasoning lanes
- tool lifecycle projection
- output projection for source, file, reasoning-file, and custom parts
- message metadata projection
- seed/index hydration

The shared `TextStreamEvent` surface should stay unchanged.

### Update After Follow-On Refactors

The first internal cuts are now complete:

- tool lifecycle projection is split into dedicated support
- text / reasoning lane projection is split into dedicated support
- metadata projection is split into dedicated support
- output projection is split into dedicated support
- seed/index hydration is split into dedicated support

That means the file is still the public facade and routing point, but it no
longer mixes the full set of projection implementations inline.

The remaining logic inside the main file is now much narrower:

- the public constructor and message snapshot facade
- event routing in `apply(...)`
- data-part upsert behavior
- small shared append / lookup / metadata helpers

So `chat_ui_accumulator.dart` is no longer the same class of hotspot it was at
the start of this review. If more work is needed later, the next likely cut is
isolating data-part upsert behavior rather than reopening event-surface design.

## 5. `openai_responses_request_encoder.dart` Is Large, But Mostly Cohesive

`openai_responses_request_encoder.dart` remains very large, but its size is not
the same as architectural confusion.

Most of its weight is still within one ownership boundary:

- prompt replay encoding
- user-part encoding
- assistant/tool replay shaping
- Responses compatibility shaping
- tool encoding
- structured-output encoding

### Decision

This file should only be split when it materially improves readability inside
the same request-encoding boundary.

The best future cut is by outbound concern, for example:

- compatibility shaping
- prompt/replay encoding
- tools and response-format encoding

It should **not** be split just because it is large.

## Recommended Order

If another refactor slice starts immediately after this review, the best order
is:

1. keep OpenAI text-path work frozen unless a bug appears
2. extract a small shared internal shell for repeated OpenAI non-text model
   infrastructure only if it removes real duplication
3. keep embedding, speech, and transcription simpler until repeated
   infrastructure pressure is concrete across at least two files

## What Should Stay Deferred

The following moves still look premature:

- a new published `provider-utils` style Dart package
- codec-style layering for every non-text OpenAI model
- widening shared core for provider-native approval or continuation behavior
- package-count parity with `repo-ref/ai`

## Bottom Line

The remaining architecture pressure is now more selective:

- **next smaller core seam if needed:** `ChatUiAccumulator` data-part upsert
  behavior
- **next OpenAI support extraction candidate if duplication reappears:**
  additional non-text response or media helpers
- **next large-but-cohesive file to watch:** `openai_responses_request_encoder.dart`

Everything else should remain frozen until real implementation pressure appears.
