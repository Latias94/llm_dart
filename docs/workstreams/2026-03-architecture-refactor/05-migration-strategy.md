# Migration Strategy

## Migration Principles

This refactor allows breaking changes, but that does not mean uncontrolled replacement.

The migration strategy must ensure:

- the old and new architectures can coexist for a period
- the highest-value mainlines move first
- each phase can still run tests and ship preview versions
- not every provider has to be rewritten at once

## 1. Migration Phases

## Phase 0: Freeze the Design

Goals:

- freeze the new core spec
- freeze prompt, result, and UI message models
- freeze package and module boundaries

Deliverables:

- the documents in this directory reach a first stable version
- key names and directions stop changing dramatically

## Phase 1: Establish the New Skeleton

Goals:

- create the workspace
- create `llm_dart_core`
- create `llm_dart_transport`
- create the facade compatibility shell

Deliverables:

- the new spec compiles
- the old code still works

## Phase 2: Migrate the OpenAI Mainline

Goals:

- implement the new `LanguageModel`
- implement `generateText` and `streamText`
- migrate OpenAI Chat
- migrate OpenAI Responses
- extract shared OpenAI-family codecs

Why this phase matters first:

- it is the most complex current path
- it offers the highest reuse payoff
- it validates whether the new architecture is actually viable

## Phase 3: Migrate Anthropic and Google

Goals:

- migrate the Anthropic messages adapter
- migrate Anthropic reasoning, tools, and MCP connector
- migrate Google chat, image, embedding, and TTS

Why this phase matters:

- these two providers are the best test of whether provider-specific features can stay out of core

## Phase 4: Migrate the Remaining Providers

Goals:

- move DeepSeek, Groq, xAI, and Phind into the OpenAI-family profile model
- move Ollama and ElevenLabs into `community`

## Phase 5: Migrate the Flutter Chat Layer

Goals:

- establish `llm_dart_flutter`
- implement `ChatSession`, `ChatTransport`, and `ChatState`
- provide both direct and HTTP transport

## Phase 6: Remove the Old Architecture

Goals:

- remove the old `LLMConfig.extensions` mainline path
- remove the old fat-builder core implementation
- remove duplicate registry concepts
- remove provider-block mixing from the old message model

## 2. Compatibility Strategy

## 1. Keep a Facade in the Short Term

The old entry points should remain temporarily:

- `ai()`
- `createProvider(...)`
- provider builders

But internally they should adapt into the new model-based API.

## 2. Provide Legacy Adapters

Recommended adapters:

- `LegacyChatCapabilityAdapter`
- `LegacyBuilderAdapter`
- `LegacyMessageAdapter`

Purpose:

- let current examples and user code continue to run
- migrate gradually instead of cutting everything at once

## 3. Migrate the Highest-Value Examples First

The following examples should be updated first:

- getting started
- streaming chat
- tool calling
- reasoning
- Flutter integration

These are the examples most likely to expose real architectural flaws early.

## 3. Main Risks

## 1. Prompt and UI Message Layers Stay Mixed

If those two layers are not actually separated, later provider migrations will keep recreating the same coupling.

## 2. OpenAI Responses Distorts the Core

Responses is powerful, but it must not define the shape of the entire language-model spec.

## 3. Flutter Gets Bound to a Framework Too Early

If the session layer is tied directly to `ChangeNotifier` or a specific state-management framework, cross-platform reuse will be weaker.

## 4. The Migration Maintains Two Full Implementations for Too Long

Adapters should be used aggressively to avoid maintaining two completely separate systems longer than necessary.

## 5. Long-Tail Providers Slow Down the Mainline

The first phases should not try to finish every provider at the same time. The mainline abstractions and the highest-value provider paths must come first.

## 4. Validation Strategy

Each phase should include at least:

- unit tests
- golden-style stream event tests
- provider request/response codec tests
- Flutter chat-layer state-machine tests

Recommended new test categories:

- prompt normalization tests
- stream-part accumulation tests
- UI message projection tests
- transport reconnection tests

## 5. Suggested Old-to-New Type Mapping

The migration should gradually map:

- `ChatMessage` -> `PromptMessage` or `ChatUiMessage`
- `ChatResponse` -> `GenerateTextResult`
- `ChatStreamEvent` -> `TextStreamEvent`
- `LLMConfig` -> model options plus call options
- `ChatCapability` -> `LanguageModel` plus `generateText` and `streamText`

## 6. Conditions for Removing the Old Architecture

The old architecture can be considered removable when all of the following are true:

- OpenAI, Anthropic, and Google mainlines have migrated
- Flutter `ChatSession` is usable
- the main README examples use the new API
- the old builder has become a thin compatibility wrapper
- `extensions` is no longer the primary extension mechanism
