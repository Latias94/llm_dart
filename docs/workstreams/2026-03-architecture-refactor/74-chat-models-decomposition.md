# Chat Models Decomposition

## Goal

This note records the root-package decomposition of `chat_models.dart` without
changing the public legacy message and value-model API.

The goal was intentionally narrow:

- keep `ChatMessage`, `MessageBuilder`, `ToolCall`, `FunctionCall`, and the
  existing legacy enums and value types stable
- reduce the amount of unrelated compatibility logic living in one file
- make future compatibility cleanup easier without starting a new public model
  redesign

## 1. Why `chat_models.dart` Needed A Split

Before this slice, `chat_models.dart` mixed six different concerns:

- base value types such as `ChatRole`, `ImageMime`, `FileMime`, and `AIModel`
- tool-call values
- message payload variants
- the `ChatMessage` compatibility model
- the `MessageBuilder` and `ContentBlock` DSL
- request metadata and reasoning-related enums

Those concerns evolve at different speeds. Keeping them in one file made
compatibility-focused work harder to audit and encouraged unrelated changes to
land together.

## 2. Frozen Decomposition Rule

This refactor keeps the legacy root model names and exports unchanged.

The split is internal only:

- `chat_models.dart` remains the library entry
- implementation moves into same-library `part` files
- no new public wrapper API is introduced
- no provider-specific request shaping is moved into the shared legacy model
  file

## 3. Landed Split

The root shell now only declares the library imports plus the focused
same-library parts:

- `chat_models_primitives.dart`
- `chat_models_tool_call_values.dart`
- `chat_models_message_types.dart`
- `chat_models_message.dart`
- `chat_models_builder.dart`
- `chat_models_request_metadata.dart`

This grouping maps better to ownership:

- primitive enums and MIME helpers stay separate from the builder DSL
- `ChatMessage` stays separate from tool-call values and request metadata
- the compatibility-oriented `MessageBuilder` no longer forces unrelated values
  to live in the same source block

## 4. Important Boundary

This decomposition does not promote `MessageBuilder` into the long-term
canonical prompt API.

`MessageBuilder` remains a compatibility DSL during the migration window.
Modern package-owned prompt and content models still belong in the new package
structure, not in the root compatibility facade.

## 5. Why Same-Library Parts Were Chosen

Using `part` files keeps the change low risk because it preserves:

- existing public type names
- private helper access patterns
- current serialization and equality behavior
- zero required migration for root-package consumers

That is the right tradeoff for the compatibility layer. The point here is to
reduce coupling first, not to invent a second legacy model API.

## 6. Validation

This slice was validated with:

- `dart analyze lib/models test/models/chat_models_test.dart test/chat_route_compatibility_test.dart test/legacy_compatibility_test.dart test/builder/llm_builder_test.dart`
- `dart test test/models/chat_models_test.dart test/chat_route_compatibility_test.dart test/legacy_compatibility_test.dart test/builder/llm_builder_test.dart`

## 7. Next Step

After `chat_models.dart` and `LLMBuilder` were decomposed, the remaining root
compatibility cleanup target was `capability.dart`, which has now also been
split into focused same-library modules.
