# Runtime Event And Tool Loop Boundary

Status: active
Opened: 2026-05-13

## Why This Workstream Exists

The previous breaking line removed root legacy implementation ownership and
froze the default app-facing prompt path. The next coupling risk is now inside
the runtime itself:

- provider stream events, runtime step lifecycle, tool execution continuation,
  UI projection, and chat transport all share too much semantic ownership
- `generateText(...)`, `streamText(...)`, `generateTextCall(...)`,
  `streamTextCall(...)`, `GenerateTextRunner`, and `StreamTextRunner` do not
  yet present one obvious long-term runtime surface
- chat direct transport streams from `LanguageModel.doStream(...)` directly,
  bypassing the AI runtime tool loop
- tool execution exists both in the AI runner and in chat session state, with
  different state machines and different callback surfaces
- runtime events do not clearly distinguish model-call events from full
  generation-run events

`repo-ref/ai` is useful here because it separates provider model calls,
runtime full streams, tool execution transforms, result facades, UI message
projection, and agent/chat transport. The goal is not to copy its TypeScript
type system. The goal is to take the architectural lesson and make it Dart
native.

## Goal

See [GOAL.md](GOAL.md) for the canonical goal text.

## Reference Model

Relevant `repo-ref/ai` areas:

- `repo-ref/ai/packages/ai/src/generate-text/stream-language-model-call.ts`
  - owns a single provider/model invocation stream boundary
- `repo-ref/ai/packages/ai/src/generate-text/stream-text.ts`
  - owns full generation stream, step lifecycle, tool continuation, output
    parsing, and UI projection
- `repo-ref/ai/packages/ai/src/generate-text/create-execute-tools-transformation.ts`
  - keeps local tool execution as a stream transform, not provider code
- `repo-ref/ai/packages/ai/src/generate-text/execute-tool-call.ts`
  - centralizes tool execution callbacks, context, timeouts, and preliminary
    outputs
- `repo-ref/ai/packages/ai/src/agent/tool-loop-agent.ts`
  - wraps reusable tool-loop settings behind an agent abstraction
- `repo-ref/ai/packages/ai/src/ui/direct-chat-transport.ts`
  - sends chat through an agent/runtime result, not directly through a provider
    model stream

## Target Architecture

- `llm_dart_provider`
  - owns provider-facing language model request/result contracts
  - owns model-call stream parts only
  - does not own runtime step lifecycle, UI chunks, chat status, or local tool
    execution loops
- `llm_dart_ai`
  - owns app-facing `generateText(...)`, `streamText(...)`,
    `generateTextCall(...)`, and `streamTextCall(...)`
  - owns full generation run events, step lifecycle, tool execution,
    structured output, result facades, UI projection, and optional agent
    helpers
  - preserves `messages:` + `ModelMessage` as the default prompt path and
    `prompt:` + `PromptMessage` as the advanced provider-contract path
- `llm_dart_chat`
  - owns chat session state, persistence, transport protocols, and ergonomic
    client-side tool output submission
  - consumes AI runtime UI streams or agent streams instead of reimplementing
    provider-level generation loops
- provider packages
  - continue to own provider wire codecs, typed provider options, capability
    profiles, replay helpers, and provider-native features
  - never depend on `llm_dart_ai`, `llm_dart_chat`, Flutter, or root

## Non-Goals

This workstream should not:

- copy the Vercel AI SDK file layout or TypeScript generic utility patterns
- remove typed provider options or provider-native replay features
- introduce a public `llm_dart_provider_utils` package before repeated code
  proves a stable public contract
- flatten provider-executed tools into generic function tools
- make chat the owner of language model runtime semantics
- preserve duplicate runtime entrypoints just to avoid a breaking change

## Documents

- [GOAL.md](GOAL.md)
  - Canonical goal text and completion definition.
- [TODO.md](TODO.md)
  - Executable checklist for this architecture line.
- [MILESTONES.md](MILESTONES.md)
  - Milestones, acceptance criteria, and status.
- [01-reference-and-gap-audit.md](01-reference-and-gap-audit.md)
  - Source-versus-reference audit that motivates the line.
- [02-target-runtime-surface.md](02-target-runtime-surface.md)
  - Proposed v2 runtime surface, event vocabulary, tool loop, and chat
    boundary.
