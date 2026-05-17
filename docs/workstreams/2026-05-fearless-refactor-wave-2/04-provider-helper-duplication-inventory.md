# Provider Helper Duplication Inventory

## Objective

Inventory repeated provider helper patterns across focused provider packages
and decide whether any pattern justifies a public `llm_dart_provider_utils`
package.

This inventory is evidence for a later decision. It does not extract a utility
package and does not change provider implementation code.

## Evidence Command

Representative search used for this inventory:

```powershell
rg -n "normalize.*BaseUrl|build.*Filename|normalize.*MediaType|require.*NonEmpty|normalize.*Json|asJsonMap|ensureJsonValue|ProviderReference|requireProvider|base64Encode|data:.*base64|ModelWarning|warnings\.add|stream.*state|Tool.*Delta|partialJson" packages\llm_dart_openai\lib\src packages\llm_dart_anthropic\lib\src packages\llm_dart_google\lib\src packages\llm_dart_ollama\lib\src packages\llm_dart_elevenlabs\lib\src -g "*.dart"
```

## Inventory

### JSON Normalization And Object Validation

Observed in:

- OpenAI request/tool output encoding
- Anthropic request JSON, content encoding, tool replay, code execution replay,
  files, and MCP models
- Google replay helpers and content projection support
- Ollama tool codec

Existing shared foundation:

- `llm_dart_provider` already owns `normalizeJsonValue`, `asJsonMap`, and
  related JSON-safe helpers.

Assessment:

- Do not publish a new public utility for this yet.
- First action should be to make sure providers consistently use the existing
  provider-owned JSON helpers before inventing a new package.

Potential future extraction:

- only if providers need helper behavior that does not belong in
  `llm_dart_provider` contracts, such as path-rich parse errors or reusable
  schema normalization policies

### Required Non-Empty String Helpers

Observed in:

- OpenAI files, moderation, responses lifecycle
- Anthropic files and code execution replay
- Google function response replay and server tool replay
- Ollama model catalog

Assessment:

- repeated shape is real
- semantics are still provider/product-specific because paths and error
  messages differ

Recommendation:

- keep provider-local for now
- consider an internal helper only after at least two packages need identical
  path/error behavior

### Media Type And Data URI Helpers

Observed in:

- OpenAI image/file prompt encoding and image output filename building
- Anthropic image/document media type normalization
- Google replay file encoding
- Ollama image byte encoding
- ElevenLabs audio filename/media type helper

Assessment:

- repeated enough to track
- provider semantics differ: OpenAI needs data URLs and output format mapping,
  Anthropic distinguishes image/document media families, Google replay uses
  Gemini `inlineData`/`fileData`, ElevenLabs maps audio output filenames

Recommendation:

- no public utility yet
- candidate for a private or future public media helper only if a stable,
  provider-neutral API emerges around:
  - top-level media type detection
  - extension lookup
  - data URI formatting
  - base64 validation

### Provider Reference Resolution

Observed in:

- OpenAI prompt and tool output encoding through `ProviderReference`
- Anthropic file ID encoding
- Google function/server tool replay helpers

Existing shared foundation:

- `ProviderReference.requireProvider(...)` already lives in
  `llm_dart_provider`.

Assessment:

- current shared primitive is likely sufficient
- provider-specific mapping from a reference into wire fields should stay
  provider-owned

Recommendation:

- do not extract more until two providers need identical reference-resolution
  policy beyond `requireProvider(...)`

### Warning Construction

Observed in:

- OpenAI chat completions, responses, speech, and options codecs
- Anthropic prompt/options/tool encoding
- Google generation/tool configuration
- Ollama request/tool codecs

Assessment:

- repeated pattern is real: append `ModelWarning` for unsupported or
  compatibility behavior
- warning text and compatibility rules are provider-specific

Recommendation:

- consider tiny provider-local helpers such as "add warning once"
- do not publish shared warning builders until warning categories and messages
  repeat exactly across providers

### Stream Tool Delta Accumulation

Observed in:

- OpenAI stream support and stream tool codecs
- Google stream part codec/state
- Ollama stream codec
- Anthropic stream tool codec/state

Assessment:

- this is the most tempting shared helper area
- it is also high-risk because provider event shapes and partial tool input
  semantics differ

Recommendation:

- do not create a generic public stream codec abstraction
- a future `streaming-tool-call-tracker`-style helper can be considered only if
  it is provider-neutral, has isolated tests, and does not own provider event
  vocabulary

### Base URL Normalization

Observed in:

- Ollama
- ElevenLabs
- Google model URLs
- Anthropic API URI resolution

Assessment:

- repeated but trivial
- not worth a public package

Recommendation:

- keep provider-local

## Provider Utils Decision

Do not publish `llm_dart_provider_utils` in this wave.

Current duplication does not yet prove a stable public helper contract. The
strongest future candidates are:

1. media type/data URI helpers
2. path-rich JSON validation helpers
3. provider-neutral streaming tool-call delta tracking

But each still needs a focused design and tests before becoming public API.

## Next Action

If provider-utils work resumes, start with one package-private experiment:

- choose one helper family
- implement it in one provider package behind `src/internal`
- migrate one other provider only if the semantics are identical
- add tests before considering a public package

This avoids creating a shared framework that later has to support provider
native behavior it should never own.
