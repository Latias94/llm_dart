# 157 OpenAI Request Body Support

## Why

After the `OpenAIClient` request-shell cleanup, the next residual duplication in
the root OpenAI compatibility layer sat one level above transport:

- `OpenAIChat._buildRequestBody(...)`
- `OpenAIResponses._buildRequestBody(...)`

Those two builders still repeated the same compatibility-owned field encoding:

- config-level system prompt prepending,
- max-token and sampling fields,
- structured-output response-format shaping,
- stop/user/service-tier fields,
- namespaced OpenAI-family provider-option reads,
- shared OpenAI request extras such as penalties, seeds, logprobs, and parallel
  tool-call flags.

The APIs are not identical, so they should not be forced into one monolithic
request builder. But the common field shaping was already duplicated enough to
become a maintenance risk.

## Decision

Extract a focused OpenAI-family compatibility request-body support helper that
owns only the truly shared field encoding.

Keep the API-specific differences local:

- chat-completions still owns its reasoning-effort parameter mapping and
  `include_reasoning` quirks,
- Responses still owns `previous_response_id`, built-in tools, and Responses
  tool conversion,
- both request builders now reuse the same shared helper for common body
  shaping.

This mirrors the reference direction from `repo-ref/ai`: shared provider-family
encoding should be reused, but API-specific request contracts should remain
separate modules.

## What Changed

- Added `lib/src/compatibility/providers/openai/request_body_support.dart`
  containing shared helpers for:
  - compatibility message preparation,
  - common OpenAI-family request field encoding,
  - structured-output response-format shaping,
  - namespaced provider-option reads.
- Switched both `OpenAIChat` and `OpenAIResponses` onto that helper.
- Removed duplicated provider-option and response-format shaping code from both
  capability modules.
- Added regression coverage that asserts both modules still preserve:
  - system prompt injection,
  - structured-output schema shaping with
    `additionalProperties: false`,
  - shared OpenAI-family compatibility options,
  - Responses-only extras such as `previous_response_id` and built-in tools,
  - chat-only `verbosity` support.

## Architectural Effect

This is another root-weight reduction step, but it stays inside the OpenAI
compatibility family instead of widening any cross-provider abstraction.

The resulting boundary is healthier:

- transport mechanics stay below the capability layer,
- shared OpenAI-family request encoding sits in one local helper,
- chat-completions and Responses still keep their different protocol semantics.

That makes the remaining OpenAI compatibility work more explicit: future
cleanup should focus on capability-level boundaries and legacy-surface slimming,
not on inventing broader generic request-builder abstractions for the whole
repository.
