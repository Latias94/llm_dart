# llm_dart_anthropic

Anthropic provider implementations for `llm_dart`.

This package owns the provider-native Anthropic chat/files/tooling surfaces,
typed Anthropic options, and Anthropic-specific request/response codecs.

Use this package when you want the focused Anthropic package boundary directly
instead of the broader root facade.

It can be consumed without a dependency on the root `llm_dart` package. Add
`llm_dart_ai` only when you want the shared generation helper calls.

## Installation

```yaml
dependencies:
  llm_dart_anthropic: ^0.11.0-alpha.1
  llm_dart_ai: ^0.11.0-alpha.1
```

The root `llm_dart` package re-exports the main focused entrypoint through:

- `package:llm_dart/anthropic.dart`
  - includes the `anthropic(...)` factory plus provider-owned Anthropic types

## Recommended Layering

1. Create a concrete chat model with `anthropic(...).chatModel(...)`.
2. Use `llm_dart_ai` helpers such as `generateTextCall(...)` and
   `streamTextCall(...)` for shared app flows.
3. Put Anthropic-specific controls in `AnthropicGenerateTextOptions` or
   `AnthropicChatModelSettings`, not in shared request types.
4. Use `anthropic(...).files()` for Anthropic beta file lifecycle.
5. Keep older provider-shell examples as compatibility appendix material, not
   as the default architecture for new application code.

## Basic Chat Example

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

Future<void> main() async {
  final model = anthropic(apiKey: 'your-anthropic-key').chatModel(
    'claude-3-5-haiku-latest',
  );

  final result = await ai.generateTextCall(
    model: model,
    messages: [
      ai.UserModelMessage.text('Summarize the design in three bullets.'),
    ],
  );

  print(result.text);
}
```

## Provider-Owned Options Example

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

Future<void> main() async {
  final model = anthropic(apiKey: 'your-anthropic-key').chatModel(
    'claude-sonnet-4-5',
    settings: const AnthropicChatModelSettings(
      betaFeatures: ['files-api-2025-04-14'],
    ),
  );

  final result = await ai.generateTextCall(
    model: model,
    messages: [
      ai.UserModelMessage.text('Solve this logic puzzle step by step.'),
    ],
    callOptions: const ai.CallOptions(
      providerOptions: AnthropicGenerateTextOptions(
        extendedThinking: true,
        thinkingBudgetTokens: 2048,
      ),
    ),
  );

  print(result.reasoningText);
  print(result.text);
}
```

## Files

`anthropic(...).files()` is the focused provider-owned file lifecycle surface
for Anthropic beta files:

- `uploadFile(...)` / `uploadBytes(...)`
- `listFiles(...)`
- `getFile(...)`
- `downloadFile(...)`
- `deleteFile(...)`

This is intentionally not a shared cross-provider file-management abstraction.
File IDs, beta headers, download behavior, and lifecycle semantics remain
Anthropic-owned.

```dart
import 'dart:convert';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';

Future<void> main() async {
  final files = anthropic(apiKey: 'your-anthropic-key').files();

  final uploaded = await files.uploadBytes(
    utf8.encode('document content'),
    filename: 'document.txt',
    mediaType: 'text/plain',
  );
  final page = await files.listFiles(limit: 10);
  final metadata = await files.getFile(uploaded.id);

  print(page.data.length);
  print(metadata.filename);
}
```

For the larger repository architecture and migration story, start with the root
package README.
