# 26 Provider-Owned Composed Message Mapper

## Why This Note Exists

The provider UI-extension contract already decided that richer UI mapping should
compose:

- the shared stable `ChatMessageMapper`
- plus provider-owned metadata and custom-part helpers

That boundary is correct, but there is still one small ergonomics gap for app
and Flutter code:

- applications often need both mappings for the same `ChatUiMessage`
- current examples therefore call the shared mapper and the provider mapper
  separately

This is not a reason to add a shared registry. It is only a reason to offer a
small provider-owned composition helper.

## Scope

This slice is additive and limited to provider packages that already expose a
provider-owned message mapper:

- `llm_dart_openai`
- `llm_dart_google`

It does **not** change:

- `ChatUiMessage`
- `ChatUiPart`
- the shared event model
- app-owned renderer policy

The only shared-layer adjustment allowed here is package ownership:

- `ChatMessageMapper` should be available from `llm_dart_core`
- `llm_dart_chat` may keep re-exporting it for compatibility

That keeps dependency direction correct when provider packages want to compose
the shared mapper without depending on the higher-level chat runtime package.

## Decision

Provider-owned mappers may expose a composed mapping helper that returns:

- the shared mapped message
- the provider-specific mapped message

That keeps the boundary exactly where it should stay:

- shared extraction remains shared
- provider-specific extraction remains provider-owned
- the convenience wrapper stays additive and provider-local

## Why This Is Worth Doing

This helper removes real repeated application code without introducing a new
cross-provider abstraction layer.

It is especially useful for Flutter and chat-style UIs because they often need
both:

- baseline render fields like text, reasoning, tools, and warnings
- provider-specific details such as OpenAI item metadata or Google thought
  signatures

## Acceptance Criteria

This slice is complete when:

- OpenAI and Google provider mappers can return one composed mapping result
- the existing plain provider-only mapping path remains available
- the shared `ChatMessageMapper` stays unchanged
- the shared/provider composition example code becomes simpler

## Bottom Line

This is the right kind of UI ergonomics improvement:

- additive
- provider-owned
- Flutter-friendly
- and still fully aligned with the frozen shared-core boundary
