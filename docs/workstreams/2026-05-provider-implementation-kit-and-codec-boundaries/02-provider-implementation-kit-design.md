# Provider Implementation Kit Design

## Principle

The provider implementation kit is a set of narrow helper boundaries, not a new
framework. It should make provider code easier to test and review without
removing provider ownership from provider-specific behavior.

The kit can start as package-private helpers inside existing provider packages
or test packages. It becomes a public package only if stable duplication proves
that the maintenance cost is worth the public API cost.

## Candidate Helper Boundaries

### JSON And Schema Helpers

Useful when multiple providers need the same behavior:

- JSON-safe value validation
- null stripping
- schema normalization
- additional-properties normalization
- structured parse errors with paths

Keep provider-local:

- provider-specific schema dialect choices
- provider-specific response format constraints
- provider-specific warning text

### File And Media Helpers

Useful when multiple providers need the same behavior:

- media-type detection
- file extension mapping
- base64/data URI conversion
- `FileData` validation
- provider reference shape validation

Keep provider-local:

- hosted file ID support
- provider-specific file upload/download clients
- provider-specific cache/file lifecycle APIs

### Provider Reference Helpers

Useful when multiple providers need the same behavior:

- validating a `ProviderReference` namespace
- resolving provider references with clear unsupported-provider errors
- preserving provider reference data through prompt JSON

Keep provider-local:

- mapping references into OpenAI file IDs
- mapping references into Anthropic file sources
- mapping references into Google/Vertex `fileData`

### Stream Parser Helpers

Useful when multiple providers need the same behavior:

- tool-call delta accumulation
- partial JSON input accumulation
- malformed tool input error shaping
- JSON event stream framing when the transport layer has already delivered
  provider payloads

Keep provider-local:

- provider event names
- provider-specific finish reasons
- provider-specific metadata namespaces
- provider-native tool/result event vocabulary

### Fixture And Test Helpers

Useful across provider packages:

- static JSON fixture loading
- request body structural matchers
- provider metadata namespace matchers
- fake transport clients
- fake streamed response chunks

Keep package-local when:

- fixtures include provider-specific payload semantics
- helper names would leak provider internals into public packages

## Publication Criteria

A helper can be considered for a public `llm_dart_provider_utils` package only
when all of these are true:

- at least two provider packages use the same stable behavior
- the helper does not depend on Dio, retry, SSE, multipart, AI runtime, chat,
  Flutter, root, or compatibility packages
- the helper is testable independently
- the helper has no provider-native lifecycle ownership
- the public API can remain stable across at least one minor release line

Until then, prefer:

- provider-local private helpers
- package-private `src` modules
- test-only helper packages or shared dev utilities

## Anti-Patterns

Avoid:

- a shared provider base class that owns request execution
- a generic "provider codec" interface that hides provider-specific wire shapes
- a public utility package that mainly re-exports private implementation
  convenience
- moving provider-native feature clients into a common package
- making provider packages depend on `llm_dart_ai` to reuse runtime helpers

## First Implementation Recommendation

For the first production slice, extract one OpenAI Responses helper that has
clear tests and low public blast radius.

Preferred first candidates:

- request body building for text/image/tool inputs
- stream tool-call delta accumulation
- provider reference input mapping

Avoid starting with:

- public OpenAI provider facade changes
- Assistants lifecycle API changes
- shared utility publication

The first slice should prove the pattern before the workstream generalizes it.
