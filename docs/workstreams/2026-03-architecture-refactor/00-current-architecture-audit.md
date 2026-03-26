# Current Architecture Audit

## Scope

This audit focuses on the current `llm_dart` package as it exists today, not on the desired target state.

It has two goals:

1. Turn the reasons for a fearless refactor into a concrete, verifiable problem list.
2. Map the current codebase to the target architecture so later migration phases stay grounded.

## Quantitative Snapshot

At the time of this audit, the repository looks roughly like this:

- Source files under `lib/`: 134
- Source files under `lib/providers/`: 96
- Files under `test/`: 101
- `LLMBuilder` length: about 810 lines
- `core/capability.dart` length: about 1032 lines
- `models/chat_models.dart` length: about 652 lines
- `providers/openai/responses.dart` length: about 717 lines
- `providers/anthropic/chat.dart` length: about 787 lines
- `providers/google/chat.dart` length: about 806 lines
- `extension(...)`, `withExtension(...)`, and `getExtension(...)` entry points in `lib/`: 258

Compared with the reference repository `repo-ref/ai`:

- Packages under `repo-ref/ai/packages`: 53
- Files under `repo-ref/ai/packages/provider/src`: 193
- Files under `repo-ref/ai/packages/openai/src`: 136

The conclusion is straightforward:

- The current main package is already too large.
- The Vercel AI SDK split is significantly finer-grained than what makes sense for the current Dart ecosystem stage of this project.
- The right direction is therefore neither “keep everything in one package” nor “copy 53 packages literally”, but a medium-grained internal workspace split.

## Current Problem List

## 1. The Root Export Surface Is Too Large

The current [lib/llm_dart.dart](../../../lib/llm_dart.dart) exports all of the following:

- Core abstractions
- Data models
- Provider implementations
- Provider factories
- Builders
- Utility helpers

This creates several direct problems:

- Users see the surface of the whole repository instead of a deliberately designed stable API.
- Internal modules can easily become externally depended-on APIs, which makes later refactors much harder.
- Provider implementations, builder shortcuts, and low-level utilities can be mistaken for stable entry points.

Target mapping:

- The root facade should only expose stable entry points.
- Provider implementations should move into dedicated packages.
- Low-level transport and codec details should stop being exported directly from the main package.

## 2. `capability.dart` Has Become a Bus File

The current [lib/core/capability.dart](../../../lib/core/capability.dart) contains:

- chat
- stream
- embedding
- audio
- realtime audio
- model listing
- image generation
- file management
- moderation
- assistants
- tool execution
- enhanced chat
- provider capability declarations

This is a clear case of an overgrown unified abstraction:

- Some capabilities are core inference paths.
- Some are provider-native management APIs.
- Some are convenience APIs.
- Some are feature-discovery enums for documentation or selection purposes.

These concerns should not be frozen into the same central file.

Target mapping:

- The core spec should keep only `LanguageModel`, `EmbeddingModel`, `ImageModel`, `SpeechModel`, and `TranscriptionModel`.
- `generateText`, `streamText`, `embed`, `generateImage`, `generateSpeech`, and `transcribe` should become the stable operation entry points.
- assistants, files, moderation, and responses CRUD should remain provider-package extension APIs rather than phase-1 unified spec.

## 3. `LLMBuilder` Carries Too Much Provider Detail

The current [lib/builder/llm_builder.dart](../../../lib/builder/llm_builder.dart) is no longer just a builder. It currently handles:

- provider selection
- shared parameters
- HTTP configuration
- OpenAI-specific parameters
- Anthropic thinking options
- web search abstraction
- image parameters
- audio parameters
- Google TTS paths
- OpenAI Responses API shortcuts

That creates a structural problem:

- The builder becomes the default dumping ground for every new feature.
- Any provider-specific capability tends to first show up as another builder method.
- Every new feature makes the builder harder to reason about.

Target mapping:

- The builder should stop being the architectural center.
- Provider packages should expose their own typed factories, profiles, and options.
- The facade layer should keep only a small set of high-frequency convenience entry points.

