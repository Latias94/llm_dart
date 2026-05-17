# llm_dart_openai

Provider-native OpenAI-family models, options, capability descriptors, and UI
helpers for `llm_dart`.

This package owns the modern OpenAI-family boundary for:

- OpenAI
- OpenRouter
- DeepSeek
- Groq
- xAI
- focused Phind compatibility on the same transport family

Use this package when you want:

- direct `openai(...).chatModel(...)` model construction outside the broad
  root facade
- provider-owned OpenAI-profile file lifecycle through `openai(...).files()`
- provider-owned OpenAI-profile moderation through `openai(...).moderation()`
- provider-owned OpenAI-profile assistant lifecycle through
  `openai(...).assistants()`
- provider-owned raw Responses lifecycle through
  `openai(...).responsesLifecycle()`
- OpenAI-family profiles such as `OpenAIProfile`, `OpenRouterProfile`,
  `DeepSeekProfile`, `GroqProfile`, `XAIProfile`, and `PhindProfile`
- provider-owned settings such as `OpenAIChatModelSettings`,
  `OpenAIEmbeddingModelSettings`, `OpenAIImageModelSettings`,
  `OpenAISpeechModelSettings`, and `OpenAITranscriptionModelSettings`
- provider-owned invocation options such as `OpenAIGenerateTextOptions`,
  `OpenAIImageOptions`, `OpenAISpeechOptions`, `OpenAITranscriptionOptions`,
  OpenRouter options, DeepSeek options, and xAI options
- provider-owned image editing through `OpenAIImageModel.edit(...)` and
  `OpenAIImageEditRequest`
- provider-native built-in tools, response formats, and custom content/event
  parts through `OpenAICustomPart`
- model-centric capability discovery through `describeOpenAIChatModel(...)`

If you prefer the convenience root package, the same focused entrypoint is
re-exported from `package:llm_dart/openai.dart`.

This package can also be consumed without a dependency on the root `llm_dart`
package. Pair it with `llm_dart_ai` only when you want the shared helper calls
such as `generateTextCall(...)`, `streamTextCall(...)`, or `generateImage(...)`.

## Installation

```yaml
dependencies:
  llm_dart_openai: ^0.11.0-alpha.1
  llm_dart_ai: ^0.11.0-alpha.1
```

Omit `llm_dart_ai` if your application only constructs provider models or calls
provider-owned lifecycle APIs directly.

## Recommended Layering

1. Create a concrete model with `openai(...).chatModel(...)`. The `OpenAI(...)`
   constructor remains available when you need to pass an explicit profile.
2. Keep application calls on the shared helpers from `llm_dart_ai` such as
   `generateTextCall(...)`, `streamTextCall(...)`, `embed(...)`,
   `generateImage(...)`, `generateSpeech(...)`, and `transcribe(...)`.
3. Add OpenAI-family behavior through model settings or
   `CallOptions.providerOptions`, not by widening the shared request shape.
4. Keep UI projection on `llm_dart_ai` / `llm_dart_chat`; use
   `OpenAICustomPart` and `OpenAICustomPartSummary` on provider content parts
   or stream events before UI projection.
5. Use `openai(...).assistants()` and `openai(...).responsesLifecycle()` for
   OpenAI-native lifecycle operations that should not widen the shared
   `llm_dart_ai` request/runtime contract.

## Basic Example

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final model = openai(apiKey: 'your-openai-key').chatModel('gpt-4.1-mini');

  final result = await ai.generateTextCall(
    model: model,
    messages: [
      ai.UserModelMessage.text(
        'Summarize the release plan in three short bullets.',
      ),
    ],
  );

  print(result.text);
}
```

## Provider-Owned Options Example

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final model = openai(apiKey: 'your-openai-key').chatModel(
    'gpt-5.4',
    settings: const OpenAIChatModelSettings(
      useResponsesApi: true,
      builtInTools: [OpenAIWebSearchTool()],
    ),
  );

  final result = await ai.generateTextCall(
    model: model,
    messages: [
      ai.UserModelMessage.text('Find recent Dart release highlights.'),
    ],
    callOptions: const ai.CallOptions(
      providerOptions: OpenAIGenerateTextOptions(
        reasoningEffort: OpenAIReasoningEffort.medium,
        promptCacheKey: 'release-highlights',
      ),
    ),
  );

  print(result.text);
}
```

## OpenAI-Family Profile Example

Use profiles when you want one package boundary to host multiple
OpenAI-compatible providers with explicit routing defaults:

```dart
import 'package:llm_dart_openai/llm_dart_openai.dart';

final groqModel =
    groq(apiKey: 'your-groq-key').chatModel('llama-3.3-70b-versatile');
```

The same package also exposes `deepSeek(...)`, `openRouter(...)`, `xai(...)`,
and `phind(...)` short factories. The grouped root `AI.*` facade remains
available when you depend on the root `llm_dart` package and prefer one
namespace.

OpenRouter app attribution headers can be passed through the package-local
factory:

```dart
import 'package:llm_dart_openai/llm_dart_openai.dart';

final openRouterModel = openRouter(
  apiKey: 'your-openrouter-key',
  appReferer: 'https://example.com',
  appTitle: 'Example App',
).chatModel('openai/gpt-4o-mini');
```

## OpenAI Moderation Example

