# Target Architecture

## Layer Rules

The target architecture keeps the existing package graph but hardens the
semantic boundaries inside it.

## `llm_dart_provider`

Owns provider-facing contracts:

- model interfaces and `do*` request/result shapes
- normalized provider prompt messages and content parts
- tool definitions and provider-facing tool output contracts
- output content parts and text stream events
- provider metadata as output observation
- provider options interfaces as input customization contracts
- serialization for provider-facing contract values

Must not own:

- user prompt ergonomics
- tool execution loops
- structured output parsing
- UI projection
- HTTP implementations
- concrete provider codecs

## `llm_dart_ai`

Owns user-facing runtime behavior:

- model-first generation helpers
- user-facing prompt shapes
- prompt normalization to provider prompt contracts
- missing tool-result validation
- multi-step tool execution
- output parsing and object generation
- stream accumulation and result facades
- UI projection and chat UI serialization

Must not own:

- concrete provider wire codecs
- provider product helper clients
- transport implementations
- provider-specific options classes except through typed extension points

## `llm_dart_transport`

Owns transport primitives:

- HTTP request/response contracts
- Dio adapters
- SSE and UTF-8 stream decoding
- retry, timeout, diagnostics, cancellation, and multipart helpers

Transport may depend on provider contracts only when adapting shared
cancellation or model error values. It must not depend on AI runtime, chat,
Flutter, root, or concrete providers.

## Provider Packages

Own provider-native implementation:

- provider facades such as `openai(...).chatModel(...)`
- provider model settings and invocation options
- provider prompt-part options
- request and response codecs
- provider-native replay helpers
- capability profiles and model describers
- product APIs such as files, moderation, voices, image editing, catalogs, and
  transcription helpers

Provider packages must not depend on AI runtime, chat, Flutter, root, or legacy
compatibility in production code.

## Provider Utility Boundary

A provider utility boundary is justified only for repeated provider
implementation helpers, such as:

- JSON validation and normalization
- media type normalization
- provider reference resolution
- schema helpers
- model warning helpers
- request body encoding helpers
- response body decoding helpers
- stream event assembly helpers

It must not own:

- transport clients
- AI runtime orchestration
- user prompt APIs
- concrete provider product features

The first implementation can stay package-private. A public
`llm_dart_provider_utils` package should be published only when its stable
contract is clear.

## Root Package

Root `llm_dart` owns:

- modern convenience exports
- short provider factory aliases
- explicit migration compatibility only while it is intentionally retained

Root must not own:

- provider codecs
- model contracts
- runtime orchestration
- transport implementations
- new legacy-compatible abstractions

## Deliberate Dart Differences From `repo-ref/ai`

The Dart library should not copy TypeScript-specific shapes. It should keep:

- typed provider options instead of untyped option maps as the primary API
- concrete provider facades for discoverability
- capability profiles for runtime model discovery
- sealed classes for prompt, content, file, tool, and stream contracts
- framework-neutral packages that remain usable outside web frameworks
