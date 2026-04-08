# llm_dart_community

Workspace package for modern community-provider shared-capability surfaces.

This package currently owns the package-owned modern model namespaces for:

- `Ollama(...).chatModel(...)`
- `Ollama(...).embeddingModel(...)`
- `ElevenLabs(...).speechModel(...)`
- `ElevenLabs(...).transcriptionModel(...)`

It depends only on:

- `llm_dart_core`
- `llm_dart_transport`

That keeps the modern community-provider path independent from the root
compatibility layer.

## Current Scope

Use this package when application code only needs a shared-capability model
surface with provider-owned typed settings.

Current shared-capability ownership:

- Ollama chat generation
- Ollama embeddings
- ElevenLabs text-to-speech
- ElevenLabs direct-audio transcription

## Runnable Examples

This package now also includes minimal runnable examples for each current modern
surface:

- `example/ollama_chat.dart`
- `example/ollama_embeddings.dart`
- `example/elevenlabs_speech.dart`
- `example/elevenlabs_transcription.dart`

Run them from this package directory:

```bash
dart run example/ollama_chat.dart
dart run example/ollama_embeddings.dart
dart run example/elevenlabs_speech.dart
dart run example/elevenlabs_transcription.dart
```

## What Stays Outside This Package

This package does not try to flatten every community-provider API into the
shared modern surface.

The following remain provider-owned or compatibility-only for now:

- root `ai()` builder flows
- root Ollama and ElevenLabs broad compatibility shells
- Ollama `/api/generate` completion
- Ollama model listing
- ElevenLabs voice catalogs, cloning, realtime, and admin-style APIs
- ElevenLabs file-path convenience flows beyond the shared byte-oriented
  `TranscriptionModel`

## Ollama Example

```dart
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart_core/llm_dart_core.dart' as core;

Future<void> main() async {
  final model = community.Ollama(
    baseUrl: 'http://localhost:11434',
  ).chatModel('llama3.2');

  final result = await core.generateTextCall(
    model: model,
    prompt: [
      core.UserPromptMessage.text('Explain when local models are useful.'),
    ],
  );

  print(result.text);
}
```

Embeddings use the same package-owned namespace:

```dart
final embeddingModel = community.Ollama().embeddingModel(
  'nomic-embed-text',
);
```

## ElevenLabs Example

```dart
import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart_core/llm_dart_core.dart' as core;

Future<void> main() async {
  final speechModel = community.ElevenLabs(
    apiKey: 'your-elevenlabs-key',
  ).speechModel('eleven_multilingual_v2');

  final speech = await core.generateSpeech(
    model: speechModel,
    text: 'Speak clearly and naturally.',
  );

  print(speech.audioBytes.length);
}
```

Direct-audio transcription uses the same package-owned namespace:

```dart
final transcriptionModel = community.ElevenLabs(
  apiKey: 'your-elevenlabs-key',
).transcriptionModel('scribe_v1');
```

## Relationship To The Root Package

`package:llm_dart/legacy.dart` still exposes broader compatibility shells for
Ollama and ElevenLabs.

Prefer that root compatibility layer only when you truly need broader
provider-specific behavior that does not belong in the shared-capability model
surface yet.

## Related Docs

- Root package overview: `../../README.md`
- Migration guide:
  `../../docs/workstreams/2026-03-architecture-refactor/38-migration-guide.md`
- Community provider public-entry guidance:
  `../../docs/workstreams/2026-03-architecture-refactor/104-community-provider-public-entry-guidance.md`
