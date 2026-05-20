// ignore_for_file: avoid_print

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs;
import 'package:llm_dart_google/llm_dart_google.dart' as google;
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Focused model and lifecycle factories.
///
/// Older versions used root builder helpers to discover or cast provider
/// capabilities. The modern shape is intentionally simpler:
/// - construct the provider facade you actually want
/// - ask it for a concrete model or provider-owned client
/// - inspect `CapabilityDescribedModel` when app UI needs feature gates
void main() {
  print('Focused Factory Methods\n');

  demonstrateOpenAIFactories();
  demonstrateGoogleFactories();
  demonstrateElevenLabsFactories();
  demonstrateOllamaFactories();
  explainMigrationRule();
}

void demonstrateOpenAIFactories() {
  print('--- OpenAI ---');

  final provider = openai.openai(apiKey: 'demo-key');
  final chat = provider.chatModel(
    'gpt-4.1-mini',
    settings: const openai.OpenAIChatModelSettings(useResponsesApi: true),
  );
  final embeddings = provider.embeddingModel('text-embedding-3-small');
  final image = provider.imageModel('gpt-image-1');
  final speech = provider.speechModel('gpt-4o-mini-tts');
  final transcription = provider.transcriptionModel('gpt-4o-mini-transcribe');
  final moderation = provider.moderation();
  final files = provider.files();
  final assistants = provider.assistants();
  final responses = provider.responsesLifecycle();

  _printProfile('chat', chat);
  _printProfile('embeddings', embeddings);
  _printProfile('image', image);
  _printProfile('speech', speech);
  _printProfile('transcription', transcription);
  print('  moderation client: ${moderation.runtimeType}');
  print('  files client: ${files.runtimeType}');
  print('  assistants client: ${assistants.runtimeType}');
  print('  responses lifecycle client: ${responses.runtimeType}');
  print('');
}

void demonstrateGoogleFactories() {
  print('--- Google ---');

  final provider = google.google(apiKey: 'demo-key');
  _printProfile('chat', provider.chatModel('gemini-2.5-flash'));
  _printProfile('embeddings', provider.embeddingModel('text-embedding-004'));
  _printProfile('image', provider.imageModel('imagen-4.0-generate-001'));
  _printProfile(
    'speech',
    provider.speechModel(
      'gemini-2.5-flash-preview-tts',
      settings: const google.GoogleSpeechModelSettings(defaultVoice: 'Kore'),
    ),
  );
  print('');
}

void demonstrateElevenLabsFactories() {
  print('--- ElevenLabs ---');

  final provider = elevenlabs.elevenLabs(apiKey: 'demo-key');
  _printProfile(
    'speech',
    provider.speechModel(
      'eleven_multilingual_v2',
      settings: const elevenlabs.ElevenLabsSpeechModelSettings(
        defaultVoiceId: elevenlabs.elevenLabsDefaultVoiceId,
      ),
    ),
  );
  _printProfile('transcription', provider.transcriptionModel('scribe_v1'));
  print('  voice catalog client: ${provider.voices().runtimeType}');
  print('');
}

void demonstrateOllamaFactories() {
  print('--- Ollama ---');

  final provider = ollama.ollama();
  _printProfile('chat', provider.chatModel('llama3.2'));
  _printProfile('embeddings', provider.embeddingModel('nomic-embed-text'));
  print('  local model catalog client: ${provider.catalog().runtimeType}');
  print('');
}

void explainMigrationRule() {
  print('--- Migration Rule ---');
  print('  Delete root builder casts instead of wrapping them.');
  print('  Use focused factories for app-facing work.');
  print(
      '  Keep provider-native lifecycle clients isolated behind provider modules.');
  print(
      '  Put per-request provider behavior in typed provider options, for example:');
  print('    CallOptions(providerOptions: OpenAIGenerateTextOptions(...))');
  print('    CallOptions(providerOptions: GoogleGenerateTextOptions(...))');
  print('    CallOptions(providerOptions: ElevenLabsSpeechOptions(...))');
}

void _printProfile(String label, Object model) {
  final profile = switch (model) {
    core.CapabilityDescribedModel(:final capabilityProfile) =>
      capabilityProfile,
    _ => null,
  };

  if (profile == null) {
    print('  $label: ${model.runtimeType}');
    return;
  }

  print(
    '  $label: ${profile.providerId}/${profile.modelId} '
    '(${profile.kind.name})',
  );
}
