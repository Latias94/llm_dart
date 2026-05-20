// ignore_for_file: avoid_print

import 'package:llm_dart/core.dart' as core;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openrouter;
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama_pkg;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai;

void main() {
  print('Capability Profiles for App and Flutter UI Gating\n');

  final presets = <_DemoModel>[
    _DemoModel(
      label: 'OpenAI / gpt-5.4',
      recommendedUse:
          'Reasoning-first assistant with OpenAI Responses routing.',
      model: openai.openai(apiKey: 'demo-key').chatModel('gpt-5.4'),
    ),
    _DemoModel(
      label: 'OpenAI / gpt-4.1-mini',
      recommendedUse: 'General chat baseline with shared structured output.',
      model: openai.openai(apiKey: 'demo-key').chatModel('gpt-4.1-mini'),
    ),
    _DemoModel(
      label: 'xAI / grok-3',
      recommendedUse: 'Source-backed chat with shared source output.',
      model: openai.xai(apiKey: 'demo-key').chatModel('grok-3'),
    ),
    _DemoModel(
      label: 'OpenRouter / openai/gpt-4o-mini :online',
      recommendedUse: 'Provider-routed web model with online search routing.',
      model: openai
          .openRouter(
            apiKey: 'demo-key',
          )
          .chatModel(
            'openai/gpt-4o-mini',
            settings: const openrouter.OpenRouterChatModelSettings(
              search: openrouter.OpenRouterSearchOptions.onlineModel(),
            ),
          ),
    ),
    _DemoModel(
      label: 'DeepSeek / deepseek-reasoner',
      recommendedUse:
          'Reasoning model on the chat-completions-compatible path.',
      model: openai
          .deepSeek(
            apiKey: 'demo-key',
          )
          .chatModel('deepseek-reasoner'),
    ),
    _DemoModel(
      label: 'Ollama / llama3.2-vision',
      recommendedUse:
          'Local multimodal chat where image input is inferred from the model family.',
      model: ollama_pkg.Ollama().chatModel('llama3.2-vision'),
    ),
  ];

  for (final preset in presets) {
    final profile = switch (preset.model) {
      core.CapabilityDescribedModel(:final capabilityProfile) =>
        capabilityProfile,
      _ => null,
    };

    if (profile == null) {
      print('--- ${preset.label} ---');
      print('  This model does not expose a capability profile yet.');
      print('');
      continue;
    }

    final policy = _ComposerPolicy.fromProfile(profile);

    print('--- ${preset.label} ---');
    print('  Use case: ${preset.recommendedUse}');
    print('  Shared controls: ${policy.sharedControlsSummary}');
    print('  Provider-aware panels: ${policy.providerPanelsSummary}');

    _printFallbackSuggestion(
      label: 'reasoning traces',
      requiredFeatures: const [
        core.ModelCapabilityFeatureIds.languageReasoningOutput,
      ],
      selected: preset,
      presets: presets,
      profile: profile,
    );
    _printFallbackSuggestion(
      label: 'source-backed answers',
      requiredFeatures: const [
        core.ModelCapabilityFeatureIds.languageSourceOutput,
      ],
      selected: preset,
      presets: presets,
      profile: profile,
    );

    print('');
  }

  print(
    'Capability profiles stay descriptive. Final validation still belongs to '
    'provider requests, warnings, and runtime errors.',
  );
}

void _printFallbackSuggestion({
  required String label,
  required List<String> requiredFeatures,
  required _DemoModel selected,
  required List<_DemoModel> presets,
  required core.ModelCapabilityProfile profile,
}) {
  if (profile.supportsAll(requiredFeatures)) {
    print('  Fallback for $label: not needed');
    return;
  }

  final fallback = _suggestFallback(
    selected: selected,
    presets: presets,
    requiredFeatures: requiredFeatures,
  );
  final missing = _missingFeatureLabels(
    profile,
    requiredFeatures,
  ).join(', ');

  print(
    '  Fallback for $label: '
    '${fallback?.label ?? 'none available'}'
    '${missing.isEmpty ? '' : ' (missing: $missing)'}',
  );
}

_DemoModel? _suggestFallback({
  required _DemoModel selected,
  required List<_DemoModel> presets,
  required Iterable<String> requiredFeatures,
}) {
  for (final preset in presets) {
    if (identical(preset, selected)) {
      continue;
    }

    final profile = switch (preset.model) {
      core.CapabilityDescribedModel(:final capabilityProfile) =>
        capabilityProfile,
      _ => null,
    };

    if (profile == null) {
      continue;
    }

    if (profile.kind == core.ModelCapabilityKind.language &&
        profile.supportsAll(requiredFeatures)) {
      return preset;
    }
  }

  return null;
}

