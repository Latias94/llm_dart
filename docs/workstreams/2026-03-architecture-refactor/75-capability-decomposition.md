# Capability Decomposition

## Goal

This note records the root-package decomposition of `capability.dart` without
changing the public legacy capability interfaces and stream event types.

The goal was narrow:

- keep the current compatibility-facing capability surface stable
- reduce concept mixing inside one legacy root file
- make provider and compatibility cleanup easier without widening the old API

## 1. Why `capability.dart` Needed A Split

Before this slice, `capability.dart` mixed several different responsibility
families:

- provider capability enums and declarations
- chat interfaces and legacy stream events
- embedding and completion generation helpers
- audio and realtime APIs
- image generation APIs
- file, moderation, assistant, and tool-execution APIs

Some of those are core compatibility contracts, while others are optional
convenience families or provider-discovery helpers. Keeping them together made
the file harder to audit and easier to over-couple.

## 2. Frozen Decomposition Rule

This refactor keeps the public root capability surface unchanged.

The split is internal only:

- `capability.dart` remains the entry library
- implementation moves into same-library `part` files grouped by concept
- the refactor does not introduce new legacy capability families
- provider-specific shaping still stays outside the shared root capability file

## 3. Landed Split

The main shell now only owns imports, exports, and part declarations.

Implementation moved into:

- `capability_provider_declarations.dart`
- `capability_chat.dart`
- `capability_generation.dart`
- `capability_audio.dart`
- `capability_image.dart`
- `capability_management.dart`

This split makes the old capability surface easier to navigate:

- chat interfaces and stream events stay together
- generation helpers stay separate from chat
- audio and realtime types stop competing with image and admin capabilities
- provider capability declarations stay isolated from request/response APIs

## 4. Important Boundary

This decomposition is not a signal that every legacy capability should remain a
first-class long-term architecture primitive.

The new package-owned model APIs remain the direction for future product work.
The root capability layer is still a compatibility shell, even if it is now a
better-structured one.

## 5. Why Same-Library Parts Were Chosen

Using `part` files keeps the change low risk because it preserves:

- the existing public interface names
- current default-method behavior
- access to shared private library scope where needed
- minimal migration and test churn for compatibility users

That makes same-library decomposition a better fit than introducing another set
of wrapper exports during the compatibility window.

## 6. Validation

This slice was validated with:

- `dart analyze lib/core lib/models test/core/registry_test.dart test/core/tool_streaming_test.dart test/utils/capability_utils_test.dart test/builder/llm_builder_test.dart test/models/chat_models_test.dart test/chat_route_compatibility_test.dart test/legacy_compatibility_test.dart`
- `dart test test/core/registry_test.dart test/core/tool_streaming_test.dart test/utils/capability_utils_test.dart test/builder/llm_builder_test.dart test/models/chat_models_test.dart test/chat_route_compatibility_test.dart test/legacy_compatibility_test.dart`

## 7. Next Step

With `compat_providers.dart`, `LLMBuilder`, `chat_models.dart`, and
`capability.dart` now decomposed, the remaining root-package refactor work is
less about file-size reduction and more about tightening compatibility
semantics, tests, and eventual deprecation boundaries.
