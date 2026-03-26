# Dependencies And Provider Features

## Goal

This document answers two questions that directly determine whether the refactor will stay stable:

1. How should dependencies be layered, and which third-party libraries should appear in which layer?
2. How should provider-specific features be supported so that the library keeps a unified interface without making `core` heavy again?

If these two points are not frozen early, later migration work tends to fall back into the old patterns:

- `core` starts depending on providers again
- transport details leak back into public APIs
- new provider features get pushed into `extensions`
- the Flutter layer binds itself directly to provider details

## Current Dependency Audit

## Runtime Dependencies Today

The current root [pubspec.yaml](../../../pubspec.yaml) has only three runtime dependencies:

- `dio`
- `http_parser`
- `logging`

The problem is not “too many dependencies”. The problem is where those dependencies currently appear.

### `dio`

Repository-wide search shows that `package:dio` appears 70 times across `lib`, `packages`, `test`, and `example`.

Its current responsibilities include:

- HTTP request execution
- streamed response handling
- multipart/form-data upload
- `CancelToken`
- web/io adapter configuration
- interceptors

The problem is not whether Dio should exist. The problem is:

- `CancelToken` has already leaked into public API surfaces
- the core layer and capability interfaces are aware of Dio
- provider, client, and utility layers all depend directly on Dio types

Conclusion:

- Keep Dio in phase 1, but confine it to `llm_dart_transport` and provider implementation layers.
- `llm_dart_core` and the root facade should stop exposing Dio types.
- If transport ever needs to change later, the core spec should not care.

### `logging`

`package:logging` currently appears 20 times, mainly inside clients, transport helpers, and registry logic.

Its problem is smaller than Dio, but the principle is the same:

- logging libraries can exist in transport and provider implementation layers
- they should not become part of the core public abstraction

Conclusion:

- keep `logging` as an internal implementation dependency
- do not expose `Logger` or logging-specific types through core APIs

### `http_parser`

`package:http_parser` currently appears only once, in [lib/providers/openai/images.dart](../../../lib/providers/openai/images.dart).

That means:

- it is not a broad foundation dependency
- it is a local implementation detail for OpenAI image multipart handling

Conclusion:

- it should not remain a long-term root-package runtime dependency
- after migration, it should either live locally inside `llm_dart_openai` or be removed entirely

### `mcp_dart`

`mcp_dart` is currently a root `dev_dependency`, and all 8 occurrences in the repository are inside `example/06_mcp_integration`.

The conclusion is clear:

- it is not a runtime dependency of the current main package
- it should not enter `llm_dart_core`, `llm_dart_transport`, or the main provider paths
- Anthropic MCP connector support does not require `mcp_dart`, because that feature sends MCP server configuration to Anthropic rather than acting as a local MCP protocol client

Conclusion:

- keep `mcp_dart` in examples or future dedicated integration packages only
- do not bring it into the core dependency chain

### `mockito`

Current repository search does not show actual `mockito` usage.

Conclusion:

- it is likely a leftover dev dependency
- it should be removed when the new test foundation is rebuilt

## Current Internal Dependency Direction Problems

The larger issue is not third-party dependencies. It is that internal dependency direction is already broken.

Typical examples:

- [capability.dart](../../../lib/core/capability.dart) imports [tts.dart](../../../lib/providers/google/tts.dart)
- [registry.dart](../../../lib/core/registry.dart) imports provider factories directly
- [llm_builder.dart](../../../lib/builder/llm_builder.dart) imports concrete provider builders and provider implementations

That means the current architecture is not “core defines the contract and providers implement it”. It is “core and providers are mixed into one layer”.

That must be corrected in the new architecture.

## Target Dependency Direction

## One Rule That Must Hold

Dependencies must flow in one direction only. They must not flow back upward.

Recommended shape:

```text
llm_dart_core
   ^
   |
llm_dart_transport
   ^
   |
llm_dart_openai / llm_dart_anthropic / llm_dart_google / llm_dart_community
   ^
   |
llm_dart

llm_dart_flutter -> llm_dart_core
llm_dart_flutter -> llm_dart_transport   (only when transport reuse is necessary)
```

Key constraints:

- `llm_dart_core` must not depend on provider packages, Flutter, or HTTP libraries
- `llm_dart_transport` must not depend on concrete provider packages
- provider packages may depend on `core` and `transport`, but not on each other in cycles
- the root `llm_dart` package should become facade and compatibility only
- `llm_dart_flutter` must not depend on concrete provider packages

