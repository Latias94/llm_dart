# 27 Public Entrypoint Mapper Guidance Alignment

## Why This Note Exists

The previous slices already changed two important facts:

- the shared `ChatMessageMapper` now belongs to `llm_dart_core`
- OpenAI and Google provider packages now expose `mapComposed(...)` helpers

That improved architecture and UI ergonomics, but public guidance still needed
to catch up.

Without a follow-up documentation pass, users could still get mixed signals:

- some docs implied that `llm_dart_chat` still owned message mapping
- some examples still encouraged manually calling the shared mapper and the
  provider mapper separately even when a composed helper now exists

## Scope

This slice is documentation and public-guidance alignment only.

It covers:

- the root `README.md`
- `packages/llm_dart_chat/README.md`
- `packages/llm_dart_flutter/README.md`

It does **not** change runtime behavior or widen any public API.

## Decision

The public story should now be:

1. `ChatMessageMapper` is part of the shared UI model layer in
   `llm_dart_core`
2. `llm_dart_chat` may re-export it for chat-runtime convenience, but does not
   conceptually own it anymore
3. Flutter and other UI code should use provider-owned `mapComposed(...)`
   helpers when both shared and provider-specific projections are needed
4. manual two-step composition remains valid, but should no longer be the
   default guidance

## Why This Matters

This alignment removes a subtle but important source of architecture drift.

If docs keep describing the old ownership model, future contributors will
naturally re-introduce the same dependency confusion that the refactor just
resolved.

Clear public guidance is therefore part of preserving the architecture:

- ownership stays visible
- example code stops teaching outdated composition patterns
- Flutter integration becomes easier to copy correctly

## Acceptance Criteria

This slice is complete when:

- the root README says that `ChatMessageMapper` belongs to `llm_dart_core`
- `llm_dart_chat` README no longer presents message mapping as runtime-owned
  logic
- `llm_dart_flutter` README recommends `mapComposed(...)` for provider-aware UI
  rendering
- the examples no longer suggest outdated default guidance

## Bottom Line

This is a public-guidance cleanup, not a new architecture decision.

It locks the already-finished mapper refactor into the user-facing docs so the
new layering remains obvious and repeatable.
