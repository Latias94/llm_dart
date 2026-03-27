# Provider Replay Fidelity Policy

## Goal

This document freezes how provider adapters should handle assistant-turn replay.

The main problem is not whether the UI can render the previous assistant turn. The main problem is whether a follow-up provider call can continue from that turn without losing provider-critical semantics.

That means replay fidelity is an adapter concern with shared-core prerequisites:

- the core must preserve replayable assistant parts
- the core must preserve JSON-safe provider metadata
- each provider adapter must decide which replay shapes are truly valid for its wire protocol

This is where `llm_dart` should learn from the Vercel AI SDK reference without copying all of its internal request-shaping logic blindly.

## 1. Shared Boundary

## 1. Replayable Assistant Semantics Live In Core

The core layer is responsible for preserving replayable assistant semantics across:

- prompt parts
- result/content parts
- stream events
- UI parts
- prompt and UI codecs
- chat-session prompt reconstruction

The replayable assistant subset currently includes:

- text
- reasoning
- reasoning-file
- tool call
- tool result
- replayable custom parts

The core should preserve these semantics even when a provider cannot replay all of them later.

## 2. Provider Metadata Is The Replay Substrate

Replay-critical provider hints must travel through namespaced, JSON-safe `ProviderMetadata`.

Examples:

- OpenAI Responses item IDs
- OpenAI message phase
- OpenAI reasoning encrypted content
- Google thought signatures
- provider-native tool replay IDs

If a provider-specific replay hint is required for a faithful follow-up turn, it should not be left only inside transient stream state.

## 3. The Core Does Not Promise One Universal Replay Wire Shape

The unified API should not claim that every replayable assistant part can always be converted into every provider request format.

The core promise is narrower and stronger:

- preserve replayable semantics
- preserve replay-critical provider metadata
- let the provider adapter make an explicit replay decision

## 2. Adapter Rules

Each provider adapter must follow one of these paths for every replayable assistant part:

1. encode a provider-valid replay representation
2. drop the part and emit a `ModelWarning`
3. fail fast only when partial replay would create an invalid request shape that cannot be recovered safely

Silent lossy replay is no longer acceptable.

Recommended review checklist for every adapter:

- Which assistant parts are replayable for this provider?
- Which provider metadata fields are required for a faithful replay?
- Which parts must be merged before request encoding?
- Which parts must be dropped with warnings?
- Which provider shortcuts depend on extra conversation-store semantics that the shared architecture does not model yet?

## 3. OpenAI Responses Policy

## 1. What Must Be Preserved

For OpenAI Responses replay, the current minimum fidelity set is:

- assistant text `itemId`
- assistant text `phase`
- reasoning `itemId`
- reasoning encrypted content
- tool-call `itemId`
- `openai.compaction` replay state

These fields are replay-critical because OpenAI Responses uses them to continue provider-owned assistant items rather than only plain text history.

## 2. Encoding Rules

The OpenAI adapter should currently encode:

- assistant text as assistant message items that preserve `id` and optional `phase`
- reasoning parts as `reasoning` items
- reasoning parts with the same `itemId` as one merged reasoning item with appended summary parts
- tool calls as `function_call` items that preserve `id` when available
- `openai.compaction` custom parts as canonical `compaction` items with `id` and `encrypted_content`

## 3. Decode Rules

The OpenAI adapter must also preserve replay-critical metadata while decoding provider output.

That currently includes:

- message `phase`
- reasoning encrypted content
- compaction encrypted content

If decode drops these fields, later prompt reconstruction cannot recover them.

## 4. What Stays Out For Now

Do not add OpenAI `item_reference` replay shortcuts yet.

Those shortcuts depend on explicit conversation-store semantics such as:

- whether the conversation is already stored server-side
- whether a replay item already exists in that stored conversation

The current Dart architecture does not model those concepts yet, so adding `item_reference` now would create a misleading partial abstraction.

## 4. Anthropic Messages Policy

## 1. What Can Be Replayed Natively

The Anthropic adapter should preserve assistant replay only where Anthropic has a native request block that matches the semantics cleanly.

That currently includes:

- assistant text
- `tool_use`
- `server_tool_use`
- `mcp_tool_use`

This preserves the provider-executed tool paths that Anthropic can actually continue.

## 2. What Must Be Dropped Explicitly

The Anthropic adapter should currently drop these assistant replay parts with explicit warnings:

- reasoning
- assistant file
- reasoning-file
- replayable custom parts such as `openai.compaction`

This is intentionally conservative.

Anthropic should not pretend to preserve provider-specific replay state that it cannot encode back into an Anthropic request.

## 3. Empty Assistant Blocks Must Not Survive

If all parts in an assistant block are dropped, the adapter should not emit an empty assistant message.

Dropping the whole block is safer than emitting an invalid or semantically misleading empty assistant item.

## 5. Google Direction

Google remains the strongest reason why replay fidelity must stay a first-class design concern.

The current direction remains:

- preserve thought signatures through provider metadata
- preserve reasoning-file as a first-class common model
- keep replay fidelity requirements in the Google adapter rather than flattening thought-only artifacts into normal text or file history

Google still needs a final replay-policy pass, but the boundary is already clear.

## 6. Package-Boundary Implications

This policy reinforces the package split:

- `llm_dart_core` owns replayable semantics and provider-metadata plumbing
- provider packages own replay encoding and replay downgrade rules
- `llm_dart_flutter` owns prompt reconstruction and session persistence, not provider wire conversion

That split is important because replay fidelity is where old architectures often re-couple the UI layer, provider layer, and transport layer again.

## 7. Practical Review Rule

When reviewing a replay-related change, ask this question:

> If a session is restored and the next user turn is submitted, will the provider receive the same replay-critical semantics, or will it receive only a display-friendly approximation?

If the answer is “display-friendly approximation”, the change is not done yet unless the downgrade is explicit and documented through warnings.