## 4. `LLMConfig.extensions` Is the Main Coupling Source

The current [lib/core/config.dart](../../../lib/core/config.dart) uses `extensions: Map<String, dynamic>` to carry provider-specific features.

That design was initially flexible, but the cost now outweighs the benefit:

- Parameter names are string-based and lack compile-time validation.
- Different providers can easily drift or collide on extension keys.
- IDE discoverability and autocomplete are poor.
- Documentation is harder to write and harder to follow.
- Provider implementations end up reading `getExtension<T>()` from many scattered places, which spreads configuration semantics everywhere.

In `lib/` alone, extension-related entry points appear 258 times. That is enough to show that the extension map is no longer an escape hatch. It has become the main design path.

Target mapping:

- Shared parameters should split into capability-specific settings plus a small shared `CallOptions`.
- Provider differences should move into provider-specific typed options.
- Provider-specific outputs should move into `providerMetadata`, custom content parts, and custom UI parts instead of continuing to inflate the shared configuration surface.

## 5. The OpenAI Family Has Reached Double Complexity

The current repository has two overlapping issues at once:

1. OpenAI itself already has a heavy implementation surface.
2. DeepSeek, xAI, Groq, Phind, and OpenRouter add more branches around OpenAI-compatible behavior.

Even though [lib/providers/factories/openai_compatible_factory.dart](../../../lib/providers/factories/openai_compatible_factory.dart) already tries to abstract OpenAI-compatible providers, the current state still has obvious problems:

- The OpenAI implementation itself is still too heavy.
- Compatible providers still depend on that large implementation surface.
- Profiles and provider instances are not yet truly separated.
- Some capability differences are still represented through conditionals and extension keys.
- OpenAI Chat and Responses still coexist as two primary paths with unclear long-term boundaries.

Target mapping:

- Move the OpenAI family into a dedicated package.
- Reorganize it around profiles, shared codecs, transport, and typed options.
- Make OpenAI, OpenRouter, DeepSeek, Groq, xAI, and Phind share a mainline where only genuine differences are expressed through profiles.

## 6. Transport, Codec, and Provider Logic Are Still Mixed

The current [lib/core/base_http_provider.dart](../../../lib/core/base_http_provider.dart) still mixes:

- Dio lifecycle management
- request execution
- logging
- generic error mapping
- provider-specific response parsing
- provider-specific stream chunk parsing

This causes two issues:

- Transport code is hard to reuse and easy to duplicate during provider migration.
- Cross-cutting concerns such as SSE, chunk parsing, retry, timeout, and cancellation are hard to test independently.

Target mapping:

- `llm_dart_transport` should own the HTTP executor, SSE decoder, stream parsing helpers, retry, timeout, and cancellation.
- Provider packages should own request codecs, response codecs, and stream-event mapping.

## 7. Flutter Has No Dedicated Session Layer

The library can already call providers directly, but for a real Flutter chat application it still lacks a stable integration layer:

- no `ChatSession`
- no `ChatState`
- no `ChatTransport`
- no formal projection layer from stream events to UI messages

That means:

- Flutter application code must manually manage sessions, stream accumulation, tool output injection, and UI state projection.
- Provider-facing APIs leak directly into the UI layer.
- Later requirements such as persistence, replay, approval, and reconnection have no stable anchor point.

Target mapping:

- `llm_dart_flutter` should become the chat-facing integration layer.
- The core data structures should be organized around `ChatUiMessage(parts)` and `TextStreamEvent`.
- Direct provider transport and HTTP transport should both be first-class modes.

## 8. Tests Are Mostly Provider-Implementation Tests

The current test suite is large, but the main issue is not the number of tests. It is where they are anchored:

- Many tests bind directly to current provider implementations and old models.
- There are not yet enough spec-level tests such as prompt normalization, stream accumulation, or UI projection.
- During refactors, it becomes easy to get “everything broke” signals even when the actual desired behavior has not changed.

Target mapping:

- The new architecture should establish spec tests first.
- Provider tests should shift toward codec, profile, and compatibility coverage.
- The Flutter chat layer should establish UI projection tests.

