# OpenAI Request Encoding Boundary

## Summary

This slice split the remaining OpenAI request-encoding hotspots out of the two
large provider-local facades:

```text
packages/llm_dart_openai/lib/src/openai_responses_request_codec.dart
packages/llm_dart_openai/lib/src/openai_chat_completions_codec.dart
```

The new provider-local request modules are:

```text
packages/llm_dart_openai/lib/src/openai_request_encoding_util.dart
packages/llm_dart_openai/lib/src/openai_request_format_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_request_prompt_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_request_tool_codec.dart
packages/llm_dart_openai/lib/src/openai_responses_request_options_codec.dart
packages/llm_dart_openai/lib/src/openai_chat_completions_request_prompt_codec.dart
packages/llm_dart_openai/lib/src/openai_chat_completions_request_tool_codec.dart
packages/llm_dart_openai/lib/src/openai_chat_completions_request_options_codec.dart
```

The reference lesson from `repo-ref/ai` remains the same: request conversion,
tool preparation, response parsing, and stream parsing should be separately
auditable provider-owned modules. The Dart split keeps OpenAI Responses and
OpenAI-family Chat Completions separate because their request wire contracts
are still different.

Reference files:

```text
repo-ref/ai/packages/openai/src/chat/convert-to-openai-chat-messages.ts
repo-ref/ai/packages/openai/src/chat/openai-chat-language-model.ts
repo-ref/ai/packages/openai/src/responses/openai-responses-language-model.ts
```

## Moved Responsibilities

`openai_request_format_codec.dart` owns:

- OpenAI JSON schema response-format encoding
- default `additionalProperties: false` normalization

`openai_request_encoding_util.dart` owns OpenAI-family request helper seams that
are still private to `llm_dart_openai`:

- JSON argument serialization
- image media-type normalization for data URLs
- OpenAI prompt-part image-detail option resolution
- provider-reference file id resolution
- provider replay metadata lookup
- request map/string projection helpers
- body-field removal with warnings

`openai_responses_request_prompt_codec.dart` owns:

- system/developer/remove mode prompt projection
- user text/image/file/PDF input projection
- assistant replay for text, reasoning, tool calls, tool results, item
  references, and compaction custom parts
- tool message replay for function outputs and MCP approval responses
- Responses-specific store/conversation replay rules

`openai_responses_request_tool_codec.dart` owns:

- Responses function tool declarations
- OpenAI built-in tool passthrough
- Responses tool-choice shape
- Responses content tool-output projection, including text, JSON, files,
  images, URIs, bytes, text files, and OpenAI file references

`openai_responses_request_options_codec.dart` owns:

- unsupported shared option warnings for Responses
- include resolution for logprobs and encrypted reasoning
- top logprobs request encoding
- Responses reasoning compatibility warnings/removals
- Responses service-tier compatibility warnings/removals

`openai_chat_completions_request_prompt_codec.dart` owns:

- system/developer/remove mode prompt projection
- text-only and multimodal user message projection
- image, audio, and PDF file request encoding
- assistant replay for text and common function tool calls
- warning-drops for unsupported assistant/tool replay parts
- OpenAI-compatible provider-reference file id resolution

`openai_chat_completions_request_tool_codec.dart` owns:

- chat-completions function tool declarations
- chat-completions tool-choice shape
- chat-completions tool-result stringification

`openai_chat_completions_request_options_codec.dart` owns:

- chat-completions unsupported provider-option validation
- system message mode resolution
- OpenAI reasoning-model compatibility
- DeepSeek reasoner compatibility
- OpenAI service-tier compatibility
- chat-completions top-logprobs encoding

## Retained Responsibilities

`openai_responses_request_codec.dart` now owns:

- `OpenAIResponsesRequest` data holder
- `OpenAIResponsesRequestCodec` request assembly
- model/capability lookup
- Responses body field assembly
- delegation to prompt, tool, options, and response-format request codecs

`openai_chat_completions_codec.dart` now owns:

- `OpenAIChatCompletionsRequest` data holder
- stable `OpenAIChatCompletionsCodec` facade
- OpenAI-family chat-completions body field assembly
- result decoding delegation
- stream decoding delegation
- re-export of `OpenAIChatCompletionsStreamState`

`OpenAILanguageModel`, `OpenAIResponsesCodec`, and
`OpenAIChatCompletionsCodec` keep their existing import and call surface.

## Provider Utils Decision Signal

This slice still does not justify a public `llm_dart_provider_utils` package.

The only new shared helpers are package-private OpenAI-family request helpers
inside `llm_dart_openai`. They are shared by Responses and Chat Completions, but
they are not stable provider-neutral contracts:

- JSON serialization is only deciding OpenAI argument string shape.
- image detail resolution is tied to `OpenAIPromptPartOptions`.
- file id resolution maps provider references into OpenAI-family request
  fields.
- body-field removal includes OpenAI-specific warning fields/messages.
- JSON schema response-format encoding targets OpenAI's `response_format`
  shape.

Those helpers are useful inside the OpenAI package, but they are not evidence
for a workspace-level public utility package.

## Validation

Focused validation completed for this slice:

```powershell
dart format packages\llm_dart_openai\lib\src\openai_responses_request_codec.dart packages\llm_dart_openai\lib\src\openai_responses_request_prompt_codec.dart packages\llm_dart_openai\lib\src\openai_responses_request_tool_codec.dart packages\llm_dart_openai\lib\src\openai_responses_request_options_codec.dart packages\llm_dart_openai\lib\src\openai_request_encoding_util.dart packages\llm_dart_openai\lib\src\openai_request_format_codec.dart
dart format packages\llm_dart_openai\lib\src\openai_chat_completions_codec.dart packages\llm_dart_openai\lib\src\openai_chat_completions_request_options_codec.dart packages\llm_dart_openai\lib\src\openai_chat_completions_request_prompt_codec.dart packages\llm_dart_openai\lib\src\openai_chat_completions_request_tool_codec.dart
dart analyze packages\llm_dart_openai
dart test packages\llm_dart_openai\test\openai_responses_codec_test.dart packages\llm_dart_openai\test\openai_chat_completions_mainline_test.dart packages\llm_dart_openai\test\openai_chat_completions_stream_codec_test.dart packages\llm_dart_openai\test\openai_responses_stream_codec_test.dart packages\llm_dart_openai\test\openai_language_model_test.dart
dart run tool\check_workspace_dependency_guards.dart
```

All commands passed on 2026-05-15T12:52:37+08:00.
