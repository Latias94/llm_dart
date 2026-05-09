// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart_community/llm_dart_community.dart' as community;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/providers/anthropic/anthropic.dart'
    as anthropic_compat;
import 'package:llm_dart/providers/openai/openai.dart' as openai_compat;

/// Model discovery now has two different architectural roles:
/// - stable concrete-model inspection through capability profiles
/// - provider-owned catalog listing through focused helpers or compatibility clients
///
/// Most apps should bind an approved model list in config and use capability
/// profiles for product gating. Remote catalogs are mainly for admin,
/// diagnostics, or model-browsing workflows.
Future<void> main() async {
  print('Model Discovery Example\n');

  demonstrateConcreteModelProfiles();

  final openAIApiKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIApiKey != null && openAIApiKey.isNotEmpty) {
    await demonstrateOpenAIRemoteCatalogBoundary(openAIApiKey);
  } else {
    print(
        'Skipping OpenAI catalog listing because OPENAI_API_KEY is not set.\n');
  }

  final anthropicApiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (anthropicApiKey != null && anthropicApiKey.isNotEmpty) {
    await demonstrateAnthropicRemoteCatalogBoundary(anthropicApiKey);
  } else {
    print(
      'Skipping Anthropic catalog listing because ANTHROPIC_API_KEY is not set.\n',
    );
  }

  final ollamaBaseUrl = Platform.environment['OLLAMA_BASE_URL'];
  if (ollamaBaseUrl != null && ollamaBaseUrl.isNotEmpty) {
    await demonstrateOllamaLocalCatalogBoundary(ollamaBaseUrl);
  } else {
    print(
      'Skipping Ollama local catalog listing because OLLAMA_BASE_URL is not set.\n',
    );
  }

  explainBoundary();

  print('\nModel discovery example completed.');
}

void demonstrateConcreteModelProfiles() {
  print('=== Stable Concrete Model Profiles ===\n');

  final models = <(String label, core.LanguageModel model)>[
    (
      'OpenAI / gpt-4.1-mini',
      llm.openai(apiKey: 'demo-key').chatModel('gpt-4.1-mini'),
    ),
    (
      'Google / gemini-2.5-flash',
      llm.google(apiKey: 'demo-key').chatModel('gemini-2.5-flash'),
    ),
    (
      'Anthropic / claude-sonnet-4-5',
      llm.anthropic(apiKey: 'demo-key').chatModel('claude-sonnet-4-5'),
    ),
  ];

  for (final entry in models) {
    final profile = switch (entry.$2) {
      core.CapabilityDescribedModel(:final capabilityProfile) =>
        capabilityProfile,
      _ => null,
    };

    if (profile == null) {
      continue;
    }

    print(entry.$1);
    print('  providerId: ${profile.providerId}');
    print('  modelId: ${profile.modelId}');
    print(
      '  structuredOutput: ${profile.supports(core.ModelCapabilityFeatureIds.languageStructuredOutput)}',
    );
    print(
      '  fileInput: ${profile.supports(core.ModelCapabilityFeatureIds.languageFileInput)}',
    );
    print(
      '  reasoningOutput: ${profile.supports(core.ModelCapabilityFeatureIds.languageReasoningOutput)}',
    );
    print('');
  }
}

Future<void> demonstrateOpenAIRemoteCatalogBoundary(String apiKey) async {
  print('=== Provider-Owned OpenAI Remote Catalog Boundary ===\n');

  final catalogClient = openai_compat.createOpenAIProvider(
    apiKey: apiKey,
    model: 'gpt-4o',
  );

  final models = await catalogClient.models();
  print('Catalog size: ${models.length}');
  _printCatalogSummary(models);
  print('');
}

Future<void> demonstrateAnthropicRemoteCatalogBoundary(String apiKey) async {
  print('=== Provider-Owned Anthropic Remote Catalog Boundary ===\n');

  final catalogClient = anthropic_compat.createAnthropicProvider(
    apiKey: apiKey,
    model: 'claude-sonnet-4-20250514',
  );

  final models = await catalogClient.models();
  print('Catalog size: ${models.length}');
  _printCatalogSummary(models);
  print('');
}

Future<void> demonstrateOllamaLocalCatalogBoundary(String baseUrl) async {
  print('=== Provider-Owned Ollama Local Catalog Boundary ===\n');

  final catalog = community.Ollama(baseUrl: baseUrl).catalog();
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

  print('');
}

void explainBoundary() {
  print('=== Boundary Notes ===\n');
  print(
    '• For app startup, prefer a reviewed model allowlist in config or remote '
    'config rather than fetching the provider catalog on every launch.',
  );
  print(
    '• For Flutter and app UI gating, prefer capability profiles from the '
    'concrete models you already selected.',
  );
  print(
    '• Use provider-owned catalog listing only when product requirements '
    'actually need remote discovery, admin tooling, or ops dashboards.',
  );
  print(
    '• Remote model catalogs are not stable shared architecture because '
    'providers expose different metadata, filtering rules, and listing endpoints.',
  );
  print(
    '• Even a local Ollama installed-model list stays provider-owned because '
    "it reflects one runtime's storage and tag semantics, not a shared model registry.",
  );
}

void _printCatalogSummary(List<AIModel> models) {
  if (models.isEmpty) {
    print('No models returned.');
    return;
  }

  final preview = models.take(5).toList(growable: false);
  for (final model in preview) {
    final ownerSuffix =
        model.ownedBy == null ? '' : ' (owner: ${model.ownedBy})';
    print('- ${model.id}$ownerSuffix');
  }

  final structuredCandidates = models.where((model) {
    final lowerId = model.id.toLowerCase();
    return lowerId.contains('gpt-4') ||
        lowerId.contains('gpt-5') ||
        lowerId.contains('claude') ||
        lowerId.contains('gemini');
  }).take(3);

  final candidateList = structuredCandidates.map((model) => model.id).toList();
  if (candidateList.isNotEmpty) {
    print('Suggested app-facing candidates: ${candidateList.join(', ')}');
  }
}
