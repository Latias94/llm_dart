# 85. Public Example Surface Alignment

## Why This Exists

The architecture workstream had already frozen the stable direction:

- new code should prefer the `AI.*(...).chatModel(...)` facade
- shared app-facing text calls should prefer `generateTextCall(...)` /
  `streamTextCall(...)`
- provider-specific features should stay provider-owned and typed
- the legacy root builder and shared web-search helpers are compatibility-only

However, a public migration is not complete when only implementation internals
move. If high-visibility examples still lead users toward legacy builder flows,
deprecated shared search helpers, or raw compatibility escape hatches, the
repository still teaches the wrong architecture.

## What Changed

### Stable Web Search Example

`example/02_core_features/web_search.dart` now demonstrates the stable search
direction:

- shared call layer through `generateTextCall(...)`
- OpenAI search through `OpenAIGenerateTextOptions.builtInTools`
- Anthropic search through `AnthropicGenerateTextOptions.tools`
- xAI search through `XAIGenerateTextOptions.search`
- OpenRouter search through `OpenRouterChatModelSettings.search`

This replaces the previous example that was centered on deprecated root builder
helpers such as:

- `enableWebSearch()`
- `webSearch()`
- `quickWebSearch()`
- `newsSearch()`
- `advancedWebSearch()`

### High-Visibility README Guidance

The top example READMEs now distinguish between:

- stable model-based examples
- compatibility-oriented builder examples that still remain during migration
- registry/provider metadata examples that are informational rather than normal
  runtime entry paths

This is intentionally explicit in:

- `example/01_getting_started/README.md`
- `example/02_core_features/README.md`
- `example/03_advanced_features/README.md`
- `example/04_providers/README.md`
- `example/04_providers/openai/README.md`
- `example/04_providers/anthropic/README.md`
- `example/04_providers/google/README.md`
- `example/04_providers/groq/README.md`
- `example/04_providers/others/README.md`
- `example/04_providers/ollama/README.md`
- `example/04_providers/elevenlabs/README.md`
- `example/05_use_cases/README.md`

The core-features README now also tightens several important architecture
messages:

- stable helpers and stable model constructors come first
- capability metadata is framed as provider-selection guidance, not runtime
  validation
- Anthropic prompt caching is pushed back to provider-specific documentation
  instead of being taught as a generic core-surface pattern

### Stable Source Example Migration

The alignment work now also covers actual example source files, not only README
descriptions.

Examples now centered on the stable model API include:

- `example/01_getting_started/basic_configuration.dart`
- `example/01_getting_started/environment_setup.dart`
- `example/01_getting_started/provider_comparison.dart`
- `example/02_core_features/chat_basics.dart`
- `example/02_core_features/capability_detection.dart`
- `example/02_core_features/cancellation_demo.dart`
- `example/02_core_features/web_search.dart`
- `example/04_providers/anthropic/extended_thinking.dart`
- `example/04_providers/anthropic/streaming_tool_calling.dart`
- `example/04_providers/anthropic/mcp_connector.dart`
- `example/04_providers/groq/fast_inference.dart`
- `example/04_providers/google/embeddings.dart`
- `example/04_providers/google/image_generation.dart`
- `example/04_providers/openai/advanced_features.dart`
- `example/04_providers/openai/audio_capabilities.dart`
- `example/04_providers/openai/gpt5_features.dart`
- `example/04_providers/openai/image_and_file_messages.dart`
- `example/04_providers/openai/image_generation.dart`
- `example/04_providers/others/xai_grok.dart`
- `example/04_providers/xai/live_search.dart`
- `example/05_use_cases/chatbot.dart`
- `example/05_use_cases/web_service.dart`
- `example/05_use_cases/cli_tool.dart`
- `example/05_use_cases/batch_processor.dart`
- `example/05_use_cases/multimodal_app.dart`

The xAI provider README now also demonstrates the same typed-search direction
instead of legacy root-builder snippets.

Some high-visibility compatibility examples are also being reworded even when
their underlying implementation intentionally remains on the old surface. The
goal there is not forced migration, but removing misleading architectural
messaging.

### Stable Cancellation Surface

The example-alignment pass also exposed a real stable-surface gap: the shared
`LanguageModel` path previously had no way to carry a cancellation token
through `CallOptions`.

That gap is now closed:

- `core.CallOptions` now accepts `cancellation`
- stable language, embedding, image, speech, and transcription models now pass
  that token into transport requests
- the shared core export now exposes `TransportCancellation` and
  `TransportCancelledException`

This matters because a stable-first example surface is incomplete if examples
must drop back to the legacy compatibility layer for a basic request-lifecycle
concern such as cancellation.

## Decision

Public examples must follow these rules:

1. Do not present deprecated shared search helpers as the recommended path.
2. Do not present `createProvider(..., extensions: ...)` as normal app code.
3. Prefer stable `AI` facade snippets in README-first material.
4. If a larger example still depends on compatibility builder wiring, label it
   as transitional instead of silently treating it as the target architecture.

## Why This Matters

This repository is already past the point where public examples are neutral.

If examples keep leading users into the compatibility layer:

