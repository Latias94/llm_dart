// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/llm_dart.dart' as llm;
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/providers/anthropic/anthropic.dart'
    as anthropic_compat;
import 'package:llm_dart/providers/openai/openai.dart' as openai_compat;

/// Model discovery now has two different architectural roles:
/// - stable concrete-model inspection through capability profiles
/// - provider-owned remote catalog listing through compatibility providers
Future<void> main() async {
  print('Model Discovery Example\n');

  demonstrateConcreteModelProfiles();

  final openAIApiKey = Platform.environment['OPENAI_API_KEY'];
  if (openAIApiKey != null && openAIApiKey.isNotEmpty) {
    await demonstrateOpenAICatalog(openAIApiKey);
  } else {
    print('Skipping OpenAI catalog listing because OPENAI_API_KEY is not set.\n');
  }

  final anthropicApiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (anthropicApiKey != null && anthropicApiKey.isNotEmpty) {
    await demonstrateAnthropicCatalog(anthropicApiKey);
  } else {
    print(
      'Skipping Anthropic catalog listing because ANTHROPIC_API_KEY is not set.\n',
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
      llm.AI.openai(apiKey: 'demo-key').chatModel('gpt-4.1-mini'),
    ),
    (
      'Google / gemini-2.5-flash',
      llm.AI.google(apiKey: 'demo-key').chatModel('gemini-2.5-flash'),
    ),
    (
      'Anthropic / claude-sonnet-4-5',
      llm.AI.anthropic(apiKey: 'demo-key').chatModel('claude-sonnet-4-5'),
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

Future<void> demonstrateOpenAICatalog(String apiKey) async {
  print('=== OpenAI Remote Catalog Boundary ===\n');

  final provider = openai_compat.createOpenAIProvider(
    apiKey: apiKey,
    model: 'gpt-4o',
  );

  final models = await provider.models();
  print('Catalog size: ${models.length}');
  _printCatalogSummary(models);
  print('');
}

Future<void> demonstrateAnthropicCatalog(String apiKey) async {
  print('=== Anthropic Remote Catalog Boundary ===\n');

  final provider = anthropic_compat.createAnthropicProvider(
    apiKey: apiKey,
    model: 'claude-sonnet-4-20250514',
  );

  final models = await provider.models();
  print('Catalog size: ${models.length}');
  _printCatalogSummary(models);
  print('');
}

void explainBoundary() {
  print('=== Boundary Notes ===\n');
  print(
    '• For Flutter and app UI gating, prefer capability profiles from the '
    'concrete models you already selected.',
  );
  print(
    '• Use provider-owned catalog listing only when product requirements '
    'actually need remote discovery, ops dashboards, or admin tooling.',
  );
  print(
    '• Remote model catalogs are not stable shared architecture because '
    'providers expose different metadata, filtering rules, and listing endpoints.',
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
