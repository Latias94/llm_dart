# Chat Runtime vs Flutter Adapter Split

## Goal

Freeze the package boundary between the reusable chat runtime and the
Flutter-only adapter layer.

This follows the same architectural principle as `repo-ref/ai`:

- keep the stateful chat runtime framework-neutral
- keep the UI-framework adapter thin

But it does **not** copy the reference package granularity. We still keep a
medium-grained split that is easier to maintain for this repository.

## Final Ownership

## `llm_dart_chat`

Owns the reusable pure Dart runtime:

- `ChatSession`
- `ChatTransport`
- `DefaultChatSession`
- `DirectChatTransport`
- `HttpChatTransport`
- `ChatState`
- `ChatInput`
- `ChatMessageMapper`
- `ToolExecutionRegistry`
- snapshot codecs and session persistence

Dependency rules:

- depends on `llm_dart_core`
- depends on `llm_dart_transport`
- must not depend on Flutter
- must not depend on concrete provider packages

## `llm_dart_flutter`

Owns only Flutter-facing adapters:

- `ChatController`
- controller-aware `ChatPersistenceAdapter` convenience
- re-export of `llm_dart_chat`

Dependency rules:

- depends on `llm_dart_chat`
- may import `llm_dart_core` directly for shared type usage in adapter code
- may depend on `flutter/foundation`
- must not own the reusable chat runtime

## Why This Split Is Better Than Keeping Everything In `llm_dart_flutter`

If the session and transport runtime stays in the Flutter package:

- CLI and server-side Dart apps cannot reuse it cleanly
- Flutter-specific dependencies become harder to contain
- architecture docs keep mixing runtime concerns with widget concerns
- future backend-oriented chat reuse keeps fighting the package boundary

With `llm_dart_chat`:

- the same runtime works for Dart CLI, server, and Flutter
- `llm_dart_flutter` becomes honest about its role
- testing stays simpler because most chat behavior remains pure Dart
- the package count still stays moderate

## Persistence Boundary

The persistence split is intentionally asymmetric:

- `llm_dart_chat`
  - snapshot/session persistence only
- `llm_dart_flutter`
  - `ChatController` save/restore convenience

That keeps the shared runtime free from Flutter controller types while still
giving Flutter apps a one-import convenience layer.

## Relationship To The HTTP Protocol Split

This package split complements the earlier transport split:

- `llm_dart_transport`
  - owns HTTP chat wire codecs and the backend SSE/reference adapter
- `llm_dart_chat`
  - owns the runtime client/session usage of that transport
- `llm_dart_flutter`
  - owns only Flutter adapters above the runtime

Together, these rules prevent two common regressions:

- backend helpers drifting into the Flutter package
- shared session runtime drifting back into the Flutter package

## Frozen Rule

From this point forward:

- new provider-agnostic chat runtime logic belongs in `llm_dart_chat`
- new Flutter-specific `ValueNotifier` / adapter logic belongs in
  `llm_dart_flutter`
- neither provider packages nor the Flutter package should become the new home
  for shared chat orchestration
