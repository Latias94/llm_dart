# 32 Flutter Material Chat Demo

## Why This Note Exists

The controller-level Flutter example proves the transport boundary, but Flutter
application authors still benefit from a concrete widget-level reference.

This slice adds a minimal `MaterialApp` chat screen that uses the same
backend-hint mapping pattern without turning `llm_dart_flutter` into a widget
library.

## Scope

This slice adds:

- `packages/llm_dart_flutter/example/flutter_material_chat_demo.dart`
- `packages/llm_dart_flutter/test/flutter_material_chat_demo_test.dart`

It also updates the relevant README entrypoints and the package test
configuration needed for widget tests.

## Example Shape

The new example keeps the same architectural ownership:

1. a Flutter widget owns UI controls and rendering
2. `ChatController` mirrors `DefaultChatSession`
3. `HttpChatTransport` stays provider-neutral
4. app-owned metadata selects a backend routing profile
5. the backend maps that profile into provider-specific execution options
6. the UI renders normal `ChatUiMessage` output plus backend-plan metadata

The example intentionally stays small:

- no shared widget exports
- no opinionated state-management package
- no provider-specific UI model widening

## Why This Matters

This example validates that the current event and message surface is already
good enough for the first real Flutter chat screen shape we want to support:

- profile selector
- message list
- streaming assistant text
- backend-owned execution-plan hints

That is the stronger signal we needed before considering any new shared Flutter
helpers. Right now, the current controller + message model is sufficient.

## Decision Reinforced

The example reinforces three post-closure rules:

- `llm_dart_flutter` stays a thin adapter layer, not a widget toolkit
- `HttpChatTransport` stays generic and backend-oriented
- provider-specific execution shaping remains backend-owned or direct-model
  owned, not serialized as raw provider options through the transport envelope

## Bottom Line

Flutter now has both a controller-level backend-hint example and a minimal
widget-level Material chat demo, which is enough to document the intended app
integration path without widening the package surface.
