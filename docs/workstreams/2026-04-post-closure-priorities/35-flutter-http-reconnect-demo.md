# 35 Flutter HTTP Reconnect Demo

## Why This Note Exists

The earlier Flutter demos already validated backend-owned routing, tool
approval, and paused-state snapshot restore.

The next real UI question was narrower:

- does the current Flutter/session/transport split already support
  `HttpChatTransport` reconnect recovery through `resume()`?

This slice answers that question with a widget-level demo and regression test.

## Scope

This slice adds:

- `packages/llm_dart_flutter/example/http_reconnect_demo_support.dart`
- `packages/llm_dart_flutter/example/flutter_http_reconnect_demo.dart`
- `packages/llm_dart_flutter/test/flutter_http_reconnect_demo_test.dart`

It also updates the package and example docs so the reconnect path is easier to
discover.

## Demo Shape

The demo uses existing surfaces only:

1. `ChatController` mirrors `DefaultChatSession`
2. `HttpChatTransport` owns the reconnect token and replay buffer
3. the first stream attempt fails mid-message with a retryable transport error
4. the UI renders the partial assistant output and error state
5. the UI calls `resume()`
6. the transport replays the buffered current-turn chunks and then appends the
   resumed tail
7. the assistant finishes without any reconnect-specific widening in
   `llm_dart_core`

The demo also uses `prepareReconnectRequest(...)` to pass app-owned reconnect
metadata through the existing transport boundary.

## What This Revalidates

This demo revalidates several frozen decisions:

- reconnect remains transport-owned
- current-turn replay is enough to rebuild the assistant UI safely
- Flutter only needs the existing `error` state plus `resume()` control surface
- app-owned reconnect hints can stay inside `HttpChatTransport` preparation
  hooks

## Bottom Line

Flutter now has a concrete reconnect recovery example and regression test, and
that result further supports keeping reconnect mechanics out of the shared
event model.
