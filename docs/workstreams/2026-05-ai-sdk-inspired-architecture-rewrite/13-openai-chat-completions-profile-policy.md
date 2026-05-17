# OpenAI Chat Completions Profile Policy

## Decision

Resolve OpenAI-family Chat Completions request policy from
`OpenAIFamilyProfile` on the language-model path.

`OpenAIChatCompletionsCodec` now has a profile-first constructor:
`OpenAIChatCompletionsCodec.forProfile(profile)`. The existing
`providerNamespace` constructor remains available for focused codec tests and
compatibility helpers, but production language-model traffic passes the full
profile.

## Problem

The previous request-policy seam moved provider-specific request fields out of
the shared codec, but the policy lookup was still keyed by a provider id string.
That left one shallow spot: a profile such as `OpenAIProfile(providerId:
'custom-openai')` could describe OpenAI-family behaviour at the type level
while the Chat Completions policy resolver saw only an unknown string.

The result was too much hidden meaning in `providerId`. The profile should own
family behaviour; the id should scope metadata, registry names, and headers.

## Implemented Shape

- Added `openAIChatCompletionsRequestPolicyForProfile(profile)`.
- `OpenAIChatCompletionsCodec.forProfile(profile)` stores the profile and uses
  profile-based request-policy lookup.
- `OpenAILanguageModel` now constructs the Chat Completions codec with the full
  `OpenAIFamilyProfile`.
- The existing `OpenAIChatCompletionsCodec(providerNamespace: ...)` constructor
  remains as a compatibility path.
- Added coverage proving a custom OpenAI profile id still emits OpenAI
  Chat Completions request fields such as `reasoning_effort`.

## Benefit

This deepens the OpenAI-family module:

- provider-family behaviour has locality at the profile seam
- `providerId` can remain an identifier rather than a policy switch
- shared Chat Completions wire-code stays reusable
- codec tests can still construct namespace-scoped codecs directly
- future profile-specific policy additions can follow the profile type instead
  of reopening string conditionals in the language-model path

## Verification

- `dart test test/openai_chat_completions_mainline_test.dart` in
  `packages/llm_dart_openai`
- `dart analyze` in `packages/llm_dart_openai`

The new regression test uses `OpenAIProfile(providerId: 'custom-openai')` with
Chat Completions and asserts that OpenAI request-policy fields are still
encoded.

## Remaining Risks

The codec still exposes a namespace-only constructor because stream/fixture
tests and low-level compatibility helpers instantiate the wire codec directly.
That is acceptable while the public provider path is profile-owned. If a future
breaking line makes the codec fully private, the namespace-only constructor can
be deleted with the tests moved to profile fixtures.
