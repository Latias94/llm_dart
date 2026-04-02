// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/ai.dart' as ai;
import 'package:llm_dart/legacy.dart' as legacy;

/// Capability detection through provider declarations.
///
/// This example intentionally separates two layers:
/// 1. registry-level capability metadata for provider selection
/// 2. stable `AI.*(...).chatModel(...)` creation for actual execution
///
/// Capability metadata is useful for:
/// - shortlisting providers before choosing API keys and models
/// - documentation and migration planning
/// - understanding provider-family boundaries
///
/// Capability metadata is not a strict runtime contract:
/// - support can vary by model
/// - some features stay provider-owned compatibility boundaries
/// - successful app calls still require graceful error handling
///
/// No credentials are required for the declaration-inspection sections.
/// To run the optional stable execution demo, set one of:
/// - OPENAI_API_KEY
/// - ANTHROPIC_API_KEY
/// - GOOGLE_API_KEY
/// - GROQ_API_KEY
/// - DEEPSEEK_API_KEY
/// - XAI_API_KEY
/// - OPENROUTER_API_KEY
Future<void> main() async {
  print('Capability Detection and Provider Selection\n');

  legacy.ensureRootRegistryBootstrap();
  final providers = loadExampleProviderInfo();

  if (providers.isEmpty) {
    print('No provider declarations are currently registered.');
    return;
  }

  printProviderOverview(providers);
  printScenarioRecommendations(providers);
  printBoundaryGuidance(providers);
  await demonstrateStableExecution(providers);

  print(
      'Capability detection remains advisory; stable calls remain model-first.');
}

List<legacy.ProviderInfo> loadExampleProviderInfo() {
  const providerOrder = [
    'openai',
    'anthropic',
    'google',
    'groq',
    'deepseek',
    'xai',
    'openrouter',
    'phind',
    'ollama',
    'elevenlabs',
  ];

  final allProviders = {
    for (final provider in legacy.LLMProviderRegistry.getAllProviderInfo())
      provider.id: provider,
  };

  return [
    for (final providerId in providerOrder)
      if (allProviders.containsKey(providerId)) allProviders[providerId]!,
  ];
}

void printProviderOverview(List<legacy.ProviderInfo> providers) {
  print('--- Provider Declarations ---');

  final byCoverage = [...providers]..sort(
      (left, right) => right.supportedCapabilities.length
          .compareTo(left.supportedCapabilities.length),
    );

  for (final provider in byCoverage) {
    final capabilities = _highSignalCapabilities
        .where(provider.supports)
        .map(_capabilityLabel)
        .join(', ');

    print(
      '  ${_providerLabel(provider.id).padRight(12)} '
      '(${provider.supportedCapabilities.length} declared): '
      '${capabilities.isEmpty ? 'none' : capabilities}',
    );
  }

  print('');
}

void printScenarioRecommendations(List<legacy.ProviderInfo> providers) {
  print('--- Scenario Recommendations ---');

  const scenarios = [
    _CapabilityScenario(
      label: 'Flutter chat baseline',
      required: {
        legacy.LLMCapability.chat,
        legacy.LLMCapability.streaming,
        legacy.LLMCapability.toolCalling,
      },
    ),
    _CapabilityScenario(
      label: 'Vision-enabled chat',
      required: {
        legacy.LLMCapability.chat,
        legacy.LLMCapability.vision,
      },
    ),
    _CapabilityScenario(
      label: 'Reasoning-heavy workflows',
      required: {
        legacy.LLMCapability.chat,
        legacy.LLMCapability.reasoning,
      },
    ),
    _CapabilityScenario(
      label: 'Semantic search / RAG indexing',
      required: {
        legacy.LLMCapability.embedding,
      },
    ),
    _CapabilityScenario(
      label: 'Speech input and output',
      required: {
        legacy.LLMCapability.textToSpeech,
        legacy.LLMCapability.speechToText,
      },
    ),
    _CapabilityScenario(
      label: 'Image generation',
      required: {
        legacy.LLMCapability.imageGeneration,
      },
    ),
  ];

  for (final scenario in scenarios) {
    final matches = _providersSupportingAll(providers, scenario.required);
    final requiredLabels = scenario.required.map(_capabilityLabel).join(', ');

    print('  ${scenario.label}');
    print('    Required: $requiredLabels');
    print(
      '    Candidates: '
      '${matches.isEmpty ? 'none declared' : matches.map((provider) => _providerLabel(provider.id)).join(', ')}',
    );
  }

  print('');
}

