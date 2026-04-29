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

- direct `OpenAI(...)` model construction outside the broad root facade
- provider-owned OpenAI-profile file lifecycle through `OpenAI(...).files()`
- provider-owned OpenAI-profile moderation through `OpenAI(...).moderation()`
- OpenAI-family profiles such as `OpenAIProfile`, `OpenRouterProfile`,
  `DeepSeekProfile`, `GroqProfile`, `XAIProfile`, and `PhindProfile`
- provider-owned settings such as `OpenAIChatModelSettings`,
  `OpenAIEmbeddingModelSettings`, `OpenAIImageModelSettings`,
  `OpenAISpeechModelSettings`, and `OpenAITranscriptionModelSettings`
- provider-owned invocation options such as `OpenAIGenerateTextOptions`,
  `OpenAIImageOptions`, `OpenAISpeechOptions`, `OpenAITranscriptionOptions`,
  OpenRouter options, and xAI options
- provider-owned image editing through `OpenAIImageModel.edit(...)` and
  `OpenAIImageEditRequest`
- provider-native built-in tools, response formats, custom parts, and UI
  mapping through `OpenAIMessageMapper`
- model-centric capability discovery through `describeOpenAIChatModel(...)`

If you prefer the convenience root package, the same focused entrypoint is
re-exported from `package:llm_dart/openai.dart`.

## Recommended Layering

1. Create a concrete model with `OpenAI(...).chatModel(...)` or the root
   `AI.openai(...).chatModel(...)` facade.
2. Keep application calls on the shared helpers from `llm_dart_core` such as
   `generateTextCall(...)`, `streamTextCall(...)`, `embed(...)`,
   `generateImage(...)`, `generateSpeech(...)`, and `transcribe(...)`.
3. Add OpenAI-family behavior through model settings or
   `CallOptions.providerOptions`, not by widening the shared request shape.
4. Use `OpenAIMessageMapper` only when the UI needs OpenAI-specific metadata on
   top of the shared `ChatMessageMapper`.
5. Drop to the root compatibility surfaces only when you truly need assistant
   lifecycle APIs, raw Responses CRUD/lifecycle APIs, or other legacy
   migration-era flows outside this package's modern boundary.

## Basic Example

```dart
import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final model = OpenAI(
    apiKey: 'your-openai-key',
  ).chatModel('gpt-4.1-mini');

  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text(
        'Summarize the release plan in three short bullets.',
      ),
    ],
  );

  print(result.text);
}
```

## Provider-Owned Options Example

```dart
import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final model = OpenAI(
    apiKey: 'your-openai-key',
  ).chatModel(
    'gpt-5.4',
    settings: const OpenAIChatModelSettings(
      useResponsesApi: true,
      builtInTools: [OpenAIWebSearchTool()],
    ),
  );

  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Find recent Dart release highlights.'),
    ],
    callOptions: const core.CallOptions(
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

final groqModel = OpenAI(
  apiKey: 'your-groq-key',
  profile: const GroqProfile(),
).chatModel('llama-3.3-70b-versatile');
```

If you prefer the root convenience facade, `AI.groq(...)`, `AI.deepSeek(...)`,
`AI.openRouter(...)`, and `AI.xai(...)` are the equivalent stable entrypoints.

## OpenAI Moderation Example

`OpenAI(...).moderation()` is intentionally OpenAI-profile only. Other
OpenAI-family profiles can share transport compatibility without sharing the
hosted moderation endpoint contract.

```dart
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final moderation = OpenAI(
    apiKey: 'your-openai-key',
  ).moderation(
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

`OpenAI(...).files()` is also intentionally OpenAI-profile only. File purpose
values, hosted storage behavior, and download semantics stay provider-owned.

```dart
import 'dart:convert';

import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final files = OpenAI(
    apiKey: 'your-openai-key',
  ).files();

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

## OpenAI Image Editing Example

Prompt-based image generation uses the shared `generateImage(...)` helper.
File-based editing is a provider-owned helper because input images, masks,
fidelity, partial images, and output options are OpenAI-specific.

```dart
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  final imageModel = OpenAI(
    apiKey: 'your-openai-key',
  ).imageModel('gpt-image-1');

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
      callOptions: const core.CallOptions(
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

## UI Mapping And Capability Discovery

- `OpenAIMessageMapper` composes provider-owned metadata with the shared UI
  model.
- `OpenAICustomPart` and `OpenAICustomPartSummary` help render provider-owned
  replay payloads without widening shared UI types.
- `describeOpenAIChatModel(...)` returns a `ModelCapabilityProfile` for app or
  Flutter capability gating.
- `describeOpenAIImageModel(...)` does the same for OpenAI-family image models,
  including provider-owned edit support metadata.
- `OpenAIFilesClient` is a narrow OpenAI-profile lifecycle client and does not
  imply a shared remote file-management contract.
- `OpenAIModerationClient` is a narrow OpenAI-profile safety client and does
  not imply a shared moderation abstraction or OpenAI-family-wide feature.

## Boundary Notes

- Shared model calls are the default path.
- Provider-owned options extend the shared call contract; they do not replace
  it.
- Root compatibility APIs remain the explicit migration and appendix path for
  assistants, raw Responses lifecycle, and other residual compatibility flows.
- OpenAI-family profiles let one package host provider-specific request routing
  without pretending every family member shares the same hosted feature set.

## Related Docs

- Root package overview: `../../README.md`
- OpenAI provider examples: `../../example/04_providers/openai/README.md`
- Other OpenAI-family examples: `../../example/04_providers/others/README.md`
