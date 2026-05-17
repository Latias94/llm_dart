# Google Language Model Policy

## Decision

Move Google language model-family request and capability policy into
`GoogleLanguageModelPolicy`.

This is deliberately not an OpenAI-style provider-profile seam. Google language
models are one provider surface with meaningful model-family differences:
Gemini, Gemini 3 style models, Gemma, and inferred-compatible model ids.

## Problem

Google language request policy was correct but spread across several modules:

- Gemma system prompts were handled in content projection and request assembly.
- Gemini 3 thinking levels lived in generation config encoding.
- Gemini 3 mixed native/common tool policy lived in tool configuration.
- Gemini 3 function-call-id replay lived in prompt message encoding.
- Gemini capability confidence and server-side tool invocation features lived
  in the public model describer.

Each module had to know a slice of the same model-family vocabulary. That made
the modules shallower than necessary: the shared request codecs carried model
family predicates instead of delegating to a policy seam.

## Implemented Shape

- Added `google_language_model_policy.dart`.
- `GoogleLanguageModelPolicy` owns language model-family predicates for
  Gemini, Gemini 3 style models, Gemma, native-tool support, and
  function-call-id replay.
- `GoogleGenerationConfigEncoder` delegates thinking config policy to the
  policy seam.
- `GoogleContentProjectionCodec` and `GoogleGenerateContentCodec` delegate
  Gemma system-instruction placement to the policy seam.
- `GoogleToolConfigurationCodec` delegates native-tool support, mixed-tool
  support, and server-side tool invocation support to the policy seam.
- `GooglePromptMessageEncoder` delegates function-call-id replay support to
  the policy seam.
- `describeGoogleChatModel` reads language capability confidence and
  server-side tool support from the policy seam.

## Benefit

This deepens the Google language module:

- model-family behaviour has locality in one provider-owned policy
- shared GenerateContent codecs keep wire-code locality without owning model
  family rules
- tests can pin policy effects through existing public request/describer
  surfaces
- future Google language model families can be added by extending one seam
  instead of reopening request assembly, prompt projection, tool config, and
  capability description separately

## Verification

- `dart test` in `packages/llm_dart_google`
- `dart analyze` in `packages/llm_dart_google`

Focused tests cover Gemini 3 thinking levels, Gemma system prompt placement,
Gemini 3 mixed native/common tools, function-call-id replay through existing
codec fixtures, and non-Gemini language capability behaviour.

## Remaining Risks

Google image model-family policy still has separate Gemini/Imagen predicates
because image generation has a different route and request shape. That should
be considered as a separate image-model policy seam if image behaviour starts
spreading across more modules.