## Why We Should Not Copy the Vercel AI SDK Literally

`repo-ref/ai` is a strong reference, but it should not be copied one-to-one.

What is worth borrowing:

- define the provider spec before defining provider packages
- return model objects instead of giant provider objects
- represent provider differences through typed options, metadata, and tool abstractions
- treat text, embeddings, images, speech, and transcription as separate capability surfaces

What should not be copied directly:

- the package split is too fine-grained for the current Dart maintenance budget
- the parallel v2/v3/v4 interface trees are too heavy for this stage
- React, RSC, Vue, and Angular layers are not directly relevant to a Flutter-first client integration model
- some advanced tooling is Node/Web-first and does not map cleanly to Dart/Flutter

The principle for this project should therefore be:

- borrow the layering, not the publishing granularity
- borrow the spec-first mindset, not the version-tree explosion
- borrow typed model objects, not a web-framework-centered architecture

## Mapping Current Code to the Target Architecture

| Current Area | Current Problem | Target Destination |
| --- | --- | --- |
| `lib/llm_dart.dart` | Root export surface is too large | Root facade exposes only stable entry points; providers move out of the main package |
| `lib/core/capability.dart` | Core and non-core capabilities are mixed | Split into focused model specs inside `llm_dart_core` |
| `lib/core/config.dart` | `extensions` carries too much difference | Shared typed options plus provider-specific typed options |
| `lib/builder/llm_builder.dart` | Builder has become a feature bus | Light facade entry points plus provider factories |
| `lib/core/registry.dart` | Core imports every provider factory | Registry and adapters move to facade/compatibility layers |
| `lib/core/base_http_provider.dart` | Transport and codec are coupled | `llm_dart_transport` plus provider codecs |
| `lib/models/chat_models.dart` | Prompt, result, and provider concerns are mixed | Separate `PromptMessage`, `ContentPart`, and `ChatUiMessage` |
| `lib/providers/openai/*` | OpenAI implementation is too heavy | `llm_dart_openai` plus shared profile/codec |
| `lib/providers/deepseek/xai/groq/phind/*` | OpenAI-compatible repetition | OpenAI family profile model |
| `lib/providers/anthropic/*` | reasoning/MCP/web search mixed into the mainline | Dedicated `llm_dart_anthropic` package |
| `lib/providers/google/*` | chat/image/embedding/tts live in one undifferentiated provider area | Dedicated `llm_dart_google` package |
| direct provider calling mode | Flutter session layer is missing | `llm_dart_flutter` with `ChatSession` and `ChatTransport` |

## Recommended Migration Waves

### Wave 0

- Freeze the core spec
- Freeze UI message and stream event structures
- Freeze package boundaries

### Wave 1

- Establish `llm_dart_core`
- Establish `llm_dart_transport`
- Make transport and spec tests pass

### Wave 2

- Establish `llm_dart_openai`
- Migrate `generateText` and `streamText` first
- Collapse OpenAI Chat and Responses behind the new language-model interface

### Wave 3

- Migrate Anthropic and Google mainlines
- Validate that typed provider options are sufficient to represent their differences

### Wave 4

- Move DeepSeek, xAI, Groq, and Phind into the OpenAI family profile model
- Migrate Ollama and ElevenLabs

### Wave 5

- Establish `llm_dart_flutter`
- Establish direct and HTTP chat transport
- Establish UI projection, tool approval, and tool result injection

### Wave 6

- Introduce the facade compatibility layer
- Degrade old `ai()` and `ChatCapability` into adapters
- Remove the old bus-style internals last

## Current Conclusion

The current repository is not short on features. Its problem is boundary distortion:

- spec, provider, transport, builder, and Flutter integration are not truly separated
- provider differences repeatedly flow back into the core through string-based extensions
- the root package exports too many internal implementation details
- the OpenAI family is already in a state of simultaneous repetition and compatibility branching

This refactor should therefore follow two rules:

1. Thin the core boundaries before migrating providers.
2. Get the text mainline correct before touching files, assistants, moderation, or admin APIs.
