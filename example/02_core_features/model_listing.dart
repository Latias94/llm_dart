// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs;
import 'package:llm_dart_google/llm_dart_google.dart' as google;
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

/// Model discovery has two separate roles:
/// - app-facing inspection of concrete model capability profiles
/// - provider-owned catalog APIs where a focused package exposes one
///
/// Do not rebuild a root provider registry just to list models. Most products
/// should keep a reviewed model allowlist in config and use profiles for UI
/// gates and diagnostics.
Future<void> main() async {
  print('Model Discovery Example\n');

  demonstrateConcreteModelProfiles();
  await demonstrateOllamaLocalCatalog();
  await demonstrateElevenLabsVoiceCatalog();
  explainBoundary();
}

void demonstrateConcreteModelProfiles() {
  print('=== Concrete Model Profiles ===\n');

  final models = <Object>[
    openai.openai(apiKey: 'demo-key').chatModel('gpt-4.1-mini'),
    openai.openai(apiKey: 'demo-key').chatModel('o3-mini'),
    google.google(apiKey: 'demo-key').chatModel('gemini-2.5-flash'),
    anthropic.anthropic(apiKey: 'demo-key').chatModel('claude-sonnet-4-5'),
    elevenlabs
        .elevenLabs(apiKey: 'demo-key')
        .speechModel('eleven_multilingual_v2'),
  ];

  for (final model in models) {
    final profile = switch (model) {
      core.CapabilityDescribedModel(:final capabilityProfile) =>
        capabilityProfile,
      _ => null,
    };

    if (profile == null) {
      continue;
    }

    print('${profile.providerId}/${profile.modelId} (${profile.kind.name})');
    print(
      '  structuredOutput: ${profile.supports(core.ModelCapabilityFeatureIds.languageStructuredOutput)}',
    );
    print(
      '  fileInput: ${profile.supports(core.ModelCapabilityFeatureIds.languageFileInput)}',
    );
    print(
      '  reasoningOutput: ${profile.supports(core.ModelCapabilityFeatureIds.languageReasoningOutput)}',
    );
    print(
      '  speechVoiceSelection: ${profile.supports(core.ModelCapabilityFeatureIds.speechVoiceSelection)}',
    );
    print('');
  }
}

Future<void> demonstrateOllamaLocalCatalog() async {
  print('=== Provider-Owned Ollama Local Catalog ===\n');

  final baseUrl =
      Platform.environment['OLLAMA_BASE_URL'] ?? ollama.ollamaDefaultBaseUrl;

  try {
    final catalog = ollama.ollama(baseUrl: baseUrl).catalog();
    final models = await catalog.listModels();
    print('Catalog size: ${models.length}');

    if (models.isEmpty) {
      print('No local models returned.\n');
      return;
    }

    for (final model in models.take(5)) {
      final family = model.details?.family ?? 'unknown-family';
      print('- ${model.name} (family: $family)');
    }
  } catch (error) {
    print('Ollama catalog listing failed at $baseUrl: $error');
  }

  print('');
}

Future<void> demonstrateElevenLabsVoiceCatalog() async {
  print('=== Provider-Owned ElevenLabs Voice Catalog ===\n');

  final apiKey = Platform.environment['ELEVENLABS_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print(
        'Skipping ElevenLabs voice catalog because ELEVENLABS_API_KEY is not set.');
    print('');
    return;
  }

  try {
    final voices =
        await elevenlabs.elevenLabs(apiKey: apiKey).voices().listVoices();
    print('Voice catalog size: ${voices.length}');
    for (final voice in voices.take(5)) {
      print('- ${voice.name} (${voice.id})');
    }
  } catch (error) {
    print('ElevenLabs voice catalog failed: $error');
  }

  print('');
}

void explainBoundary() {
  print('=== Boundary Notes ===\n');
  print(
    'For app startup, prefer a reviewed model allowlist in config or remote config.',
  );
  print(
    'Use capability profiles from the concrete models you already selected for UI gating.',
  );
  print(
    'Use provider-owned catalogs only for admin, diagnostics, local runtime inspection, or browsing workflows.',
  );
  print(
    'A single root model catalog would hide provider-specific metadata and lifecycle rules.',
  );
}
