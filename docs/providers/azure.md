# Azure OpenAI Guide

This guide documents how to use Azure OpenAI via `llm_dart_azure`.

Azure OpenAI is integrated through the OpenAI-shaped protocol layers:

- Chat Completions baseline: `llm_dart_openai_compatible`
- Responses API (OpenAI-only semantics): `llm_dart_openai` / `llm_dart_openai_compatible` (tiered)

LLM Dart follows a best-effort approach: we forward requests as-is and do **not**
maintain a provider/model support matrix.

Provider-agnostic usage should prefer `llm_dart_ai` task APIs. Azure-only knobs
live behind:

- `providerOptions['azure']`
- `providerMetadata['azure']`

## Packages

- Provider: `llm_dart_azure`
- Recommended tasks: `llm_dart_ai`
- Builder: `llm_dart_builder`
- Protocol reuse: `llm_dart_openai_compatible` (internal dependency)

## Base URL

Azure base URL should point at the Azure OpenAI `openai` prefix (no `/v1`):

- `https://{resource}.openai.azure.com/openai`

LLM Dart will derive the final API root depending on your settings (see below).

## Authentication

Azure OpenAI uses header auth:

- `api-key: <AZURE_OPENAI_API_KEY>`

(Not `Authorization: Bearer ...`.)

## API version (`api-version`)

Azure requires an `api-version` query parameter.

Configure it via provider options:

- `providerOptions['azure']['apiVersion'] = '2024-10-01-preview'` (example)

Note: the default in this repository is `v1` (AI SDK parity), but you should
set the exact version required by your Azure resource.

## URL mode: v1 vs deployment-based URLs

Configure:

- `providerOptions['azure']['useDeploymentBasedUrls'] = true|false`

When `false` (v1-style URLs):

- Requests go to `{baseUrl}/v1/...`
- The `model` field is included in request bodies (best-effort)

When `true` (deployment-based URLs, common in Azure):

- Requests go to `{baseUrl}/deployments/{deployment}/...`
- The builder `model(...)` value is treated as the deployment name

## Responses API vs Chat Completions

Azure can use either:

- Chat Completions (`/chat/completions`)
- Responses (`/responses`)

Control it via:

- `providerOptions['azure']['useResponsesAPI'] = true|false`

If you configure any OpenAI built-in tools via `providerTools`, LLM Dart will
force `useResponsesAPI=true` (tooling requires Responses).

Note: Azure tool ids use the `azure.` prefix (AI SDK parity), e.g.
`azure.web_search_preview`. The Azure factory also tolerates legacy `openai.*`
ids during the fearless refactor window.

## Quick start (recommended: task APIs)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_azure/llm_dart_azure.dart';

Future<void> main() async {
  registerAzure();

  final model = await LLMBuilder()
      .provider(azureProviderId)
      .apiKey(Platform.environment['AZURE_OPENAI_API_KEY'] ?? 'AZURE_OPENAI_API_KEY')
      .baseUrl('https://example.openai.azure.com/openai')
      .model('deployment_1')
      .providerOptions('azure', const {
        'apiVersion': '2024-10-01-preview',
        'useDeploymentBasedUrls': true,
        'useResponsesAPI': true,
      })
      .build();

  final result = await generateText(
    model: model,
    messages: const [ChatMessage.user('Hello from Azure OpenAI!')],
  );

  print(result.text);
  print(result.providerMetadata);
}
```

## providerMetadata

`ChatResponse.providerMetadata` is an optional provider-id namespaced map.

For Azure, the namespace is:

- `providerMetadata['azure']`

Compatibility aliases may also be emitted during the fearless refactor window
(e.g. `azure.chat`, `azure.responses`), but downstream code should treat
`providerMetadata['azure']` as canonical.

The payload includes best-effort fields such as:

- `id`, `model`, `systemFingerprint`, `finishReason`
- `usage` (when available)

## Streaming (LLMStreamPart)

Azure streaming is SSE. Prefer consuming stream output via `LLMStreamPart`:

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

Future<void> printStream(Stream<LLMStreamPart> parts) async {
  await for (final part in parts) {
    switch (part) {
      case LLMStreamStartPart(:final warnings):
        if (warnings.isNotEmpty) stderr.writeln('warnings: $warnings');
      case LLMResponseMetadataPart(:final id, :final model):
        stderr.writeln('meta: id=$id model=$model');
      case LLMTextDeltaPart(:final delta):
        stdout.write(delta);
      case LLMProviderToolCallPart(:final toolName, :final toolCallId):
        stderr.writeln('\nprovider tool call: $toolName ($toolCallId)');
      case LLMProviderToolResultPart(:final toolName, :final toolCallId):
        stderr.writeln('\nprovider tool result: $toolName ($toolCallId)');
      case LLMFinishPart(:final finishReason, :final usage):
        stderr.writeln('\nfinish: $finishReason usage=$usage');
      case LLMErrorPart(:final error):
        stderr.writeln('error: $error');
      default:
        break;
    }
  }
}
```

Note: some Azure gateways may send `usage` in a trailing chunk after a finish
signal; LLM Dart captures it best-effort (see conformance tests).

## Conformance tests

- `test/providers/azure/azure_openai_request_mapping_test.dart`
- `test/providers/azure/azure_openai_responses_vercel_fixtures_test.dart`
- `test/protocols/openai_compatible/openai_compatible_streaming_usage_tail_conformance_test.dart`
