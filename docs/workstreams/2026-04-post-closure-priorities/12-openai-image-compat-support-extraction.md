# 12 OpenAI Image Compatibility Support Extraction

## Why This Slice Exists

`lib/src/compatibility/providers/openai/images.dart` was still carrying several
different responsibilities at once:

- compatibility image capability methods
- generation request-body shaping
- edit and variation multipart shaping
- image response parsing
- base64 decode and response validation

That made the root OpenAI image compatibility path heavier than necessary, even
though the broader OpenAI provider shell had already been thinned in earlier
slices.

## What Changed

This slice extracts provider-local request and response shaping into:

- `lib/src/compatibility/providers/openai/openai_image_support.dart`

The public compatibility entry stays the same:

- `lib/src/compatibility/providers/openai/images.dart`

The split is intentionally narrow:

- `OpenAIImages` remains the capability shell and endpoint orchestrator
- `OpenAIImageSupport` now owns generation request shaping, edit/variation
  multipart shaping, and image response parsing

## Why This Is Better

### 1. It separates transport-facing orchestration from codec work

The compatibility class now reads more like a shell:

- choose the endpoint
- call the client
- delegate request shaping and response parsing to support code

That is a clearer ownership split than one file holding all the protocol detail
inline.

### 2. It keeps generation/edit/variation behavior localized together

OpenAI image compatibility still has one provider-local subdomain:

- image-generation request shaping
- image-edit multipart shaping
- image-variation multipart shaping
- image response decoding

Those belong together more naturally in one provider-owned support helper than
spread across the capability shell.

### 3. It preserves compatibility behavior honestly

This slice is structural only.

It does **not** change current compatibility behavior, including:

- the current generation request fields
- the current edit and variation multipart field names
- the current PNG filename and media-type defaults
- the current image response parsing and revised-prompt projection

## Validation

This slice adds targeted compatibility coverage for:

- generation request shaping plus image parsing
- edit multipart field and file shaping
- variation multipart field and file shaping

## What Did Not Change

This slice does not:

- route image calls through a new modern package bridge
- widen the shared image model
- change the root compatibility image API
- revisit OpenAI image variation policy

Those are separate questions.

## Why This Matches The Current Refactor Direction

The useful lesson from `repo-ref/ai` is ownership clarity, not file-count
symmetry.

This slice follows that lesson by separating:

- compatibility shell orchestration
- provider-local request shaping
- provider-local response parsing

without pretending the root compatibility image path is a new modern API.

## Bottom Line

This was a worthwhile support extraction:

- `OpenAIImages` is thinner
- image request and response shaping now have a clearer local home
- compatibility behavior stays stable
- the root OpenAI compatibility layer becomes easier to audit