## Dependency Responsibilities Per Package

## `llm_dart_core`

Responsibilities:

- model spec
- prompt, result, stream, and UI data structures
- usage, warning, and provider metadata
- shared top-level helper functions

Recommended runtime dependencies:

- Dart SDK only

Things that must not appear here:

- Dio
- logging
- Flutter
- MCP client dependencies
- provider registry
- provider-specific client helpers

## `llm_dart_transport`

Responsibilities:

- transport abstraction
- HTTP executor
- SSE decoder
- retry, timeout, and cancellation
- multipart helpers
- transport diagnostics

Recommended runtime dependencies:

- `llm_dart_core`
- `dio`
- `logging`

Current recommendation:

- do not split out `llm_dart_transport_dio` yet
- keep Dio hidden inside transport for now
- only consider a deeper split if a second transport implementation becomes real

## `llm_dart_openai` / `llm_dart_anthropic` / `llm_dart_google`

Responsibilities:

- provider factories
- request and response codecs
- stream-event mapping
- typed provider options
- provider-native extension APIs

Recommended runtime dependencies:

- `llm_dart_core`
- `llm_dart_transport`
- only provider-local third-party dependencies when necessary

Examples:

- `llm_dart_openai` may keep `http_parser` locally if still needed
- `llm_dart_anthropic` should not pull in `mcp_dart` just because it supports the MCP connector

## `llm_dart_community`

Responsibilities:

- Ollama
- ElevenLabs
- transition-home for lower-volume providers

Dependency policy:

- depends on `core` and `transport`
- may temporarily depend on `llm_dart_openai` if it reuses OpenAI-family profile internals
- but this must remain a controlled transition, not a new cyclic dependency mesh

Current recommendation:

- do not introduce a public `provider_utils` package yet
- shared logic should first live either in `transport` or provider-internal `src/shared`
- only after stable long-term reuse appears should an internal support package be introduced

## `llm_dart_flutter`

Responsibilities:

- `ChatSession`
- `ChatState`
- `ChatTransport`
- `ChatController`
- UI message projection

Dependency policy:

- must depend on `llm_dart_core`
- may depend on `llm_dart_transport` if transport reuse is needed
- must not depend on concrete provider packages

Why:

- the Flutter layer should target model interfaces and chat-session protocols, not provider implementations

## Third-Party Dependency Policy

| Dependency | Current State | New Architecture Policy |
| --- | --- | --- |
| `dio` | spread through many layers | confine to `llm_dart_transport` and provider implementation layers |
| `logging` | used across internal layers | keep as internal implementation dependency only |
| `http_parser` | only used in OpenAI image code | localize to `llm_dart_openai` or remove |
| `mcp_dart` | example-only | keep in example or dedicated integration packages only |
| `mockito` | unused | remove when rebuilding the test foundation |

## Provider Feature Support Model

Provider-specific features should no longer all flow through `extensions`.

They should be represented through five fixed channels.

## Channel 1: Typed Model Settings

Use this for provider-specific features that are stable over the lifetime of a model instance.

Examples:

- OpenAI default service tier, responses mode, built-in tool availability
- Anthropic default reasoning configuration
- Google default safety settings and response modalities
- xAI default live-search configuration

Characteristics:

- passed when the model is created
- affects the model's default behavior
- not expected to change on every call

## Channel 2: Typed Invocation Options

Use this for provider-specific features that can change per invocation.

Examples:

- OpenAI `previous_response_id`
- OpenAI `verbosity` or `parallel_tool_calls`
- Anthropic `thinkingBudgetTokens`
- Google `candidateCount`
- xAI call-specific search parameters

Recommendation:

keep marker interfaces in core instead of using raw `Object?` as the long-term design:

```text
ProviderModelOptions
ProviderInvocationOptions
```

Provider packages should implement their own typed options:

- `OpenAITextModelSettings`
- `OpenAIGenerateTextOptions`
- `AnthropicTextModelSettings`
- `AnthropicGenerateTextOptions`
- `GoogleTextModelSettings`
- `GoogleGenerateTextOptions`

## Channel 3: Provider Metadata

Use this for useful provider-returned information that does not justify a shared top-level field.

Examples:

