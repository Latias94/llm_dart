# 09 Google Image Compatibility Support Extraction

## Why This Slice Exists

The remaining root Google image compatibility module was a better refactor
target than more Anthropic request-builder splitting.

`lib/src/compatibility/providers/google/images.dart` still mixed:

- compatibility capability methods
- HTTP endpoint routing
- Imagen request-body shaping
- Gemini request-body shaping
- image edit and variation request shaping
- Imagen response decoding
- Gemini response decoding
- MIME and aspect-ratio helpers

That is a real mixed-ownership file, unlike the Anthropic request builder that
is long but still one coherent request codec.

## What Changed

This slice extracts provider-local request and response shaping into:

- `lib/src/compatibility/providers/google/google_image_support.dart`

The public compatibility entry remains unchanged:

- `lib/src/compatibility/providers/google/images.dart`

The split is intentionally local:

- `GoogleImages` still owns capability methods, endpoint choice, logging, and
  HTTP dispatch
- `GoogleImageSupport` owns request-body construction, response parsing,
  aspect-ratio mapping, MIME mapping, and the shared variation prompt

## Why This Is Better

### 1. It separates dispatch from codec work

The compatibility class now reads more like an orchestration shell:

- choose Imagen versus Gemini
- call the client
- delegate request and response shaping to support code

That is closer to the repository's current direction for provider modules.

### 2. It keeps behavior stable

This slice does **not** route legacy image calls through the modern
`llm_dart_google` image model yet.

That is deliberate.

The modern provider-owned image model is stricter and more explicit around
typed options, while the root compatibility API still carries older request
fields and legacy config behavior.

So this slice reduces mixed ownership without silently changing compatibility
semantics.

### 3. It creates a safer future bridge point

If a later slice delegates a bridge-safe Google image subset into
`llm_dart_google`, the boundary is now easier to inspect:

- support functions show what the legacy wire shape currently does
- the compatibility class can add bridge/fallback routing without also owning
  all parsing details

## What Did Not Change

This slice does not:

- change the public `GoogleImages` API
- remove the root compatibility image surface
- widen the shared `ImageModel` contract
- change legacy edit or variation support
- add URL-input support to the root compatibility image edit path
- force `ImageGenerationRequest.size` into the modern Google provider-owned
  option model

## Validation

This slice adds targeted root compatibility coverage:

- Imagen predict request shaping and response parsing
- Gemini generateContent request shaping and revised-prompt parsing
- variation request reuse of the shared Gemini inline-image request builder

## Why This Matches The Reference Direction

The useful lesson from `repo-ref/ai` is not to copy every package boundary.

The useful lesson is to keep these roles separate:

- provider capability shell
- request encoding
- response decoding
- provider-owned richer APIs

This slice follows that lesson while preserving Dart compatibility behavior.

## Follow-Up

Do not immediately bridge all root Google image calls to the modern package.

Only add a bridge if a narrow compatibility-safe subset is proven, especially
around:

- legacy `size` behavior
- old config-level generation parameters
- Gemini multi-candidate behavior
- edit and variation request fields that the modern provider-owned helpers
  intentionally model differently

## Bottom Line

This was a worthwhile split because `GoogleImages` was mixing shell dispatch
with codec logic.

The result is a thinner compatibility image shell without pretending the old
root API and the modern Google image model are identical.
