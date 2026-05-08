// ignore_for_file: avoid_print

import 'dart:io';

import 'package:llm_dart/builder/llm_builder.dart' as compat_builder;
import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart/core/capability.dart' as compat_core;
import 'package:llm_dart/core/registry.dart' as compat_registry;
import 'package:llm_dart/llm_dart.dart' as ai;

/// Capability detection through provider declarations.
///
/// This example intentionally separates two layers:
/// 1. registry-level capability metadata for provider selection
/// 2. stable `<provider>(...).chatModel(...)` creation for actual execution
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

  _ensureProviderDeclarationsRegistered();
  final providers = loadExampleProviderInfo();

  if (providers.isEmpty) {
    print('No provider declarations are currently registered.');
    return;
  }

  printProviderOverview(providers);
  printScenarioRecommendations(providers);
  printBoundaryGuidance();
  await demonstrateStableExecution(providers);

  print(
      'Capability detection remains advisory; stable calls remain model-first.');
}

List<compat_registry.ProviderInfo> loadExampleProviderInfo() {
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
    for (final provider
        in compat_registry.LLMProviderRegistry.getAllProviderInfo())
      provider.id: provider,
  };

  return [
    for (final providerId in providerOrder)
      if (allProviders.containsKey(providerId)) allProviders[providerId]!,
  ];
}

void printProviderOverview(List<compat_registry.ProviderInfo> providers) {
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

void printScenarioRecommendations(
    List<compat_registry.ProviderInfo> providers) {
  print('--- Scenario Recommendations ---');

  const scenarios = [
    _CapabilityScenario(
      label: 'Flutter chat baseline',
      required: {
        compat_core.LLMCapability.chat,
        compat_core.LLMCapability.streaming,
        compat_core.LLMCapability.toolCalling,
      },
    ),
    _CapabilityScenario(
      label: 'Vision-enabled chat',
      required: {
        compat_core.LLMCapability.chat,
        compat_core.LLMCapability.vision,
      },
    ),
    _CapabilityScenario(
      label: 'Reasoning-heavy workflows',
      required: {
        compat_core.LLMCapability.chat,
        compat_core.LLMCapability.reasoning,
      },
    ),
    _CapabilityScenario(
      label: 'Semantic search / RAG indexing',
      required: {
        compat_core.LLMCapability.embedding,
      },
    ),
    _CapabilityScenario(
      label: 'Speech input and output',
      required: {
        compat_core.LLMCapability.textToSpeech,
        compat_core.LLMCapability.speechToText,
      },
    ),
    _CapabilityScenario(
      label: 'Image generation',
      required: {
        compat_core.LLMCapability.imageGeneration,
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

void printBoundaryGuidance() {
  print('--- Boundary Guidance ---');

  print(
    '  Raw OpenAI response lifecycle is provider-owned, not a shared capability.',
  );
  print(
    '  Check `OpenAIProvider.supportsResponsesApi` or `provider.responses`',
  );
  print(
    '  when you explicitly need fetching, continuing, or deleting raw responses.',
  );
  print(
    '  For normal Flutter chat flows, keep using `openai(...).chatModel(...)`',
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
    List<compat_registry.ProviderInfo> providers) async {
  print('--- Stable Execution After Selection ---');

  final candidates = _providersSupportingAll(
    providers,
    const {
      compat_core.LLMCapability.chat,
      compat_core.LLMCapability.streaming,
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

List<compat_registry.ProviderInfo> _providersSupportingAll(
  List<compat_registry.ProviderInfo> providers,
  Set<compat_core.LLMCapability> required,
) {
  return providers
      .where((provider) => required.every(provider.supports))
      .toList(growable: false);
}

_SelectedModel? _selectStableModelFromEnvironment(
  List<compat_registry.ProviderInfo> candidates,
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
        model: ai.openai(apiKey: apiKey).chatModel('gpt-4.1-mini'),
      );
    case 'anthropic':
      final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'Anthropic / claude-sonnet-4-5',
        model: ai.anthropic(apiKey: apiKey).chatModel('claude-sonnet-4-5'),
      );
    case 'google':
      final apiKey = Platform.environment['GOOGLE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'Google / gemini-2.5-flash',
        model: ai.google(apiKey: apiKey).chatModel('gemini-2.5-flash'),
      );
    case 'groq':
      final apiKey = Platform.environment['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'Groq / llama-3.3-70b-versatile',
        model: ai.groq(apiKey: apiKey).chatModel('llama-3.3-70b-versatile'),
      );
    case 'deepseek':
      final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'DeepSeek / deepseek-chat',
        model: ai.deepSeek(apiKey: apiKey).chatModel('deepseek-chat'),
      );
    case 'xai':
      final apiKey = Platform.environment['XAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'xAI / grok-3',
        model: ai.xai(apiKey: apiKey).chatModel('grok-3'),
      );
    case 'openrouter':
      final apiKey = Platform.environment['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      return _SelectedModel(
        providerId: providerId,
        modelLabel: 'OpenRouter / openai/gpt-4.1-mini',
        model: ai.openRouter(apiKey: apiKey).chatModel('openai/gpt-4.1-mini'),
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

String _capabilityLabel(compat_core.LLMCapability capability) {
  switch (capability) {
    case compat_core.LLMCapability.chat:
      return 'chat';
    case compat_core.LLMCapability.streaming:
      return 'streaming';
    case compat_core.LLMCapability.toolCalling:
      return 'tool calling';
    case compat_core.LLMCapability.vision:
      return 'vision';
    case compat_core.LLMCapability.reasoning:
      return 'reasoning';
    case compat_core.LLMCapability.embedding:
      return 'embeddings';
    case compat_core.LLMCapability.textToSpeech:
      return 'text to speech';
    case compat_core.LLMCapability.speechToText:
      return 'speech to text';
    case compat_core.LLMCapability.imageGeneration:
      return 'image generation';
    case compat_core.LLMCapability.modelListing:
      return 'model listing';
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
  compat_core.LLMCapability.chat,
  compat_core.LLMCapability.streaming,
  compat_core.LLMCapability.toolCalling,
  compat_core.LLMCapability.vision,
  compat_core.LLMCapability.reasoning,
  compat_core.LLMCapability.embedding,
  compat_core.LLMCapability.imageGeneration,
  compat_core.LLMCapability.textToSpeech,
  compat_core.LLMCapability.speechToText,
  compat_core.LLMCapability.modelListing,
];

final class _CapabilityScenario {
  final String label;
  final Set<compat_core.LLMCapability> required;

  const _CapabilityScenario({
    required this.label,
    required this.required,
  });
}

void _ensureProviderDeclarationsRegistered() {
  compat_builder.LLMBuilder();
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
