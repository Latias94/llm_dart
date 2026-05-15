# Google GenerateContent Codec Boundary

## Summary

The Google follow-up slice extracted GenerateContent prompt/content projection
and tool configuration into provider-local modules:

```text
packages/llm_dart_google/lib/src/google_content_projection.dart
packages/llm_dart_google/lib/src/google_tool_configuration.dart
```

`GoogleGenerateContentCodec` remains the package-private request facade used by
`GoogleLanguageModel`, but it now delegates prompt conversion, media/file
projection, custom replay projection, native tool encoding, function tool
encoding, and `toolConfig` assembly to focused helpers.

This mirrors the useful boundary shape from `repo-ref/ai` without copying its
package graph:

```text
repo-ref/ai/packages/google/src/convert-to-google-messages.ts
repo-ref/ai/packages/google/src/google-prepare-tools.ts
```

## Moved Responsibilities

`google_content_projection.dart` owns:

- system instruction and conversation content projection
- Gemma system prompt folding into the first user content
- user text, image, file, URI, and provider-reference file projection
- assistant text, reasoning, reasoning-file, file, and function-call replay
- tool-result and custom Google function-response replay
- Google server-side tool-call and tool-response replay continuation detection
- Google/Vertex provider metadata fallback for thought signatures, file
  references, and Gemini 3 function-call id replay

`google_tool_configuration.dart` owns:

- common `FunctionToolDefinition` to Google `functionDeclarations` projection
- Google native tool encoding and model support warnings
- common/native mixed-tool policy for Gemini 3
- `ToolChoice` to Google `functionCallingConfig` mapping
- `includeServerSideToolInvocations` validation and `toolConfig` assembly
- warnings for native-tool and `toolChoice` combinations that Google cannot
  honor

## Retained Responsibilities

`google_generate_content_codec.dart` still owns:

- the stable `GoogleGenerateContentCodec` request facade
- top-level GenerateContent request body assembly
- generation config option projection
- response format schema normalization
- safety settings and cached content projection
- candidate count compatibility warnings
- Google thinking config mapping for Gemini 3 and earlier Gemini models

The split keeps provider-specific behavior in the Google package. It does not
turn Gemini, Vertex, native tools, or replay custom parts into provider-neutral
runtime abstractions.

## Validation

Focused validation completed for this slice:

```powershell
dart format packages/llm_dart_google/lib/src/google_generate_content_codec.dart packages/llm_dart_google/lib/src/google_content_projection.dart packages/llm_dart_google/lib/src/google_tool_configuration.dart
dart analyze packages/llm_dart_google
dart test test/google_generate_content_codec_test.dart test/google_language_model_test.dart test/google_function_response_replay_test.dart test/google_server_tool_replay_test.dart test/google_result_codec_test.dart test/google_stream_codec_test.dart
dart run tool/check_workspace_dependency_guards.dart
```

All commands passed.

## Provider Utils Decision Signal

This third provider slice still does not justify a public
`llm_dart_provider_utils` package.

The new Google helpers resemble Vercel AI SDK's Google-local message conversion
and tool preparation boundaries, but their Dart contracts remain provider
specific:

- Google content projection must preserve Gemini and Vertex metadata fallback.
- Google file projection maps Dart `ProviderReference` into Google `fileData`
  rules, not a generic file abstraction.
- Google tool configuration must preserve native Google tools and Gemini 3
  `includeServerSideToolInvocations` behavior.
- Google server-tool replay and function-call id replay are continuation
  semantics, not shared runtime semantics.

Keep these helpers provider-local until two provider packages need the same
independently testable behavior with the same validation rules and names.
