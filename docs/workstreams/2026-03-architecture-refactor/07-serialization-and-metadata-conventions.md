# Serialization And Metadata Conventions

## Goal

The refactor now has stable prompt, stream, and UI message shapes, but two cross-cutting rules still need to be frozen before persistence and replay work can move safely:

- how `ProviderMetadata` is namespaced
- how `PromptMessage`, `ChatUiMessage`, and session state are serialized

If these rules stay implicit, the codebase will drift back toward ad hoc maps, provider-specific escape hatches, and incompatible persistence formats.

## 1. Core Principle

The library should separate three concerns clearly:

1. domain models
2. provider metadata
3. serialization codecs

That means:

- domain models stay as plain immutable objects
- provider metadata stays provider-owned and provider-scoped
- serialization stays in explicit codecs and versioned envelopes instead of spreading `toJson()` logic across every model type

## 2. Provider Metadata Namespace Rules

## 1. `ProviderMetadata` Is Provider-Owned, Not Common Metadata

`ProviderMetadata` should only carry information that belongs to a specific provider or provider-family implementation.

Good examples:

- OpenAI Responses item IDs
- OpenAI MCP approval request IDs
- Anthropic cache markers
- Google grounding payload fragments

Bad examples:

- message role
- finish reason
- response timestamp
- generic usage counts

Those belong in explicit core fields or documented common UI metadata keys instead.

## 2. Top-Level Keys Must Be Namespace Keys

The top-level map inside `ProviderMetadata` should use namespace keys, not flat mixed keys.

Recommended shape:

```dart
const ProviderMetadata({
  'openai': {
    'itemId': 'msg_123',
    'approvalRequestId': 'mcpr_456',
  },
});
```

Not recommended:

```dart
const ProviderMetadata({
  'itemId': 'msg_123',
  'approvalRequestId': 'mcpr_456',
});
```

Rules:

- the first-level key should normally match the provider or provider-family ID such as `openai`, `anthropic`, or `google`
- provider-family shared codecs may use the family namespace, for example `openai`
- a single `ProviderMetadata` object may contain multiple namespaces only when multiple provider systems genuinely contribute to the same artifact

## 3. Namespace Values Must Stay JSON-Safe

`ProviderMetadata` must stay serializable by default.

Allowed values:

- `null`
- `bool`
- `num`
- `String`
- `List<Object?>` containing JSON-safe values
- `Map<String, Object?>` containing JSON-safe values

Disallowed values:

- SDK client objects
- `Stream`
- `Future`
- function values
- raw provider response classes

If a provider needs richer local-only state, it should keep that state outside the serialized metadata path.

## 4. Common Projection Must Stay Outside Provider Metadata

When the core layer promotes a concept into a stable field or documented UI metadata key, providers should stop duplicating it in provider metadata unless the provider-specific raw detail is still needed.

Examples:

- `ChatUiMetadataKeys.responseId` is the common projection
- `ProviderMetadata({'openai': {'itemId': 'resp_123'}})` is the provider detail

These are related, but they are not the same piece of information.

## 5. Tool Metadata Must Stay Split By Lifecycle Stage

Tool-related metadata should remain split between call and result paths.

That means:

- request-time tool detail goes into `callProviderMetadata`
- result-time tool detail goes into `resultProviderMetadata`

This is important because approval, provider execution, and client execution may all happen at different times.

## 3. Custom Part `kind` Namespace Rules

Custom kinds are required, but they must not become another unstructured dumping ground.

Rules:

- built-in library custom kinds must be namespaced
- the namespace should be the first segment
- provider-owned kinds should start with the provider or provider-family ID
- application-owned kinds should start with the application or package namespace

Recommended examples:

- `openai.web_search_call`
- `openai.reasoning.summary`
- `anthropic.mcp.cache_marker`
- `my_app.vote_card`

Not recommended:

- `search`
- `reasoning`
- `custom`
- `data`

Interpretation rules:

- `kind` identifies semantics
- `data` carries the provider or app payload
- consumers may switch on `kind` without needing to infer semantics from random nested fields

## 4. Serialization Architecture

## 1. Do Not Put `toJson()` On Every Domain Model

The refactor should avoid turning core domain classes into persistence-aware transport DTOs.

Recommended direction:

- keep domain models focused on runtime semantics
- add explicit codec objects for serialization
- use versioned envelopes

This keeps the domain layer stable while allowing the persistence format to evolve carefully.

## 2. Use Separate Codecs For Separate Artifacts

The library should eventually provide separate codecs for:

- prompt history
- UI message lists
- chat-session snapshots

Recommended future surfaces:

```dart
abstract interface class PromptJsonCodec { ... }
abstract interface class ChatUiJsonCodec { ... }
abstract interface class ChatSessionSnapshotJsonCodec { ... }
```

Do not force one giant universal message codec that tries to cover every runtime object in the library.

## 3. Versioned Envelope Required

Every serialized top-level artifact should include a schema version and artifact kind.

Recommended pattern:

```json
{
  "schemaVersion": "2026-03-1",
  "kind": "chat-session-snapshot",
  "data": { ... }
}
```

This is required for:

- forward migration
- compatibility windows
- persistence debugging
- safe breaking changes

## 5. What Must Be Serializable

## 1. Prompt History

Prompt history must be serializable because:

- continuation depends on it
- approval response is part of it
- tool-result replay depends on it

The serialized prompt protocol must support:

- `system`, `user`, `assistant`, and `tool` roles
- all current prompt parts
- assistant-side reasoning, reasoning-file, and replayable custom parts
- provider-executed tool call flags such as `providerExecuted`, `isDynamic`, and `title`
- tool approval request and response parts
- part-level provider metadata on replayable prompt parts so provider continuation hints such as Google thought signatures survive round-trip serialization

Prompt persistence is not only a display cache.

It is also the continuation substrate for later provider calls, so losing part-level provider metadata or reasoning-file parts would make restored sessions look correct in the UI while becoming semantically lossy for follow-up turns.

## 2. UI Messages

`ChatUiMessage` must be serializable for:

- local persistence
- Flutter state restoration
- offline cache
- debugging snapshots

The protocol must support:

- role
- ordered parts
- stable common metadata keys
- provider metadata on parts where present

## 3. Chat Session Snapshot

For real session restore, serializing `ChatState` alone is not enough.

The snapshot needs at least:

- `chatId`
- visible `messages`
- `promptHistory`
- `status`
- last serializable error representation

Recommended future shape:

```dart
final class ChatSessionSnapshot {
  final String chatId;
  final List<PromptMessage> prompt;
  final List<ChatUiMessage> messages;
  final ChatStatus status;
  final Object? error;
}
```

The actual runtime `DefaultChatSession` may hold additional transient state, but that transient state should not define the persistence format.

Current baseline limitation:

- snapshot export should fail while an assistant turn is still active because the library does not yet support reconnecting or resuming an in-flight stream

## 6. Value Encoding Rules

## 1. Structured Values

For `input`, `output`, `data`, and metadata payloads, the default serialization path should only accept JSON-safe values.

If callers want richer application data, they should convert it before storing it in prompt, UI, or metadata payloads.

## 2. `Uri`

Known URI fields should serialize as strings.

Examples:

- `SourceReference.uri`
- `FilePromptPart.uri`
- `GeneratedFile.uri`

## 3. Binary Data

Binary payloads must use an explicit base64 envelope.

Recommended shape:

```json
{
  "encoding": "base64",
  "data": "..."
}
```

This applies to:

- `FilePromptPart.bytes`
- `ImagePromptPart.bytes`
- `GeneratedFile.bytes`

## 4. Date And Time

Date values should serialize as ISO-8601 strings in UTC or with explicit offset.

This especially applies to:

- response timestamps
- future session snapshot timestamps if they are added

## 7. What Should Not Be Serialized By Default

Do not serialize these by default:

- active stream subscriptions
- transport cancellation handles
- provider client instances
- retry state
- live accumulator internals

These are runtime mechanics, not conversation state.

`RawChunkEvent` payloads should only be persisted in explicit diagnostic mode, because they can be large, unstable, or provider-shape dependent.

## 8. Recommended Implementation Order

1. Freeze provider metadata and custom-kind namespace rules
2. Add JSON value helpers and shared codec test fixtures
3. Implement prompt JSON codecs in `llm_dart_core`
4. Implement `ChatUiMessage` JSON codecs in `llm_dart_core`
5. Add a `ChatSessionSnapshot` model and codec in `llm_dart_chat`
6. Add round-trip tests before wiring persistence adapters

## 9. Conclusion

The important architectural decision is not “which JSON shape looks nice today”.

The important decision is:

- provider detail must stay namespaced
- common fields must stay common
- persistence must use explicit codecs and versioned envelopes
- session restore must serialize both UI and prompt history, not only rendered messages

Freezing these rules now will make later Flutter persistence, approval replay, and provider continuation work much less risky.
