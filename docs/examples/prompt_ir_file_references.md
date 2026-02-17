# Prompt IR: file references (copy/paste examples)

These examples demonstrate the minimal Prompt IR shapes for:

- Google: `FileIdPart(id: 'files/...')`
- OpenAI Responses: `FileIdPart(id: 'file-...')`
- URL-based PDFs: `FileUrlPart(mime: FileMime.pdf, url: 'https://...')`

Note:

- These require **prompt-native** capabilities. Prefer `llm_dart_ai` with
  `generateText(promptIr: ...)`.
- `Prompt.toChatMessages()` cannot losslessly represent `FileUrlPart` /
  `FileIdPart` and will throw.

---

## 1) Google: use a Files API id (`files/...`)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';

Future<void> main() async {
  registerGoogle();

  final model = await LLMBuilder()
      .provider(googleProviderId) // 'google'
      .apiKey(Platform.environment['GOOGLE_API_KEY'] ?? 'GOOGLE_API_KEY')
      .model('gemini-2.5-pro')
      .build();

  final prompt = Prompt(messages: [
    const PromptMessage(
      role: ChatRole.user,
      parts: [
        FileIdPart(mime: FileMime.pdf, id: 'files/123'),
        TextPart('Summarize it.'),
      ],
    ),
  ]);

  final result = await generateText(model: model, promptIr: prompt);
  print(result.text);
}
```

---

## 2) OpenAI Responses: use a file id (`file-...`)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

Future<void> main() async {
  registerOpenAI();

  final model = await LLMBuilder()
      .provider(openaiProviderId) // 'openai'
      .apiKey(Platform.environment['OPENAI_API_KEY'] ?? 'OPENAI_API_KEY')
      .model('gpt-4o')
      .build();

  final prompt = Prompt(messages: [
    const PromptMessage(
      role: ChatRole.user,
      parts: [
        FileIdPart(mime: FileMime.pdf, id: 'file-abc'),
        TextPart('Summarize it.'),
      ],
    ),
  ]);

  final result = await generateText(model: model, promptIr: prompt);
  print(result.text);
}
```

---

## 3) URL-based PDF (`FileUrlPart`)

```dart
import 'dart:io';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';

Future<void> main() async {
  registerGoogle();

  final model = await LLMBuilder()
      .provider(googleProviderId) // 'google'
      .apiKey(Platform.environment['GOOGLE_API_KEY'] ?? 'GOOGLE_API_KEY')
      .model('gemini-2.5-pro')
      // Optional: strict AI SDK-style URL validation.
      .option('supportedFileUrlsOnly', true)
      .build();

  final prompt = Prompt(messages: [
    const PromptMessage(
      role: ChatRole.user,
      parts: [
        FileUrlPart(
          mime: FileMime.pdf,
          // For strict mode, prefer a Google Files API URL:
          // https://generativelanguage.googleapis.com/v1beta/files/...
          url: 'https://generativelanguage.googleapis.com/v1beta/files/123',
        ),
        TextPart('Summarize it.'),
      ],
    ),
  ]);

  final result = await generateText(model: model, promptIr: prompt);
  print(result.text);
}
```
