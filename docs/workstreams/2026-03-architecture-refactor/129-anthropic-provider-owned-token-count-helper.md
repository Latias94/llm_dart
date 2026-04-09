# 129. Anthropic Provider-Owned Token Count Helper

## Decision

Anthropic exact token counting should gain a provider-owned modern helper in
`llm_dart_anthropic`.

It should **not** be migrated by widening the shared `LanguageModel` contract
in the current round.

## Why

The earlier Anthropic residual-API classification showed that exact token
counting was the clearest remaining Anthropic gap where:

- the root compatibility layer still exposed real user-facing value
- `llm_dart_anthropic` still lacked an equivalent modern path
- Flutter or other chat applications can use the endpoint directly for prompt
  budgeting, preflight validation, and UX guardrails

At the same time, the shared text-generation contract is still intentionally
narrow:

- generate text
- stream text
- shared result and event models

It does not define provider-neutral token-counting behavior across providers.

So widening shared core first would have been the wrong sequencing.

## What Landed

The modern Anthropic package now exposes a provider-owned token-counting helper
on the concrete `AnthropicLanguageModel` type:

- `countTokens(AnthropicTokenCountRequest request)`

New typed provider-owned request and result shapes:

- `AnthropicTokenCountRequest`
- `AnthropicTokenCountResult`

These types live entirely inside `llm_dart_anthropic` and are exported from the
package root.

## Boundary

### Shared core stays unchanged

No shared-core model changes were required:

- `LanguageModel` stays generate/stream oriented
- no shared `countTokens(...)` contract was added
- no provider-neutral token-count request model was introduced

### The helper is provider-owned

Token counting remains intentionally Anthropic-shaped:

- it lives on the concrete `AnthropicLanguageModel`
- it accepts a provider-owned typed request model
- it reuses the modern Anthropic prompt/tool/thinking encoding path
- it still accepts normal `CallOptions` for headers, timeout, cancellation, and
  provider options

This matches the broader architecture rule already used elsewhere in the
repository:

- keep shared core honest and narrow
- add provider-owned helpers only for concrete provider-native workflows

## Request Semantics

The helper reuses the same Anthropic prompt and tool encoding boundary used by
`generate(...)`, so it stays aligned with:

- system, user, assistant, and tool replay handling
- native-tool declarations
- deferred tool loading
- prompt and tool cache-control markers
- extended thinking and interleaved-thinking request shaping
- MCP connector request configuration

The token-count endpoint request is still narrower than a normal messages call.

The helper intentionally omits fields that do not belong to the token-count
wire contract:

- `max_tokens`
- `stream`
- sampling controls such as `temperature`, `top_p`, and `top_k`
- `stop_sequences`

The current helper also warning-drops fields that are still present on
`AnthropicGenerateTextOptions` but are not sent for token counting:

- `serviceTier`
- `metadata`
- `container`

That keeps the request honest without forcing a second provider-options type in
the same round.

## Result Surface

The helper returns:

- the exact `input_tokens` count from Anthropic
- any request-shaping warnings produced by the provider-owned encoder

Returning warnings is important because the helper shares prompt/tool/thinking
encoding with the main language-model path and therefore should not silently
drop compatibility adjustments.

## Why This Is Better Than Keeping It Only In The Root Provider

Leaving exact token counting only on the legacy root provider would have
preserved several problems:

- preflight token budgeting would remain trapped behind the old compatibility
  surface
- new code would need to fall back to `ChatMessage`-era abstractions for a
  concrete Anthropic feature
- the root compatibility layer would keep carrying real app-facing value that
  already fits the modern provider package

The provider-owned helper path avoids that.

## Roadmap Consequence

This closes the clearest remaining Anthropic provider-owned gap identified in
the residual classification:

- exact token counting: now has a provider-owned modern path
- model listing: still compatibility-only or a future optional convenience
- broader file CRUD: still compatibility-only or a future optional convenience

The next Anthropic-specific decision should therefore focus on whether model
catalog or broader storage helpers deserve provider-owned utilities at all, not
on reopening the shared text boundary.
