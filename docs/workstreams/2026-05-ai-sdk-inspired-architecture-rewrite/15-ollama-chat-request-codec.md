# Ollama Chat Request Codec

## Decision

Split Ollama chat request encoding into deeper provider-owned modules while
keeping `OllamaChatRequestCodec` as the single request assembly point.

This is not a new public API. The public Ollama model settings, invocation
options, prompt contract, and wire shape remain unchanged.

## Problem

`ollama_chat_request_codec.dart` was correct but too broad. One module owned:

- request body assembly
- shared and typed provider option projection
- reasoning conflict warnings
- response-format compatibility handling
- prompt-message projection
- multimodal image file encoding
- binary URI resolution
- tool-result replay warnings

Those behaviours change for different reasons. Keeping them in one module made
the request codec shallow: understanding or testing one policy required reading
the full request assembly implementation.

## Implemented Shape

- Added `ollama_chat_request_options_policy.dart`.
  - Owns `GenerateTextOptions` plus `OllamaGenerateTextOptions` projection into
    Ollama `options`, `format`, and `think` request fields.
  - Owns shared reasoning, unsupported shared option, and response-format
    compatibility warnings.
- Added `ollama_chat_prompt_projection.dart`.
  - Owns provider-facing `PromptMessage` projection into Ollama chat
    `messages`.
  - Keeps user, assistant, system, and tool replay behaviour local to prompt
    projection.
- Added `ollama_chat_binary_part_encoder.dart`.
  - Owns direct bytes, data URI, and `OllamaBinaryResolver` handling for
    multimodal prompt parts.
- Kept `OllamaChatRequestCodec` as orchestration.
  - It resolves typed provider options, asks the policy/projection modules for
    their parts, and assembles the final request body.

## Benefit

This deepens the Ollama chat module:

- option policy has locality separate from prompt projection
- binary prompt resolution can evolve without reopening request body assembly
- prompt projection tests can pin Ollama replay behaviour directly
- the language model path remains a narrow transport orchestration layer
- typed Ollama options stay provider-owned instead of being flattened into
  shared options

The shape mirrors the mature provider-codec pattern used elsewhere in this
workstream: a small public/request orchestration interface with deeper internal
modules behind it.

## Verification

- `dart test` in `packages/llm_dart_ollama`
- `dart analyze` in `packages/llm_dart_ollama`

Focused tests cover:

- shared and provider option projection into `options`, `format`, and `think`
- provider reasoning overriding shared reasoning with a compatibility warning
- unsupported shared penalties and reasoning effort/budget warnings
- call-level `OllamaBinaryResolver` overriding model settings for image files
- non-image file prompt parts still being rejected on the chat path

## Remaining Risks

Ollama currently has only one modern chat route, so the new policy is a
package-private deep module rather than a model-family profile seam. If Ollama
adds materially different chat routes, this policy can become the place where
route-specific request rules are selected.
