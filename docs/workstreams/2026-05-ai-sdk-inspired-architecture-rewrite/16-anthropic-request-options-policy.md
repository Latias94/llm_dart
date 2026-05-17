# Anthropic Request Options Policy

## Decision

Split Anthropic Messages request option encoding into deeper internal modules
while keeping `AnthropicRequestOptionsEncoder` as the request assembly entry.

This is a package-internal refactor. Public Anthropic model settings,
invocation options, request codec entrypoints, beta-header behaviour, token
count behaviour, and wire output remain unchanged.

## Problem

`anthropic_request_options_encoder.dart` had already moved request option logic
out of the language model path, but it still owned several behaviours with
different reasons to change:

- shared reasoning to Anthropic extended-thinking policy
- provider thinking budget precedence and warnings
- sampling compatibility when thinking is enabled
- temperature clamping
- interleaved-thinking beta inference
- body-scanning beta inference for cache control and file sources
- MCP beta inference
- token-count request projection and token-count-only warnings
- final Messages request body assembly

That made the module shallower than the surrounding Anthropic codec structure:
the request assembly interface carried nearly the same conceptual load as the
implementation.

## Implemented Shape

- Added `anthropic_thinking_policy.dart`.
  - Owns shared/provider thinking projection.
  - Owns sampling compatibility and temperature clamping.
  - Returns a small `AnthropicThinkingSamplingProjection` consumed by request
    assembly.
- Added `anthropic_beta_feature_inference.dart`.
  - Owns interleaved-thinking, MCP, cache-control, and file-source beta feature
    inference.
  - Keeps beta feature sorting in one module.
- Added `anthropic_token_count_request_projection.dart`.
  - Owns projection from a full Messages request body to the
    `/messages/count_tokens` subset.
  - Owns token-count-only compatibility warnings for `serviceTier`,
    `metadata`, and `container`.
- Kept `AnthropicRequestOptionsEncoder`.
  - It now orchestrates prompt/request option projection, tool configuration,
    beta inference, and final body assembly.

## Benefit

This deepens the Anthropic messages module:

- extended-thinking policy has locality separate from body assembly
- beta-header inference can evolve without reopening sampling or token-count
  projection
- token-count support has its own testable seam
- `AnthropicMessagesCodec` remains stable and keeps its current public-focused
  fixture tests
- typed Anthropic options stay provider-owned instead of leaking into shared
  runtime options

## Verification

- `dart test` in `packages/llm_dart_anthropic`
- `dart analyze` in `packages/llm_dart_anthropic`

Existing golden tests still cover Messages request body and request metadata.
New focused tests cover:

- shared reasoning and provider thinking projection
- temperature clamping and sampling suppression when thinking is enabled
- interleaved-thinking beta warning behaviour
- beta feature inference and sorting
- token-count request projection and ignored-field warnings

## Remaining Risks

The request body assembly still chooses where provider options such as
`serviceTier`, `metadata`, `container`, and MCP servers appear in the final
body. That is acceptable for now because those fields are direct request
assembly, not a separate cross-route policy. If Anthropic adds more request
routes with different supported field subsets, the token-count projector shape
can be reused for those route projections.
