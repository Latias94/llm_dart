# 11 Ollama Chat Compatibility Thinning

## Why This Slice Exists

`lib/src/compatibility/providers/ollama/ollama_chat_compat.dart` was still one
of the clearest remaining mixed-responsibility hosts in the root compatibility
layer.

It combined:

- compatibility chat facade methods
- request-body shaping
- streamed JSON-line parsing
- response wrapper behavior

That made the fallback Ollama chat path harder to audit than necessary, even
though the provider shell above it was already using a cleaner bridge-versus-
fallback split.

## What Changed

This slice keeps the public compatibility entry stable while splitting the
remaining mixed ownership into narrower local files:

- `ollama_chat_compat.dart`
  - thin chat capability facade and fallback orchestration
- `ollama_chat_request_builder.dart`
  - Ollama request-body shaping
- `ollama_chat_stream_parser.dart`
  - streamed JSON-line parsing and completion event projection
- `ollama_chat_response.dart`
  - compatibility response wrapper

The public compatibility import path still exposes `OllamaChatResponse`
through `ollama_chat_compat.dart`.

## Why This Is Better

### 1. It separates shell orchestration from protocol details

The compatibility class now reads as a shell:

- validate base URL
- call the client
- delegate request shaping and stream parsing to local helpers

That is a better ownership split than one file mixing all four roles inline.

### 2. It makes the fallback path easier to compare with the bridge path

The Ollama provider already has a clearer bridge-versus-fallback shell through
`shell_support.dart`.

After this slice, the fallback chat module is easier to inspect in the same
terms:

- facade
- request codec
- stream parser
- response wrapper

### 3. It preserves compatibility behavior honestly

This slice is intentionally structural.

It does **not** claim that the fallback chat path is the same as the modern
community-model bridge.

It keeps the current fallback behavior intact, including:

- legacy request shaping
- current image-URL warning behavior
- current stream parsing order, where text deltas are emitted before a later
  bare `done` completion event

## Validation

This slice adds targeted compatibility coverage for:

- fallback request shaping plus response-wrapper behavior
- streamed thinking/text/completion event parsing

The existing provider bridge tests also stay green, so the bridge-versus-
fallback boundary remains stable.

## What Did Not Change

This slice does not:

- change `OllamaCompatShellSupport` bridge gating
- move more Ollama logic into the modern community package
- change the current fallback wire shape
- widen shared chat abstractions

Those are separate questions.

## Why This Matches The Current Refactor Direction

The useful lesson from `repo-ref/ai` is ownership clarity, not file-count
symmetry.

This slice follows that lesson by separating:

- compatibility shell orchestration
- request shaping
- stream parsing
- response wrapper behavior

without pretending the compatibility fallback path is itself a new modern API.

## Bottom Line

This was a real mixed-ownership cleanup:

- `OllamaChat` is now thinner
- request, parser, and response logic have clearer local homes
- fallback behavior remains stable
- the root compatibility layer becomes easier to audit