void printBoundaryGuidance(List<legacy.ProviderInfo> providers) {
  print('--- Boundary Guidance ---');

  final rawResponsesProviders = _providersSupportingAll(
    providers,
    const {legacy.LLMCapability.openaiResponses},
  );

  print(
    '  Raw OpenAI response lifecycle boundary: '
    '${rawResponsesProviders.isEmpty ? 'none declared' : rawResponsesProviders.map((provider) => _providerLabel(provider.id)).join(', ')}',
  );
  print(
    '  Use `openaiResponses` only when you explicitly need provider-specific',
  );
  print(
    '  lifecycle APIs such as fetching, continuing, or deleting raw responses.',
  );
  print(
    '  For normal Flutter chat flows, keep using `AI.openai(...).chatModel(...)`',
  );
  print(
    '  plus shared `generateTextCall(...)` or `streamTextCall(...)` helpers.',
  );
  print(
    '  Some declared providers also remain compatibility-oriented until they',
  );
  print(
    '  receive a stable facade, so declaration coverage and stable app-facing',
  );
  print(
    '  surface coverage are related but not identical.',
  );
  print('');
}

Future<void> demonstrateStableExecution(
    List<legacy.ProviderInfo> providers) async {
  print('--- Stable Execution After Selection ---');

  final candidates = _providersSupportingAll(
    providers,
    const {
      legacy.LLMCapability.chat,
      legacy.LLMCapability.streaming,
    },
  );

  final selected = _selectStableModelFromEnvironment(candidates);
  if (selected == null) {
    print('  No matching API key was found for the stable execution demo.');
    print('  Capability inspection still works without credentials.');
    print('');
    return;
  }

  print('  Selected provider: ${_providerLabel(selected.providerId)}');
  print('  Stable model: ${selected.modelLabel}');

  try {
    final result = await core.generateTextCall(
      model: selected.model,
      prompt: [
        core.SystemPromptMessage.text(
          'You are a concise architecture assistant. Respond in one short paragraph.',
        ),
        core.UserPromptMessage.text(
          'Explain why provider capability metadata helps selection but cannot replace runtime validation.',
        ),
      ],
      options: const core.GenerateTextOptions(
        maxOutputTokens: 120,
      ),
    );

    print('  Response: ${_truncate(result.text)}');
  } catch (error) {
    print('  Stable call failed: $error');
    print(
      '  This is why capability declarations stay advisory rather than becoming a strict runtime guarantee.',
    );
  }

  print('');
}

List<legacy.ProviderInfo> _providersSupportingAll(
  List<legacy.ProviderInfo> providers,
  Set<legacy.LLMCapability> required,
) {
  return providers
      .where((provider) => required.every(provider.supports))
      .toList(growable: false);
}

_SelectedModel? _selectStableModelFromEnvironment(
  List<legacy.ProviderInfo> candidates,
) {
  for (final provider in candidates) {
    final selected = _stableModelForProvider(provider.id);
    if (selected != null) {
      return selected;
    }
  }

  return null;
}

