# Package And Module Split

## Goal

The goal of package splitting is not “the more granular, the more advanced”. The real goals are:

- decouple the stable spec from provider implementations
- prevent providers from polluting each other
- let the Flutter integration layer stay independent from concrete provider details
- keep repository maintenance cost lower than the current single-package monolith

## Why We Should Not Copy the Vercel AI SDK Split Literally

The Vercel AI SDK is an ecosystem monorepo covering:

- core
- provider spec
- provider utilities
- UI hooks
- React, Vue, and Svelte integrations
- MCP
- LangChain and LlamaIndex adapters
- many provider packages

For `llm_dart`, copying that split literally would be too fine-grained and too expensive.

The better fit here is:

- first turn the repository into an internal workspace
- keep the package count at a medium scale
- publish fewer external packages than the number of internal modules

## Recommended Split

## Layer 1: Internal Workspace Packages

Start with the following workspace package boundaries:

### 1. `llm_dart_core`

Responsibilities:

- stable spec
- prompt models
- result and stream models
- tool schema
- error types
- usage, warning, and metadata models

Must not depend on:

- `dio`
- Flutter
- concrete provider implementations

### 2. `llm_dart_transport`

Responsibilities:

- HTTP transport abstraction
- SSE and chunk decoding
- retry, timeout, and cancellation
- request execution
- error mapping
- shared codec helpers

Notes:

- this can remain an internal package at first
- `core` should not know it exists, but provider packages may depend on it

### 3. `llm_dart_openai`

Responsibilities:

- native OpenAI provider support
- shared OpenAI-family codecs
- OpenAI-compatible adapter infrastructure

Recommended providers in this package:

- OpenAI
- OpenRouter
- DeepSeek OpenAI-compatible
- Groq OpenAI-compatible
- xAI OpenAI-compatible
- Phind OpenAI-compatible

Why:

- these providers share a very similar protocol surface
- they currently account for the largest amount of repeated code
- moving them together yields the fastest weight reduction

### 4. `llm_dart_anthropic`

Responsibilities:

- Anthropic message adapters
- Anthropic tool, reasoning, and MCP connector support
- Anthropic-specific request and response codecs

### 5. `llm_dart_google`

Responsibilities:

- Gemini language model support
- Gemini image, embedding, and TTS support
- Google-specific safety, modality, and candidate codecs

### 6. `llm_dart_community`

Responsibilities:

- Ollama
- ElevenLabs
- smaller or more specialized providers that are not worth dedicated packages yet

Notes:

- this is a transition package, not a permanent final design
- once a community provider grows substantially in complexity, it should move to its own package

### 7. `llm_dart_flutter`

Responsibilities:

- `ChatSession`
- `ChatTransport`
- `ChatState`
- Flutter-friendly controller and notifier layers
- serialization and persistence helpers

Notes:

- this package may depend on `flutter/foundation`
- the main `llm_dart` package should not require Flutter

### 8. `llm_dart`

Responsibilities:

- facade
- backward-compatibility adapters
- most common re-exports
- transitional implementation of the old builder APIs

## Layer 2: Package-Internal Module Boundaries

Even inside a single provider package, module boundaries still matter.

### `catalog`

Responsibilities:

- model capability tables
- default models
- model aliases
- parameter compatibility notes

### `options`

Responsibilities:

- provider typed options
- invocation-level typed options

### `codec`

Responsibilities:

- prompt -> provider payload
- provider response -> content parts
- stream chunk -> stream events

### `client`

Responsibilities:

- endpoints
- headers
- transport glue

### `models`

Responsibilities:

- externally exposed provider instances and model factories

### `experimental`

Responsibilities:

- beta, preview, or unstable capabilities

## Why the OpenAI-Compatible Family Should Be Consolidated

The current repository already shows substantial overlap across OpenAI and compatible providers:

- similar config structures
- similar chat request and response shapes
- similar SSE parsing
- similar reasoning, tool, and structured-output adaptation

If the codebase keeps splitting these by provider without a shared OpenAI-family core, the problem only changes from “single-package duplication” to “multi-package duplication”.

The more reasonable path is:

- build an OpenAI-family shared core first
- layer provider profiles on top of it to represent differences

That way:

- DeepSeek, Groq, xAI, Phind, and OpenRouter become profiles rather than full re-implementations
- only genuine differences need provider-specific codecs

## Dart Project Best Practices

## 1. Clear `src/` Boundaries

- public API should only be exported through package-level barrels
- implementation details should live under `src/`
- top-level `lib/` should stop flattening dozens of internal implementation files

## 2. Avoid One Giant Barrel

The main entry point can remain, but it should stop growing indefinitely.

A better shape is:

- `llm_dart.dart`
- `llm_dart/core.dart`
- `llm_dart/openai.dart`
- `package:llm_dart_flutter/llm_dart_flutter.dart`

## 3. Enforce One-Way Dependencies

Recommended dependency direction:

`core <- transport <- provider packages <- facade / flutter`

Reverse dependencies should be disallowed.

## 4. Remove Double Registry Concepts

The current architecture contains more than one registry-style concept. The new architecture should retain one clear provider/model discovery mechanism.

## 5. Move Capability Logic into Catalogs

Capability checks should stop being scattered across:

- config
- builder
- chat
- factory

They should move into:

- provider catalogs
- model capability profiles

## External Publishing Strategy

In phase 1, not every workspace package needs to be published independently to pub.dev.

Recommended strategy:

- establish the workspace boundaries first
- publish only `llm_dart` initially
- let `llm_dart` consume the internal workspace packages
- only evaluate separate publishing for `llm_dart_core` or `llm_dart_flutter` after the API has stabilized

This gives the project the benefit of clean boundaries without immediately multiplying release and maintenance overhead.
