# OpenAI Responses Persistence Policy

## Purpose

This note audits the remaining OpenAI Responses gap against `repo-ref/ai` from the perspective of persistence policy rather than prompt-model shape.

The goal is to answer one question precisely:

- should `llm_dart` treat `store`, `conversation`, and `item_reference` as shared architecture, or as OpenAI-owned continuation policy?

## What The Reference Actually Models

The reference Responses adapter does not only encode prompt parts.

It also models a provider-owned persistence policy with these levers:

- `previous_response_id`
  - continue from a previous stored OpenAI response
- `store`
  - choose whether OpenAI should persist the response and whether replay can use stored item references
- `conversation`
  - continue an OpenAI server-side conversation directly
- `item_reference`
  - replay previously stored OpenAI items by ID instead of resending full item payloads

That means the reference behavior is policy-driven:

1. if `store: true` and an OpenAI item ID is available, replay often prefers `item_reference`
2. if `store: false`, replay must often reconstruct full items instead of relying on stored OpenAI state
3. if `conversation` is active, replay must skip items that already exist in the server-side conversation to avoid duplicate-item errors

This is not just a codec detail. It is OpenAI-owned stored-conversation behavior.

## Current `llm_dart_openai` State

The migrated Dart package already preserves the minimum replay-critical metadata that a future persistence policy would need:

- assistant message `itemId`
- assistant message `phase`
- reasoning `itemId`
- reasoning encrypted content
- tool-call `itemId`
- `openai.compaction` item IDs and encrypted content

The migrated package also already exposes one persistence-related invocation option:

- `OpenAIGenerateTextOptions.previousResponseId`

What it does not currently expose is:

- `store`
- `conversation`
- any request-time branch that chooses between full replay and `item_reference`
- any duplicate-skip policy for server-owned stored conversation items

Today the migrated Responses path therefore behaves as:

- preserve OpenAI replay-critical metadata
- re-encode full replay items when it can
- do not expose store-aware replay optimization

## Architectural Conclusion

`store`, `conversation`, and `item_reference` should remain OpenAI-owned policy.

They should not widen:

- the shared prompt model
- the shared runner
- the Flutter session abstraction
- generic `GenerateTextOptions`

They belong, if implemented, under OpenAI-owned invocation options and OpenAI-owned codec policy.

The reason is structural:

- they depend on OpenAI server-side storage semantics
- they depend on whether a prior item already exists in OpenAI's store
- they depend on OpenAI item IDs that have no cross-provider meaning

This is a provider continuation/storage contract, not a shared message contract.

## What Should Happen Next

If this feature is needed, the rollout should happen in this order:

1. keep the current shared core unchanged
2. expose any new persistence levers only on `OpenAIGenerateTextOptions`
3. implement `store` together with the codec branch that decides between full replay and `item_reference`
4. only add `conversation` together with duplicate-skip logic for stored assistant items
5. extend provider-owned OpenAI item families only when a real OpenAI wire contract or app use case requires them

This also implies one implementation hygiene rule:

- provider-option overlay code must not rebuild `OpenAIGenerateTextOptions` field-by-field once persistence fields grow

Otherwise future OpenAI-owned persistence fields would be too easy to silently drop.

## What Should Not Happen

The library should not:

- add shared `itemReference` concepts to `PromptPart`
- add shared “stored conversation” abstractions to the core just for OpenAI
- force chat-completions to mimic Responses persistence semantics
- expose `store` or `conversation` as generic cross-provider options

## Flutter And Session Implication

No Flutter-specific API expansion is required for this policy decision.

The important Flutter/session requirement is already the current one:

- preserve prompt-part provider metadata during persistence and session restore

That keeps future OpenAI-owned persistence policy possible without widening shared UI models.

## Bottom Line

The remaining Responses gap versus `repo-ref/ai` is not a missing shared data structure.

It is an unexposed OpenAI-owned persistence policy.

That policy should only land if we intentionally adopt OpenAI server-side storage semantics as an OpenAI-specific continuation feature.
