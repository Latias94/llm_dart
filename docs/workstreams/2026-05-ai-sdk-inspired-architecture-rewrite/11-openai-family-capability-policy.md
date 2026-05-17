# OpenAI-Family Capability Policy

## Decision

Move OpenAI-family model-capability description details into a profile-owned
policy seam.

`openai_model_describer.dart` still builds the public `ModelCapabilityProfile`
shape, but it now delegates family-specific capability confidence and provider
feature descriptions to `openAIFamilyCapabilityPolicyFor(profile)`.

## Problem

The earlier describer refactor removed the obvious `providerId` capability
reporting bug, but the remaining helper still concentrated profile-specific
behaviour in one function body. That made the module flatter than it should be:
the public describer looked like the source of truth for OpenAI-family
capabilities even though the differences actually belong to family policy.

## Implemented Shape

- `OpenAIFamilyCapabilityPolicy` owns family-specific capability description
  rules.
- `OpenAIProfile` maps to a known-confidence policy.
- Compatible OpenAI-family profiles map to an inferred-confidence policy.
- DeepSeek adds `deepseek.thinkTagReasoning` and inferred reasoning output for
  reasoner models.
- OpenRouter adds `openrouter.onlineModelRouting` from resolved profile options.
- xAI adds `xai.liveSearch` and `languageSourceOutput`.
- The describer keeps the shared capability assembly, but no longer embeds
  those family-specific policy decisions directly.

## Benefit

This gives the OpenAI package a deeper seam:

- the describer stays a stable public entrypoint
- profile-specific capability policy now has one owner
- tests can pin confidence and provider-feature behaviour at the policy seam
- future compatible providers can extend policy without reopening the public
  describer shape

## Verification

- `dart test test/openai_model_describer_test.dart` in `packages/llm_dart_openai`
- `dart analyze` in `packages/llm_dart_openai`

## Remaining Risks

The policy file is still OpenAI-family specific rather than a fully generic
capability-policy framework. That is deliberate: the current objective is to
deepen the existing module, not invent a new cross-provider abstraction before
the shape proves itself elsewhere.