- new users build on surfaces that are already being phased down
- future removals become harder
- provider-owned typed options look optional rather than foundational
- the architecture appears less coherent than it actually is

Aligning the public example surface is therefore part of the refactor itself,
not just documentation cleanup.

## Status

This alignment pass is partially complete:

- root README is already centered on the stable facade
- the core web-search example is now aligned with provider-owned search
- the core capability-detection example now uses registry/provider declarations
  for selection guidance and a stable `AI.*(...).chatModel(...)` execution
  appendix instead of teaching `ai().*.build()` and `buildOpenAIResponses()`
  as normal application flow
- the core chat-basics example now teaches prompt-message roles, conversation
  replay, and response metadata through `AI.openai(...).chatModel(...)` plus
  shared `generateTextCall(...)`, rather than legacy `ChatCapability` and
  `ChatMessage`
- the core capability-factory example now explicitly presents `build*()`
  helpers as typed compatibility bridges for migration and provider-owned
  capability families, rather than as the new primary app-facing architecture
- the core cancellation example now uses stable `CallOptions(cancellation: ...)`
  for `generateTextCall(...)` and `streamTextCall(...)`, while keeping
  `buildModelListing()` isolated as an explicit compatibility boundary because
  model listing still has no stable facade
- the getting-started configuration and provider-comparison examples now also
  use the stable `AI` facade and shared text-call layer
- the environment-setup example now also demonstrates stable model creation
  from environment-driven config rather than legacy provider builders
- the xAI live-search example and provider README now also use typed
  `XAIGenerateTextOptions`
- the Groq fast-inference example now also uses the stable `LanguageModel`
  surface plus shared `generateTextCall(...)` and `streamTextCall(...)`
- the Anthropic extended-thinking example now also uses stable
  `AI.anthropic(...).chatModel(...)` plus typed
  `AnthropicGenerateTextOptions`
- the Anthropic streaming-tool example now also uses the shared
  `streamTextCall(...)` event model with stable `FunctionToolDefinition`
  schemas instead of legacy `ChatCapability` and `Tool.function(...)`
- the Anthropic MCP connector example now also uses typed
  `AnthropicGenerateTextOptions.mcpServers` with shared `generateTextCall(...)`
  results instead of builder extensions plus `AnthropicChatResponse` casts
- the OpenAI image-generation and audio examples now also use stable
  `imageModel(...)`, `speechModel(...)`, and `transcriptionModel(...)`
  entrypoints, while explicitly documenting image editing, variations, and
  translation as compatibility-only boundaries
- the OpenAI advanced-features example now also uses stable
  `generateTextCall(...)`, `streamTextCall(...)`, shared tool-call replay, and
  typed `OpenAIGenerateTextOptions`, while treating Assistants-era helpers as a
  compatibility boundary instead of normal application architecture
- the OpenAI GPT-5 feature example now also uses stable
  `AI.openai(...).chatModel(...)` plus typed `OpenAIGenerateTextOptions` for
  verbosity and reasoning-effort controls instead of legacy builder flags
- the OpenAI image/file message example now also teaches shared prompt parts
  (`TextPromptPart`, `ImagePromptPart`, `FilePromptPart`) instead of legacy
  `ChatMessage.*` convenience constructors and explicit Responses-vs-Chat API
  distinctions
- the Google provider README now also distinguishes stable embedding, image,
  and one-shot speech surfaces from compatibility-only streaming TTS examples
- the Google embeddings and image-generation examples now also use stable
  `embeddingModel(...)` and `imageModel(...)` entrypoints with typed
  `GoogleEmbedOptions` and `GoogleImageOptions`
- the legacy xAI Grok example under `example/04_providers/others/` now also
  runs on the stable `AI.xai(...).chatModel(...)` facade with typed live-search
  options
- the provider overview and provider-specific README files now explicitly mark
  which providers already have stable facades and which remain
  compatibility-oriented
- the chatbot, CLI, and web-service use-case examples now also depend on
  injected stable `LanguageModel` instances and shared text-call helpers
- the batch-processing use-case example now also runs on stable
  `LanguageModel` injection rather than legacy `ChatCapability` wiring
- the multimodal use-case example now also uses stable `LanguageModel`,
  `ImageModel`, and `SpeechModel` entrypoints instead of legacy capability
  builders
- high-visibility example READMEs now explain the stable-vs-compatibility split
- the core-features README now also removes legacy guidance such as "always use
  specialized build methods" and instead teaches stable-first app code with
  explicit compatibility boundaries
- the stable shared surface now also includes request cancellation on
  `CallOptions`, so example guidance no longer needs the legacy chat layer just
  to teach aborted requests

Remaining work can continue incrementally on the older example files that still
use legacy builder flows internally.

The remaining OpenAI Responses-oriented examples are now explicitly treated as
boundary material rather than target architecture:

- stable built-in tool, reasoning, and streaming usage should stay on
  `AI.openai(...).chatModel(...)` plus shared call helpers
- provider-specific lifecycle helpers such as `getResponse(...)`,
  `continueConversation(...)`, and `deleteResponse(...)` remain compatibility
  surfaces until a separate stable contract is designed