`openai(...).moderation()` is intentionally OpenAI-profile only. Other
OpenAI-family profiles can share transport compatibility without sharing the
hosted moderation endpoint contract.

```dart
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final moderation = openai(apiKey: 'your-openai-key').moderation(
    settings: const OpenAIModerationSettings(
      defaultModel: 'omni-moderation-latest',
    ),
  );

  final result = await moderation.moderateText(
    'Please keep the discussion respectful and constructive.',
  );

  print(result.flagged);
  print(result.categoryScores.harassment);
}
```

## OpenAI Files Example

`openai(...).files()` is also intentionally OpenAI-profile only. File purpose
values, hosted storage behavior, and download semantics stay provider-owned.

```dart
import 'dart:convert';

import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final files = openai(apiKey: 'your-openai-key').files();

  final uploaded = await files.uploadBytes(
    bytes: utf8.encode('training or assistant resource data'),
    filename: 'resource.txt',
    purpose: OpenAIFilePurposes.assistants,
    mediaType: 'text/plain',
  );

  final downloaded = await files.downloadFile(uploaded.id);
  print(downloaded.sizeBytes);
}
```

## OpenAI Assistants Example

`openai(...).assistants()` owns Assistants CRUD and assistant-specific DTOs in
this package. Function tools use the shared provider `FunctionToolDefinition`
instead of the old root tool models.

```dart
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

Future<void> main() async {
  final assistants = openai(apiKey: 'your-openai-key').assistants();

  final assistant = await assistants.createAssistant(
    OpenAICreateAssistantRequest(
      model: 'gpt-4.1-mini',
      name: 'Support Assistant',
      instructions: 'Answer customer support questions.',
      tools: [
        OpenAIAssistantFunctionTool(
          function: FunctionToolDefinition(
            name: 'lookup_ticket',
            inputSchema: ToolJsonSchema.object(),
          ),
        ),
      ],
    ),
  );

  print(assistant.id);
}
```

## OpenAI Responses Lifecycle Example

Shared text generation should still use `OpenAILanguageModel` plus
`llm_dart_ai`. Use `openai(...).responsesLifecycle()` only when the application
needs OpenAI-native raw response storage, cancellation, continuation, deletion,
or input-item inspection.

```dart
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final responses = openai(apiKey: 'your-openai-key').responsesLifecycle();

  final created = await responses.createResponse({
    'model': 'gpt-4.1-mini',
    'input': 'Create a short incident summary.',
    'background': true,
  });

  final items = await responses.listInputItems(created.id!);
  print(items.data.length);
}
```

## OpenAI Image Editing Example

Prompt-based image generation uses the shared `generateImage(...)` helper.
Current OpenAI image models such as `gpt-image-2` can use provider-owned
options like `moderation`, `outputFormat`, and `outputCompression`.
File-based editing is a provider-owned helper because input images, masks,
fidelity, partial images, and output options are OpenAI-specific.

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final imageModel =
      openai(apiKey: 'your-openai-key').imageModel('gpt-image-1');

  final inputBytes = await File('input.png').readAsBytes();
  final result = await imageModel.edit(
    OpenAIImageEditRequest(
      prompt: 'Turn this product photo into a clean hero image.',
      images: [
        OpenAIImageEditInput(
          bytes: inputBytes,
          mediaType: 'image/png',
          filename: 'input.png',
        ),
      ],
      inputFidelity: OpenAIImageInputFidelity.high,
      callOptions: const ai.CallOptions(
        providerOptions: OpenAIImageOptions(
          quality: OpenAIImageQuality.high,
          responseFormat: OpenAIImageResponseFormat.base64Json,
        ),
      ),
    ),
  );

  print(result.images.first.bytes?.length);
}
```

## Custom Parts And Capability Discovery

- `OpenAICustomPart` and `OpenAICustomPartSummary` help render provider-owned
  replay payloads without widening shared provider contracts or shared UI
  types.
- `describeOpenAIChatModel(...)` returns a `ModelCapabilityProfile` for app or
  Flutter capability gating.
- `describeOpenAIImageModel(...)` does the same for OpenAI-family image models,
  including provider-owned edit support metadata.
- `OpenAIFilesClient` is a narrow OpenAI-profile lifecycle client and does not
  imply a shared remote file-management contract.
- `OpenAIModerationClient` is a narrow OpenAI-profile safety client and does
  not imply a shared moderation abstraction or OpenAI-family-wide feature.
- `OpenAIAssistantsClient` is a narrow OpenAI-profile assistant lifecycle
  client and does not imply a shared assistant abstraction.
- `OpenAIResponsesLifecycleClient` is a narrow OpenAI-profile raw lifecycle
  client; normal prompt execution remains on `OpenAILanguageModel`.

## Boundary Notes

- Shared model calls are the default path.
- Provider-owned options extend the shared call contract; they do not replace
  it.
- Root compatibility APIs are not the ownership path for OpenAI-native
  lifecycle operations; focused package APIs own those provider-specific
  features.
- OpenAI-family profiles let one package host provider-specific request routing
  without pretending every family member shares the same hosted feature set.

## Related Docs

- Root package overview: `../../README.md`
- OpenAI provider examples: `../../example/04_providers/openai/README.md`
- Other OpenAI-family examples: `../../example/04_providers/others/README.md`
