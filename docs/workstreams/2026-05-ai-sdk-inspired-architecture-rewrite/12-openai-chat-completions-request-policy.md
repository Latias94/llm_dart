# OpenAI Chat Completions Request Policy

## Decision

Move OpenAI-family Chat Completions provider-specific request-field policy out
of `openai_chat_completions_codec.dart` and into a dedicated request policy
seam.

The Chat Completions codec remains the shared wire-code module for request
assembly and response decoding. Provider-specific request decisions now live in
`openAIChatCompletionsRequestPolicyFor(providerNamespace)`.

## Problem

The shared Chat Completions codec still knew which request fields belonged only
to OpenAI or DeepSeek. That kept several `providerNamespace` checks directly in
the body assembly path:

- OpenAI-only `reasoning_effort`
- OpenAI-only `max_completion_tokens`
- DeepSeek-specific `logprobs`, `top_logprobs`, `frequency_penalty`,
  `presence_penalty`, and `response_format`
- OpenAI reasoning-model compatibility cleanup
- DeepSeek reasoner compatibility cleanup

Those rules were correct, but they made the codec shallower than it should be:
adding another OpenAI-compatible provider would require editing shared wire-code
instead of extending a provider policy.

## Implemented Shape

- Added `openai_chat_completions_request_policy.dart`.
- `OpenAIChatCompletionsRequestPolicy` owns provider-specific request fields,
  response-format fallback, and compatibility cleanup.
- The default compatible policy emits shared Chat Completions logprob fields.
- The OpenAI policy owns OpenAI reasoning fields and OpenAI model compatibility
  warnings.
- The DeepSeek policy owns DeepSeek typed option fields and DeepSeek reasoner
  cleanup.
- `openai_chat_completions_codec.dart` now delegates provider-specific request
  behaviour to the policy and keeps shared body assembly.
- `openai_chat_completions_request_options_codec.dart` now focuses on option
  validation and system-message-mode resolution.

## Benefit

This deepens the OpenAI-family Chat Completions module:

- shared wire-code keeps locality for common request assembly
- provider request policy keeps locality for OpenAI/DeepSeek differences
- tests keep asserting the same wire bodies and warnings
- future compatible providers can add request-field policy without reopening
  the codec body assembly path

## Verification

- `dart test test/openai_chat_completions_mainline_test.dart` in
  `packages/llm_dart_openai`
- `dart test` in `packages/llm_dart_openai`
- `dart analyze` in `packages/llm_dart_openai`

The mainline tests cover OpenAI reasoning fields, OpenAI reasoning-model
cleanup, service-tier warnings, DeepSeek typed option encoding, DeepSeek
reasoner cleanup, xAI live-search request fields, and chat-completions fixture
compatibility.

## Remaining Risks

The policy is still keyed by provider namespace because the Chat Completions
codec currently receives a namespace rather than the full family profile. This
is acceptable for this slice because it moves policy out of shared wire-code.
If the codec later receives `OpenAIFamilyProfile`, the policy lookup should move
from namespace to profile matching.
