# 2026-03 Architecture Refactor

## Background

`llm_dart` already supports a broad set of providers, but its core abstractions are becoming too heavy:

- `LLMConfig.extensions` and `ChatMessage.extensions` now carry too many provider-specific concerns.
- `ChatCapability`, `AudioCapability`, `ImageGenerationCapability`, and similar interfaces are mixed with concrete provider behavior.
- `LLMBuilder`, `capability.dart`, and `chat_models.dart` have gradually turned into bus files.
- OpenAI, OpenAI-compatible providers, DeepSeek, xAI, Groq, and Phind contain repeated code and conditional branching.
- Flutter integration is still too close to direct provider calls and lacks a real chat-focused message and session layer.

This workstream is not about a file-moving refactor. It is about defining stable boundaries first, and then rewriting against those boundaries.

## Questions This Workstream Must Answer

1. Which interfaces should actually be unified, and which capabilities should stay provider-specific?
2. How should we borrow the layering ideas from the Vercel AI SDK without copying its package granularity?
3. What should the Dart-specific best-practice boundaries be?
4. Which APIs should be exposed to make Flutter chat applications easy to integrate?
5. How do we sequence a breaking refactor without turning it into an uncontrolled rewrite?

## Document Index

- [00-current-architecture-audit.md](00-current-architecture-audit.md)
  - Current repository audit, quantified problem signals, and the mapping to the target architecture.
- [01-design-principles.md](01-design-principles.md)
  - Design goals, non-goals, layering rules, and Dart-specific constraints.
- [02-unified-api-and-boundaries.md](02-unified-api-and-boundaries.md)
  - Unified API scope, stable boundaries, message models, and provider feature handling.
- [03-package-and-module-split.md](03-package-and-module-split.md)
  - Recommended workspace and package split, plus package-internal module boundaries.
- [04-flutter-chat-integration.md](04-flutter-chat-integration.md)
  - Chat session, transport, and UI-facing design for Flutter applications.
- [05-migration-strategy.md](05-migration-strategy.md)
  - Migration phases, compatibility strategy, risk control, and validation.
- [06-dependencies-and-provider-features.md](06-dependencies-and-provider-features.md)
  - Third-party dependency policy, package dependency direction, and the provider feature support model.
- [DECISIONS.md](DECISIONS.md)
  - Architecture decisions that are currently frozen.
- [TODO.md](TODO.md)
  - Executable task list.
- [MILESTONES.md](MILESTONES.md)
  - Phase milestones and acceptance criteria.
- [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md)
  - Decisions that are not yet fully closed.

## Current Summary

### Layers That Should Be Unified

- Text generation model interfaces
- Embedding model interfaces
- Image generation model interfaces
- Speech generation and transcription model interfaces
- UI-facing chat message models
- Stream event models

### Layers That Should Not Be Forced Into the Stable Unified Spec

- Stateful OpenAI Responses API features
- Anthropic MCP connector
- Provider-native file, assistant, moderation, and admin APIs
- Provider-specific model catalogs, beta features, and experimental parameters

### Recommended Overall Direction

- Borrow the Vercel AI SDK split of spec layer, shared utility layer, provider adapters, and UI layer.
- Do not copy its one-package-per-provider publishing strategy.
- Build an internal workspace first, then decide later which packages should be published separately.
- Get the text generation path and the Flutter chat path right first, and migrate everything else afterward.

### Current Audit Signals

- The current `lib/` directory contains 134 source files, and `providers/` alone accounts for 96 of them.
- `LLMBuilder`, `capability.dart`, and `chat_models.dart` have already become bus files.
- `extensions/getExtension/extension` related entry points appear 258 times in `lib/`, which means string-based extensions have already become a primary design path.
- `dio` appears 70 times across `lib/packages/test/example`, which shows that transport details have already leaked into too many layers.

## Recommended Phase-1 Freeze Items

The following items should be frozen before deeper implementation work continues:

1. Unified interface boundaries
2. Prompt, UI message, and stream event data structures
3. How provider-specific features are represented
4. Workspace package boundaries
5. The minimal Flutter `ChatSession` and `ChatTransport` API
6. Third-party dependency policy and inter-package dependency direction

These freeze points are expanded in the documents in this directory.
