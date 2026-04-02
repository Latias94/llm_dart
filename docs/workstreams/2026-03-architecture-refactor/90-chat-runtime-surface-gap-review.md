# 90. Chat Runtime Surface Gap Review

## Goal

After the runtime split between `llm_dart_chat` and `llm_dart_flutter`, the
next question is narrower:

> Which remaining `llm_dart_chat` surface differences versus `repo-ref/ai`
> still represent a real maturity gap, and which ones are React/UI-store
> ergonomics that should stay out of the shared Dart runtime?

This note freezes that answer so the repository does not drift into copying the
reference API mechanically.

## Reference Inputs

The relevant reference files for this pass are:

- `repo-ref/ai/packages/ai/src/ui/chat.ts`
- `repo-ref/ai/packages/ai/src/ui/chat-transport.ts`
- `repo-ref/ai/packages/ai/src/ui/http-chat-transport.ts`
- `repo-ref/ai/packages/ai/src/ui/direct-chat-transport.ts`
- `repo-ref/ai/packages/ai/src/ui/process-ui-message-stream.ts`
- `repo-ref/ai/packages/react/src/use-chat.ts`

The important lesson is not package count or exact naming. The useful lesson is
which responsibilities already belong to the shared chat runtime in the mature
reference:

- stateful chat/session orchestration
- transport abstraction
- resumable streaming
- local tool-output and approval mutation
- transport request customization

At the same time, the reference also contains React-oriented store ergonomics
that do **not** automatically belong in a pure Dart runtime.

## Current `llm_dart_chat` Surface

`llm_dart_chat` now already owns the correct shared runtime boundary:

- `ChatSession`
- `DefaultChatSession`
- `ChatTransport`
- `DirectChatTransport`
- `HttpChatTransport`
- `ToolExecutionRegistry`
- session snapshots and persistence
- `ChatUiStreamChunk` consumption and UI-message projection

Compared with the reference, the runtime is already aligned on the most
important point:

- a framework-neutral stateful runtime lives below the UI adapter

The remaining review is therefore about runtime surface maturity, not package
ownership anymore.

## Gap Matrix

### 1. Transport Request Customization

Reference signal:

- `HttpChatTransport` supports `prepareSendMessagesRequest`
- `HttpChatTransport` supports `prepareReconnectToStreamRequest`

Why it matters for Dart too:

- mobile and Flutter apps often need backend-specific auth headers
- some apps need per-request routing, tenancy, locale, tracing, or session IDs
- these concerns belong to the app-backend transport layer, not to provider
  invocation options

Decision:

- adopt

Implementation direction:

- `HttpChatTransport` now exposes `prepareSendMessagesRequest`
- `HttpChatTransport` now exposes `prepareReconnectRequest`
- these hooks can override endpoint, headers, timeout, and typed transport
  payloads

Important boundary:

- this is transport customization, not provider-option serialization
- `CallOptions` still must not be serialized across the generic HTTP chat
  protocol

### 2. Explicit Request Trigger Semantics

Reference signal:

- the reference transport receives request triggers such as
  `submit-message` and `regenerate-message`

Why it matters:

- request customization is much less useful if the transport cannot tell why a
  request exists
- `llm_dart_chat` has more than one outbound request reason:
  - user message submission
  - regenerate
  - tool-output continuation
  - approval continuation

Decision:

- adopt

Implementation direction:

- `ChatTransportRequest` now carries `ChatTransportTrigger`

Important boundary:

- the trigger is runtime/transport context
- it does not widen the shared prompt model
- it does not require the generic HTTP payload itself to become provider-aware

### 3. JSON-Safe Request Metadata

Reference signal:

- the reference runtime carries transport-oriented `metadata` separately from
  model-call settings

Why it matters:

- `llm_dart_transport` request envelopes already had a JSON-safe `metadata`
  field
- `llm_dart_chat` previously had no shared way to populate it

Decision:

- adopt

Implementation direction:

- `ChatRequestOptions` now carries JSON-safe `metadata`
- `HttpChatTransport` forwards that metadata into the request envelope

Important boundary:

- this metadata is for the app/backend request contract
- it is not a substitute for provider invocation options
- it is not a second dumping ground for provider-specific model features

### 4. React-Style `setMessages` / Local Message Store Mutation

Reference signal:

- `useChat` exposes `setMessages`

Why it exists in the reference:

- React hooks need local store mutation ergonomics
- the hook must let callers edit UI state and then manually reload