List<String> _missingFeatureLabels(
  core.ModelCapabilityProfile profile,
  Iterable<String> requiredFeatures,
) {
  return [
    for (final featureId in requiredFeatures)
      if (!profile.supports(featureId)) _featureLabel(featureId),
  ];
}

String _featureLabel(String featureId) {
  switch (featureId) {
    case core.ModelCapabilityFeatureIds.languageReasoningOutput:
      return 'reasoning output';
    case core.ModelCapabilityFeatureIds.languageSourceOutput:
      return 'source output';
    case core.ModelCapabilityFeatureIds.languageStructuredOutput:
      return 'structured output';
    case core.ModelCapabilityFeatureIds.languageImageInput:
      return 'image input';
    case core.ModelCapabilityFeatureIds.languageFileInput:
      return 'file input';
    default:
      return featureId;
  }
}

final class _ComposerPolicy {
  final bool canAttachImages;
  final bool canAttachFiles;
  final bool canUseStructuredOutput;
  final bool canShowReasoningPanel;
  final bool canShowSourcesPanel;
  final String? route;
  final List<String> providerPanels;

  const _ComposerPolicy({
    required this.canAttachImages,
    required this.canAttachFiles,
    required this.canUseStructuredOutput,
    required this.canShowReasoningPanel,
    required this.canShowSourcesPanel,
    required this.route,
    required this.providerPanels,
  });

  factory _ComposerPolicy.fromProfile(core.ModelCapabilityProfile profile) {
    final providerPanels = <String>[];
    final routeFeature =
        profile.providerFeature(profile.providerId, 'api.route');
    final route = routeFeature?.detail as String?;

    if (profile.providerFeature(
            profile.providerId, 'responses.nativeFeatures') !=
        null) {
      providerPanels.add('Responses lifecycle inspector');
    }
    if (profile.providerFeature(
            'openrouter', 'openrouter.onlineModelRouting') !=
        null) {
      providerPanels.add('OpenRouter online-mode badge');
    }
    if (profile.providerFeature('xai', 'xai.liveSearch') != null) {
      providerPanels.add('xAI live-search sources badge');
    }
    if (profile.providerFeature('deepseek', 'deepseek.thinkTagReasoning') !=
        null) {
      providerPanels.add('DeepSeek think-tag reasoning renderer');
    }
    if (profile.providerFeature('ollama', 'ollama.toolSelection') != null) {
      providerPanels.add('Ollama automatic tool-selection badge');
    }
    if (profile.providerFeature('ollama', 'ollama.thinking') != null) {
      providerPanels.add('Ollama thinking-toggle badge');
    }

    return _ComposerPolicy(
      canAttachImages: profile.supports(
        core.ModelCapabilityFeatureIds.languageImageInput,
      ),
      canAttachFiles: profile.supports(
        core.ModelCapabilityFeatureIds.languageFileInput,
      ),
      canUseStructuredOutput: profile.supports(
        core.ModelCapabilityFeatureIds.languageStructuredOutput,
      ),
      canShowReasoningPanel: profile.supports(
        core.ModelCapabilityFeatureIds.languageReasoningOutput,
      ),
      canShowSourcesPanel: profile.supports(
        core.ModelCapabilityFeatureIds.languageSourceOutput,
      ),
      route: route,
      providerPanels: providerPanels,
    );
  }

  String get sharedControlsSummary {
    final items = <String>[
      'image attach: ${canAttachImages ? 'on' : 'off'}',
      'file attach: ${canAttachFiles ? 'on' : 'off'}',
      'structured output: ${canUseStructuredOutput ? 'on' : 'off'}',
      'reasoning panel: ${canShowReasoningPanel ? 'on' : 'off'}',
      'sources panel: ${canShowSourcesPanel ? 'on' : 'off'}',
    ];
    return items.join(', ');
  }

  String get providerPanelsSummary {
    final items = <String>[
      if (route != null) 'route=$route',
      ...providerPanels,
    ];
    return items.isEmpty ? 'none' : items.join(', ');
  }
}

final class _DemoModel {
  final String label;
  final String recommendedUse;
  final core.LanguageModel model;

  const _DemoModel({
    required this.label,
    required this.recommendedUse,
    required this.model,
  });
}