_SelectedModel? _stableModelForProvider(String providerId) {
  switch (providerId) {
    case 'openai':
      final apiKey = Platform.environment['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'OpenAI / gpt-4.1-mini',
        model: ai.AI.openai(apiKey: apiKey).chatModel('gpt-4.1-mini'),
      );
    case 'anthropic':
      final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'Anthropic / claude-sonnet-4-5',
        model: ai.AI.anthropic(apiKey: apiKey).chatModel('claude-sonnet-4-5'),
      );
    case 'google':
      final apiKey = Platform.environment['GOOGLE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'Google / gemini-2.5-flash',
        model: ai.AI.google(apiKey: apiKey).chatModel('gemini-2.5-flash'),
      );
    case 'groq':
      final apiKey = Platform.environment['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'Groq / llama-3.3-70b-versatile',
        model: ai.AI.groq(apiKey: apiKey).chatModel('llama-3.3-70b-versatile'),
      );
    case 'deepseek':
      final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'DeepSeek / deepseek-chat',
        model: ai.AI.deepSeek(apiKey: apiKey).chatModel('deepseek-chat'),
      );
    case 'xai':
      final apiKey = Platform.environment['XAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'xAI / grok-3',
        model: ai.AI.xai(apiKey: apiKey).chatModel('grok-3'),
      );
    case 'openrouter':
      final apiKey = Platform.environment['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'OpenRouter / openai/gpt-4.1-mini',
        model:
            ai.AI.openRouter(apiKey: apiKey).chatModel('openai/gpt-4.1-mini'),
      );
    default:
      return null;
  }
}

String _providerLabel(String providerId) {
  switch (providerId) {
    case 'openai':
      return 'OpenAI';
    case 'anthropic':
      return 'Anthropic';
    case 'google':
      return 'Google';
    case 'groq':
      return 'Groq';
    case 'deepseek':
      return 'DeepSeek';
    case 'xai':
      return 'xAI';
    case 'openrouter':
      return 'OpenRouter';
    case 'phind':
      return 'Phind';
    case 'ollama':
      return 'Ollama';
    case 'elevenlabs':
      return 'ElevenLabs';
    default:
      return providerId;
  }
}

String _capabilityLabel(legacy.LLMCapability capability) {
  switch (capability) {
    case legacy.LLMCapability.chat:
      return 'chat';
    case legacy.LLMCapability.streaming:
      return 'streaming';
    case legacy.LLMCapability.toolCalling:
      return 'tool calling';
    case legacy.LLMCapability.vision:
      return 'vision';
    case legacy.LLMCapability.reasoning:
      return 'reasoning';
    case legacy.LLMCapability.embedding:
      return 'embeddings';
    case legacy.LLMCapability.textToSpeech:
      return 'text to speech';
    case legacy.LLMCapability.speechToText:
      return 'speech to text';
    case legacy.LLMCapability.imageGeneration:
      return 'image generation';
    case legacy.LLMCapability.modelListing:
      return 'model listing';
    case legacy.LLMCapability.openaiResponses:
      return 'openai responses';
    default:
      return capability.name;
  }
}

String _truncate(String text, {int maxLength = 220}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }

  return '${normalized.substring(0, maxLength)}...';
}

const _highSignalCapabilities = [
  legacy.LLMCapability.chat,
  legacy.LLMCapability.streaming,
  legacy.LLMCapability.toolCalling,
  legacy.LLMCapability.vision,
  legacy.LLMCapability.reasoning,
  legacy.LLMCapability.embedding,
  legacy.LLMCapability.imageGeneration,
  legacy.LLMCapability.textToSpeech,
  legacy.LLMCapability.speechToText,
  legacy.LLMCapability.modelListing,
  legacy.LLMCapability.openaiResponses,
];

final class _CapabilityScenario {
  final String label;
  final Set<legacy.LLMCapability> required;

  const _CapabilityScenario({
    required this.label,
    required this.required,
  });
}

final class _SelectedModel {
  final String providerId;
  final String modelLabel;
  final core.LanguageModel model;

  const _SelectedModel({
    required this.providerId,
    required this.modelLabel,
    required this.model,
  });
}
