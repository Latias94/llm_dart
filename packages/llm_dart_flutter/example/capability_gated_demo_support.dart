import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_community/llm_dart_community.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

const sourceBackedAnswerFeatureIds = [
  ModelCapabilityFeatureIds.languageSourceOutput,
];

const reasoningInspectorFeatureIds = [
  ModelCapabilityFeatureIds.languageReasoningOutput,
];

final capabilityGatedDemoPresets = <CapabilityDemoPreset>[
  CapabilityDemoPreset(
    id: 'openai-gpt-5.4',
    label: 'OpenAI / gpt-5.4',
    description: 'Reasoning-first chat baseline with Responses routing.',
    profile: describeOpenAIChatModel('gpt-5.4'),
  ),
  CapabilityDemoPreset(
    id: 'openai-gpt-4.1-mini',
    label: 'OpenAI / gpt-4.1-mini',
    description: 'General chat baseline with shared structured output.',
    profile: describeOpenAIChatModel('gpt-4.1-mini'),
  ),
  CapabilityDemoPreset(
    id: 'xai-grok-3',
    label: 'xAI / grok-3',
    description: 'Source-aware chat using shared source output.',
    profile: describeOpenAIChatModel(
      'grok-3',
      profile: const XAIProfile(),
    ),
  ),
  CapabilityDemoPreset(
    id: 'openrouter-online',
    label: 'OpenRouter / openai/gpt-4o-mini :online',
    description: 'Provider-routed online model with native search routing.',
    profile: describeOpenAIChatModel(
      'openai/gpt-4o-mini',
      profile: const OpenRouterProfile(),
      settings: const OpenRouterChatModelSettings(
        search: OpenRouterSearchOptions.onlineModel(),
      ),
    ),
  ),
  CapabilityDemoPreset(
    id: 'deepseek-reasoner',
    label: 'DeepSeek / deepseek-reasoner',
    description: 'Reasoning model on a chat-completions-compatible route.',
    profile: describeOpenAIChatModel(
      'deepseek-reasoner',
      profile: const DeepSeekProfile(),
      settings: const OpenAIChatModelSettings(
        useResponsesApi: false,
      ),
    ),
  ),
  CapabilityDemoPreset(
    id: 'ollama-llama3.2-vision',
    label: 'Ollama / llama3.2-vision',
    description: 'Local multimodal chat with inferred image-input support.',
    profile: describeOllamaChatModel('llama3.2-vision'),
  ),
];

final class CapabilityDemoPreset {
  final String id;
  final String label;
  final String description;
  final ModelCapabilityProfile profile;

  const CapabilityDemoPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.profile,
  });
}

final class ChatComposerPolicy {
  final bool canAttachImages;
  final bool canAttachFiles;
  final bool canUseStructuredOutput;
  final bool canShowReasoningPanel;
  final bool canShowSourcesPanel;
  final String routeLabel;
  final List<String> providerBadges;

  ChatComposerPolicy({
    required this.canAttachImages,
    required this.canAttachFiles,
    required this.canUseStructuredOutput,
    required this.canShowReasoningPanel,
    required this.canShowSourcesPanel,
    required this.routeLabel,
    Iterable<String> providerBadges = const [],
  }) : providerBadges = List.unmodifiable(providerBadges);
}

ChatComposerPolicy buildChatComposerPolicy(ModelCapabilityProfile profile) {
  final providerBadges = <String>[];
  final route =
      profile.providerFeature(profile.providerId, 'api.route')?.detail;
  final routeLabel = route is String ? route : 'unknown';

  if (profile.providerFeature(profile.providerId, 'responses.nativeFeatures') !=
      null) {
    providerBadges.add('Responses lifecycle');
  }
  if (profile.providerFeature('openrouter', 'openrouter.onlineModelRouting') !=
      null) {
    providerBadges.add('OpenRouter online mode');
  }
  if (profile.providerFeature('xai', 'xai.liveSearch') != null) {
    providerBadges.add('xAI live search');
  }
  if (profile.providerFeature('deepseek', 'deepseek.thinkTagReasoning') !=
      null) {
    providerBadges.add('DeepSeek think tags');
  }
  if (profile.providerFeature('ollama', 'ollama.toolSelection') != null) {
    providerBadges.add('Ollama auto tool selection');
  }
  if (profile.providerFeature('ollama', 'ollama.thinking') != null) {
    providerBadges.add('Ollama thinking toggle');
  }

  return ChatComposerPolicy(
    canAttachImages: profile.supports(
      ModelCapabilityFeatureIds.languageImageInput,
    ),
    canAttachFiles: profile.supports(
      ModelCapabilityFeatureIds.languageFileInput,
    ),
    canUseStructuredOutput: profile.supports(
      ModelCapabilityFeatureIds.languageStructuredOutput,
    ),
    canShowReasoningPanel: profile.supports(
      ModelCapabilityFeatureIds.languageReasoningOutput,
    ),
    canShowSourcesPanel: profile.supports(
      ModelCapabilityFeatureIds.languageSourceOutput,
    ),
    routeLabel: routeLabel,
    providerBadges: providerBadges,
  );
}

CapabilityDemoPreset? suggestFallbackPreset({
  required CapabilityDemoPreset selected,
  required Iterable<CapabilityDemoPreset> candidates,
  required Iterable<String> requiredFeatures,
}) {
  if (selected.profile.supportsAll(requiredFeatures)) {
    return null;
  }

  for (final candidate in candidates) {
    if (candidate.id == selected.id) {
      continue;
    }

    if (candidate.profile.kind != selected.profile.kind) {
      continue;
    }

    if (candidate.profile.supportsAll(requiredFeatures)) {
      return candidate;
    }
  }

  return null;
}

List<String> missingSharedFeatureLabels(
  ModelCapabilityProfile profile,
  Iterable<String> requiredFeatures,
) {
  return [
    for (final featureId in requiredFeatures)
      if (!profile.supports(featureId)) capabilityFeatureLabel(featureId),
  ];
}

String capabilityFeatureLabel(String featureId) {
  switch (featureId) {
    case ModelCapabilityFeatureIds.languageImageInput:
      return 'image input';
    case ModelCapabilityFeatureIds.languageFileInput:
      return 'file input';
    case ModelCapabilityFeatureIds.languageStructuredOutput:
      return 'structured output';
    case ModelCapabilityFeatureIds.languageReasoningOutput:
      return 'reasoning output';
    case ModelCapabilityFeatureIds.languageSourceOutput:
      return 'source output';
    default:
      return featureId;
  }
}