- [03-m1-boundary-decision-freeze.md](03-m1-boundary-decision-freeze.md)
  - Frozen M1 names, ownership rules, migration story, callback vocabulary, and
    first implementation slice.
- [04-provider-event-vocabulary-first-slice.md](04-provider-event-vocabulary-first-slice.md)
  - First implemented code seam for `LanguageModelStreamEvent`, provider event
    validation, and AI runtime stream adaptation.
- [05-focused-provider-stream-naming-migration.md](05-focused-provider-stream-naming-migration.md)
  - Production provider-facing stream APIs, codecs, replay helpers, and test
    fakes migrated to `LanguageModelStreamEvent` naming.
- [06-provider-stream-serialization-guard.md](06-provider-stream-serialization-guard.md)
  - Provider-owned stream JSON codec plus source guards that prevent focused
    providers from coupling back to runtime stream names.
- [07-core-prompt-replay-test-alignment.md](07-core-prompt-replay-test-alignment.md)
  - Core compatibility tests aligned with typed replay options instead of
    removed prompt-side `providerMetadata` fields.
- [08-ai-runtime-stream-serialization-owner.md](08-ai-runtime-stream-serialization-owner.md)
  - `llm_dart_ai` starts owning the app-facing `TextStreamEventJsonCodec`
    name while preserving the existing wire protocol.
- [09-ai-runtime-stream-event-export-owner.md](09-ai-runtime-stream-event-export-owner.md)
  - `llm_dart_ai` starts owning app-facing full-stream event names through
    compatibility aliases and updates `llm_dart_core` re-exports.
- [10-provider-runtime-dependency-guards.md](10-provider-runtime-dependency-guards.md)
  - Source and dependency guards that keep provider packages independent from
    AI runtime, chat, Flutter, and root app layers.
- [11-runtime-only-provider-event-guard.md](11-runtime-only-provider-event-guard.md)
  - Runtime-only event classes are marked in provider compatibility code and
    focused provider packages are guarded from emitting them.
- [12-streaming-result-projection-accessors.md](12-streaming-result-projection-accessors.md)
  - Streaming text, text-call, and structured-output results expose consistent
    text stream and chat UI projection accessors.
- [13-direct-chat-transport-runtime-path.md](13-direct-chat-transport-runtime-path.md)
  - Direct chat transport now streams through the AI runtime path before
    projecting to chat UI chunks.
- [14-stream-text-run-result-accessors.md](14-stream-text-run-result-accessors.md)
  - `StreamTextRunResult` exposes final content, usage, metadata, source, file,
    and tool convenience accessors.
- [15-provider-stream-codec-owned-path.md](15-provider-stream-codec-owned-path.md)
  - `LanguageModelStreamEventJsonCodec` owns provider model-call
    serialization directly instead of delegating through the full runtime
    stream codec.
- [16-ai-runtime-event-vocabulary-owner.md](16-ai-runtime-event-vocabulary-owner.md)
  - `llm_dart_ai` owns concrete full-stream event classes and bridges provider
    model-call events into the runtime vocabulary.
- [17-ai-native-stream-codec.md](17-ai-native-stream-codec.md)
  - `TextStreamEventJsonCodec` now serializes AI-owned full-stream events
    directly without delegating through the provider event codec.
- [18-provider-public-stream-export-narrowing.md](18-provider-public-stream-export-narrowing.md)
  - `llm_dart_provider` no longer publicly exports the legacy full-stream
    event base, runtime-only events, or the legacy full-stream codec.
- [19-provider-native-stream-event-vocabulary.md](19-provider-native-stream-event-vocabulary.md)
  - `llm_dart_provider` now owns a real provider-only
    `LanguageModelStreamEvent` sealed class and no longer contains the legacy
    full-stream event file or codec.
- [20-primary-runtime-entrypoints.md](20-primary-runtime-entrypoints.md)
  - `generateText(...)` and `streamText(...)` now use the AI runtime runner
    path while preserving their existing return types.
- [21-provider-metadata-boundary-guard.md](21-provider-metadata-boundary-guard.md)
  - Provider metadata is guarded as response-side and replay-only data; input
    customization stays on typed provider options.
- [22-tool-execution-lifecycle-callbacks.md](22-tool-execution-lifecycle-callbacks.md)
  - AI runtime local function tool execution now has start and finish
    callbacks on the primary and advanced text runtime helpers.
