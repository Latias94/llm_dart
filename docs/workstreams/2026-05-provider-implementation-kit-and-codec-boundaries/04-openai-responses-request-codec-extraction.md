# OpenAI Responses Request Codec Extraction

## Summary

The first production slice extracted OpenAI Responses request encoding into:

```text
packages/llm_dart_openai/lib/src/openai_responses_request_codec.dart
```

`OpenAIResponsesCodec` remains the package-private facade used by
`OpenAILanguageModel`, but it now delegates request body construction to
`OpenAIResponsesRequestCodec`.

## Moved Responsibilities

The new request codec owns:

- top-level Responses request body assembly
- prompt message and prompt part encoding
- assistant replay and item-reference encoding
- OpenAI reasoning and service-tier request compatibility policy
- include/logprobs request option projection
- built-in tool, tool choice, response format, and tool-output request encoding
- file/image data URL and provider-reference request helpers

`OpenAIResponsesRequest` moved with the request codec so the facade can depend
on the request boundary without creating an import cycle.

## Retained Responsibilities

`openai_responses_codec.dart` still owns:

- the stable `OpenAIResponsesCodec` facade
- `OpenAIResponsesStreamState`
- non-stream response decoding
- Responses stream chunk dispatch and event mapping
- stream metadata adapter wiring

Result and stream decoding were intentionally left untouched in this slice. The
stream parser has more stateful behavior and should be split only after a
dedicated stream-boundary audit.

## Validation

Focused validation completed for this slice:

```powershell
dart analyze packages/llm_dart_openai
dart test packages/llm_dart_openai/test/openai_responses_codec_test.dart
dart test packages/llm_dart_openai/test/openai_responses_stream_codec_test.dart
dart test packages/llm_dart_openai/test/openai_language_model_test.dart
dart run tool/check_workspace_dependency_guards.dart
```

All commands passed.

## Next Slice

The next architecture slice should be a non-OpenAI contrast provider. Preferred
order:

1. Anthropic message/content/tool replay boundary.
2. Google content/tool/file projection boundary.
3. Ollama chat request/stream parser boundary.

Do not extract public provider utilities yet. Keep one-provider helpers local
until at least two provider slices show stable duplication.