- OpenAI `response_id`
- Anthropic `stop_reason`
- Google `safety_ratings`
- cache-hit or cache-creation metadata
- provider request IDs or trace IDs

Recommendation:

- `ProviderMetadata` should use provider namespaces as the top-level keys, for example:

```dart
ProviderMetadata({
  'openai': {
    'responseId': 'resp_123',
    'serviceTier': 'default',
  },
})
```

- when multiple streamed updates contribute metadata under the same provider namespace, the projection layer should merge those nested values instead of replacing the whole provider entry blindly
- metadata should carry attached details, not primary content

## Channel 4: Custom Content Parts and Custom UI Parts

Use this for provider-specific output blocks that genuinely need to be rendered or consumed.

Examples:

- OpenAI Responses-specific lifecycle or structured reasoning blocks
- Anthropic MCP connector blocks
- Google grounding, citation, or safety-explanation blocks
- xAI live-search extra source blocks

This is also a direct implication for the current skeleton:

- [content_part.dart](../../../packages/llm_dart_core/lib/src/content/content_part.dart) `CustomContentPart`
- [chat_ui_message.dart](../../../packages/llm_dart_core/lib/src/ui/chat_ui_message.dart) `CustomUiPart`

Previously they only carried `kind`. They now need payload support.

Recommended rules:

- `kind` must be provider-namespaced, for example `openai.reasoning.summary`
- `data` may carry provider-typed payloads
- the UI layer can decide how to render specific custom kinds

## Channel 5: Provider-Native Extension APIs

Use this for capabilities that should not be normalized into the core spec.

Typical examples:

- OpenAI Responses CRUD
- OpenAI files, assistants, and moderation
- Anthropic MCP connector management
- provider-native admin, batch, or storage APIs

That means:

- the shared spec owns cross-provider commonality
- provider-native APIs own deep provider-specific features
- both can coexist without contaminating each other

## Provider-by-Provider Guidance

## OpenAI

Supported in the shared spec:

- `generateText`
- `streamText`
- `embed`
- `generateImage`
- `generateSpeech`
- `transcribe`

Provider-specific handling:

- built-in tools: typed provider options
- `previous_response_id`: invocation options
- response ID and low-level finish detail: metadata
- Responses CRUD: provider-native API

## Anthropic

Supported in the shared spec:

- `generateText`
- `streamText`

Provider-specific handling:

- thinking and interleaved thinking: typed options
- cache markers: metadata or custom parts
- MCP server config: provider-native typed options
- MCP connector lifecycle: provider-native API

## Google

Supported in the shared spec:

- `generateText`
- `streamText`
- `embed`
- `generateImage`
- `generateSpeech`

Provider-specific handling:

- safety settings: typed model and invocation options
- response modalities: typed options
- grounding and safety annotations: metadata or custom parts

## OpenAI-Compatible Family

Principle:

- reuse only the protocol-overlap mainline
- do not absorb each provider's extra capabilities into shared OpenAI text options

Examples:

- DeepSeek reasoning can surface as metadata or custom reasoning content
- xAI live-search parameters should remain xAI typed options
- Groq and Phind differences should not flow back into the common OpenAI text option surface

## Conclusions That Should Now Be Treated As Frozen

## 1. Keep `dio`, But Push It Down

- `llm_dart_core` must not expose Dio types
- `CancelToken` should stop being a long-term core public API
- transport should own cancellation abstraction

## 2. Do Not Add a Public `provider_utils` Package Yet

- let `llm_dart_transport` own shared network and streaming utilities first
- keep provider-shared logic inside internal `src/shared` modules for now
- only introduce another internal support package after stable multi-provider reuse exists

## 3. Provider Features Must Go Through the Five Channels

- typed model settings
- typed invocation options
- provider metadata
- custom content or UI parts
- provider-native extension APIs

## 4. `extensions` Is Compatibility Only

- keep it during migration
- do not let it remain the main design path

## 5. `mcp_dart` Must Stay Out of the Core Dependency Chain

- use it only in examples or in a future dedicated integration package

## Direct Impact on the Current Skeleton

Before the next provider-migration wave, these changes should happen:

- add provider-options marker interfaces to core
- add payload support to `CustomContentPart` and `CustomUiPart`
- design a transport-level cancellation abstraction to replace public `CancelToken`
- move `http_parser` out of the root package
- remove unused `mockito`
