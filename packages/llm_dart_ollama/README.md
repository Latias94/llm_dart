# llm_dart_ollama

Provider-native Ollama models, options, model catalog APIs, and capability
descriptors for `llm_dart`.

Use this package when you want a small direct dependency for local Ollama chat,
embeddings, or installed-model listing without depending on the root
`llm_dart` package.

## Supported Surfaces

- short factory `ollama(...)`
- `ollama(...).chatModel(...)`
- `ollama(...).embeddingModel(...)`
- `ollama(...).catalog().listModels()`
- `OllamaGenerateTextOptions`
- `describeOllamaChatModel(...)`
- `describeOllamaEmbeddingModel(...)`

## Installation

```yaml
dependencies:
  llm_dart_ollama: ^0.11.0-alpha.1
  llm_dart_ai: ^0.11.0-alpha.1
```

Omit `llm_dart_ai` if your application only constructs provider models or calls
provider-owned catalog APIs directly.

## Basic Chat Example

```dart
import 'package:llm_dart_ai/llm_dart_ai.dart' as ai;
import 'package:llm_dart_ollama/llm_dart_ollama.dart';

Future<void> main() async {
  final model = ollama().chatModel('llama3.2');

  final result = await ai.generateTextCall(
    model: model,
    messages: [ai.UserModelMessage.text('Write a short haiku about Dart.')],
  );

  print(result.text);
}
```

## Capability Profiles

Ollama models expose model-centric capability discovery through
`CapabilityDescribedModel.capabilityProfile`.

Ollama capability details can depend on the locally installed model family. The
package treats the stable baseline as known and labels family-shaped extras such
as image input or reasoning output as inferred when the local model family is
not standardized enough for a stronger guarantee.

## Runnable Examples

Run these from this package directory:

```bash
dart run example/ollama_chat.dart
dart run example/ollama_embeddings.dart
dart run example/ollama_model_catalog.dart
```

## Relationship To The Root Package

The root `llm_dart` package keeps compatibility-era Ollama entrypoints for
older code. New focused provider code should prefer this package.