Why this does **not** translate directly:

- `llm_dart_chat` owns replay-safe prompt history and session invariants
- arbitrary message replacement can desynchronize:
  - prompt history
  - tool/approval state
  - snapshot replay
  - assistant-turn continuation assumptions

Decision:

- reject

Rule:

- do not add a generic `setMessages` or mutable message-store API to
  `ChatSession`
- if history editing is needed later, design it as an explicit replay-safe
  session operation, not a raw UI-state setter

### 5. React Store Subscription Ergonomics

Reference signal:

- `useChat` adds throttled `useSyncExternalStore` helpers

Decision:

- reject

Reason:

- these are UI-framework adapter concerns
- the Dart runtime already exposes `ChatState` plus `states`
- `llm_dart_flutter` remains the correct place for controller/listenable
  adapters

### 6. `sendAutomaticallyWhen`

Reference signal:

- the reference runtime exposes a callback that decides whether tool updates
  should auto-submit

Current Dart status:

- `DefaultChatSession` already has a built-in whole-step continuation policy
- it waits until the current step no longer has unresolved local tool output or
  approval work

Decision:

- reject for now

Reason:

- the current built-in continuation rule is simpler and more honest for Flutter
  chat applications
- adding a callback-driven policy now would widen the session contract before a
  concrete Dart-side need is proven

Follow-up rule:

- if manual continuation policy is later required, design it as an explicit
  session continuation policy, not as a copy of the reference callback API

### 7. `resumeStream` As A General UI Hook Ergonomic

Reference signal:

- the reference exposes `resumeStream()` and React `resume: true`

Current Dart status:

- `ChatSession.resume()` exists for reconnect-based error recovery

Decision:

- keep the current narrower Dart rule

Reason:

- reconnect currently belongs to transport-backed recovery after error
- resume-on-mount browser ergonomics are not a shared Dart-runtime
  requirement

### 8. Runtime `onFinish` / `onData` Callbacks

Reference signal:

- the reference exposes `onFinish`
- the reference exposes `onData`

Current Dart status:

- `ChatSession.states` already exposes the full runtime state stream
- `ChatUiStreamChunk` already provides a separate data-part path under the
  session boundary

Decision:

- defer

Reason:

- there is some value in a dedicated finish callback for persistence,
  analytics, or side effects
- however, the state stream is currently sufficient, and this is not as
  foundational as transport request customization

Frozen rule:

- do not add callback-heavy lifecycle APIs in the same pass as transport
  boundary work

### 9. Step-Finish Lifecycle Hooks In The Chat Runtime

Reference signal:

- the reference has richer stream processing and step lifecycle handling

Decision:

- reject in `llm_dart_chat`

Reason:

- richer step lifecycle belongs to the higher-level multi-step runner
- `llm_dart_chat` should stay focused on chat-session orchestration above the
  UI stream layer, not become a second general orchestration runtime

## What Landed In This Pass

The runtime surface now adopts the narrow missing pieces that actually improve
the shared transport/session boundary:

- `ChatRequestOptions.metadata`
- `ChatTransportTrigger`
- `HttpChatTransport.prepareSendMessagesRequest`
- `HttpChatTransport.prepareReconnectRequest`

These changes improve backend integration and transport modularity without
pulling React/store ergonomics into the shared Dart runtime.

## Resulting Boundary

`llm_dart_chat` should continue to own:

- session state transitions
- tool and approval continuation
- prompt-history reconstruction
- request trigger semantics
- transport-facing request metadata
- HTTP transport customization hooks

`llm_dart_chat` should **not** start owning:

- arbitrary local message-store mutation
- React-style store subscription ergonomics
- callback-heavy continuation policy copied from `useChat`
- runner-level step lifecycle APIs

## Next Candidates

If the runtime surface needs another maturity pass later, the next candidates
should be evaluated in this order:

1. determine whether a dedicated session-finish callback is truly needed above
   `states`
2. determine whether replay-safe history editing needs an explicit session API
3. avoid any further widening until at least one real Flutter or backend use
   case proves the need

## Conclusion

The remaining useful lesson from `repo-ref/ai` was narrower than it first
looked.

The right Dart move was **not** to copy `useChat`.

The right Dart move was to strengthen the shared transport boundary:

- explicit request semantics
- JSON-safe request metadata
- request customization hooks on `HttpChatTransport`

That keeps `llm_dart_chat` closer to the mature reference architecture while
still preserving the repository's Dart-first and Flutter-first design
constraints.
