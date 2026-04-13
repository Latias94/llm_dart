# 177 Google File And Cache Boundary

## Why This Decision Exists

After the recent Google refactor rounds, one explicit open item remained:

- should Google file-upload and cache helpers stay compatibility-only
- or should `llm_dart_google` gain a provider-owned utility surface for them

This question matters because Google exposes several related but different
concepts:

- prompt-side `fileData.fileUri`
- image-edit input file URIs
- server-side `cachedContent` references
- the older Files API upload flow and local upload-cache helpers

Treating all of those as one feature would create a misleading abstraction.

## What Was Reviewed

Modern package-owned Google surface:

- `packages/llm_dart_google/lib/src/google_generate_content_codec.dart`
- `packages/llm_dart_google/lib/src/google_image_model.dart`
- `packages/llm_dart_google/lib/src/google_image_editing.dart`
- `packages/llm_dart_google/lib/src/google_options.dart`

Legacy compatibility-owned Google surface:

- `lib/src/compatibility/providers/google/chat.dart`

Earlier classification note:

- `docs/workstreams/2026-03-architecture-refactor/124-google-residual-api-classification.md`

## Current Reality

### What The Modern Package Already Supports

`llm_dart_google` already supports the provider-owned parts that matter most for
the modern model path:

- prompt parts can encode `fileData.fileUri`
- Google image editing can accept URI-backed edit inputs
- text generation already exposes `GoogleGenerateTextOptions.cachedContent`

So the modern package already supports:

- using a previously available Google file URI in prompting
- using a previously available Google file URI in image editing
- referencing a previously created Google cached-content resource

### What The Modern Package Does Not Yet Support

The package does **not** currently expose a typed utility for:

- uploading files to the Google Files API
- creating or managing server-side cached-content resources
- storing local upload/cache entries across requests

### What The Legacy Compatibility Layer Still Does

The old Google compatibility path still contains:

- `GoogleFile`
- `uploadFile(...)`
- `getOrUploadFile(...)`
- a static in-memory upload cache

That helper is tightly coupled to:

- old compatibility transport choices
- mutable process-local caching
- old chat-surface expectations
- the old root compatibility shell

It is not yet a good candidate to move into the modern provider package as-is.

## Frozen Decision

Google file-upload helpers and Google cache-management helpers should remain
**compatibility-only residual APIs for now**.

The modern provider package should keep only the already-justified provider
surfaces:

- file URI based prompt and image inputs
- `cachedContent` as a provider-owned request reference field

It should **not** yet add:

- `uploadFile(...)`
- `getOrUploadFile(...)`
- a mutable local upload cache
- a generic Google file-management utility surface
- a cache-management utility surface

## Why This Boundary Is Better

### 1. It matches the reference signal more honestly

The reference package treats supported Google file URLs as prompt capability,
not as a general file-management API commitment.

That is a useful constraint here too.

### 2. It avoids baking unstable storage semantics into the provider package

A real provider-owned upload utility would need clear answers for:

- what a stable Google file handle looks like
- which resources are reusable across text, image, and future audio flows
- whether local dedupe/cache policy belongs in the provider package at all
- whether cached-content creation belongs with file helpers or with text
  generation orchestration

Those answers are not frozen yet, so adding an API now would likely create
another migration surface to undo later.

### 3. The high-value product path is already covered

The modern package can already consume:

- inline bytes where Google supports them
- explicit file URIs where Google supports them
- existing `cachedContent` handles for text generation

That means the main application path is not blocked on a public upload helper.

### 4. It keeps dependency direction clean

If a file-management utility is ever added later, it should be a separate
provider-owned utility layer above transport primitives, not something hidden
inside the language model, image model, or shared core.

## Allowed Current Surface

The following current shapes stay valid:

- `GoogleGenerateTextOptions.cachedContent`
- prompt parts that carry URI-backed file input
- `GoogleImageEditInput.uri(...)`

These are request-time provider-owned references, not file-management APIs.

## If We Add Something Later

Any future modern Google file/cache utility should satisfy all of the following:

- separate provider-owned utility surface, not shared-core expansion
- explicit typed handle model instead of leaking raw legacy `GoogleFile`
- no hidden global mutable cache
- no assumption that upload, cache creation, and prompt replay are one API
- justified by concrete app demand, not by symmetry with legacy helpers

## Non-Goals

This decision does not:

- remove the old compatibility helpers yet
- change current `cachedContent` request encoding
- add cache-creation support to the modern text API
- invent a cross-provider file abstraction

## Conclusion

Google is now in the same policy state as OpenAI and Anthropic on this point:

- file-management style helpers remain compatibility-only unless a concrete
  product need proves a stable provider-owned utility contract
- modern model APIs continue to accept provider-owned file references where the
  actual request protocol already supports them

That means Google file upload and cache management are no longer “unfinished
migration work” by default. They are explicit deferred provider-owned utility
candidates.
