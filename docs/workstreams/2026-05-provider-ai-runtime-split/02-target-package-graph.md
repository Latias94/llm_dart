# Target Package Graph

## Target Dependency Direction

The intended direction is:

```text
llm_dart_provider
  ^
  |
llm_dart_provider_utils
  ^
  |
provider packages ---------> llm_dart_transport
  ^                              ^
  |                              |
llm_dart_ai ---------------------+
  ^
  |
llm_dart_chat -----> llm_dart_transport
  ^
  |
llm_dart_flutter

llm_dart -> facade over provider packages, llm_dart_ai, llm_dart_chat,
            llm_dart_transport, and explicit legacy compatibility
```

The graph should preserve these rules:

- provider packages do not import root `llm_dart`
- `llm_dart_provider` does not depend on transport, chat, Flutter, or concrete
  providers
- `llm_dart_provider_utils` does not own Dio or HTTP transport
- `llm_dart_ai` depends on provider specs and generic helpers, not concrete
  provider implementations
- `llm_dart_chat` depends on shared model/UI contracts and transport, not
  concrete provider packages
- `llm_dart_flutter` depends on chat/core-style contracts, not concrete
  providers
- root `llm_dart` can depend outward as a facade, but should not own new
  implementation logic

## Package Responsibilities

### `llm_dart_provider`

Owns stable provider-facing contracts:

- `LanguageModel`, `EmbeddingModel`, `ImageModel`, `SpeechModel`,
  `TranscriptionModel`
- provider interface and optional capability interfaces
- prompt messages and parts
- content parts
- stream events
- tool definitions and tool-choice structures
- provider options and provider metadata
- model warnings and model errors
- usage and response metadata
- file data and provider references

### `llm_dart_provider_utils`

Owns reusable provider implementation helpers:

- JSON-safe normalization
- provider-reference resolution
- media-type helpers
- schema normalization
- warning builders
- stream accumulator primitives that are provider-codec specific
- request codec helpers that do not own HTTP transport

It must not expose Dio, request retry, SSE transport, or Flutter concepts.

### `llm_dart_ai`

Owns app-facing runtime:

- `generateText`
- `streamText`
- structured output helpers
- multi-step generation runner
- stream result facades
- tool execution loop
- stop policy
- optional `prepareStep`-style hooks if accepted for the breaking line

It must not own provider-native lifecycle APIs.

### `llm_dart_transport`

Owns transport:

- HTTP request and response abstraction
- SSE decoding
- retry and timeout policy
- cancellation adapters
- diagnostics
- multipart body encoding
- Dio implementation entrypoints

### Provider Packages

Provider packages own:

- model implementations
- provider-specific request and response codecs
- typed model settings
- typed invocation options
- provider-native tools
- provider-native helper clients
- model capability describers

### `llm_dart_chat`

Owns framework-neutral chat runtime:

- `ChatSession`
- `ChatTransport`
- direct provider transport
- HTTP chat transport protocol
- prompt/UI message mapping
- chat snapshots
- automatic local tool execution helpers

### `llm_dart_flutter`

Owns Flutter-only adapters:

- controller APIs
- Flutter examples and widgets
- Material-friendly demos

### Root `llm_dart`

Root owns:

- modern convenience facade
- focused public entrypoints
- compatibility bridge during migration
- migration documentation

Root should not own new provider implementations or new shared model contracts.

## Guard Updates

When packages are introduced, guard tooling should be updated to enforce:

- allowed runtime dependencies by package
- no provider implementation imports from root `llm_dart`
- no `llm_dart_provider` dependency on transport or Flutter
- no Flutter package dependency on concrete provider packages
- no root-local provider implementation growth outside explicit legacy areas
