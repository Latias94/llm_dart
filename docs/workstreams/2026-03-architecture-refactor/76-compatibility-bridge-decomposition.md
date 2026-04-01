# Compatibility Bridge Decomposition

## Goal

This note records the next compatibility-layer cleanup step after the root
facade decomposition:

- split `chat_route_compatibility.dart` by provider-family responsibility
- split `legacy_chat_adapter.dart` by request, response, and streaming helpers
- keep all existing bridge-gating and fallback decisions unchanged

The point is structural clarity, not a behavior change.

## 1. Why These Files Became The Next Hotspot

After `compat_providers.dart`, `LLMBuilder`, `chat_models.dart`, and
`capability.dart` were decomposed, the main remaining compatibility buses moved
under `lib/src/compatibility/`.

The most obvious hotspots were:

- `chat_route_compatibility.dart`, which mixed OpenAI-family, Google,
  Anthropic, and xAI bridge rules plus generic helper predicates
- `legacy_chat_adapter.dart`, which mixed request conversion, response mapping,
  stream projection, and Google-specific stream behavior in one file

These files are compatibility-owned, but they still benefit from the same
separation discipline that the reference keeps between shared model surfaces and
provider routing logic.

## 2. Frozen Decomposition Rule

This slice keeps the compatibility bridge semantics stable:

- no widening of the legacy public API
- no change to provider fallback conditions
- no change to audited bridge-safe subsets
- no movement of provider-specific request shaping back into shared root files

The refactor only changes internal file ownership and helper placement.

## 3. Landed Split

### 3.1 `chat_route_compatibility.dart`

The route-gating file is now reduced to a shell plus same-library parts:

- `chat_route_compatibility_openai_family.dart`
- `chat_route_compatibility_google_anthropic.dart`
- `chat_route_compatibility_support.dart`

This keeps provider-family bridge rules closer to provider-family concerns while
keeping shared helper predicates explicit and small.

### 3.2 `legacy_chat_adapter.dart`

The legacy adapter is now reduced to the adapter shell plus focused helper
parts:

- `legacy_chat_adapter_request.dart`
- `legacy_chat_adapter_response.dart`
- `legacy_chat_adapter_streaming.dart`

That separates:

- request and prompt conversion
- result and error adaptation
- stream event projection and stream state

## 4. Important Compatibility Constraint

The most important preserved behavior is dynamic dispatch for subclass-owned
conversion.

In particular, `AnthropicLegacyChatCapabilityAdapter` still relies on the base
adapter calling `convertMessages(...)` virtually from `buildRequest(...)`, so
its provider-specific replay mapping keeps working without duplication.

That constraint is exactly why this slice uses helper extraction rather than a
more aggressive inheritance rewrite.

## 5. Validation

This slice was validated with:

- `dart analyze lib/src/compatibility test/chat_route_compatibility_test.dart test/legacy_compatibility_test.dart test/builder/llm_builder_test.dart`
- `dart test test/chat_route_compatibility_test.dart test/legacy_compatibility_test.dart test/builder/llm_builder_test.dart`

## 6. Next Step

After this decomposition, the biggest remaining compatibility hotspot is no
longer the generic bridge shell. It is now mostly provider-specific legacy
parsing, especially `anthropic_legacy_extensions.dart`, plus any future
provider-family coverage expansions that still need to stay bridge-safe.
