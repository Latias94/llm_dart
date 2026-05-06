import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_options.dart';

const List<String> _anthropicNativeToolFamilies = [
  'web_search',
  'code_execution',
  'tool_search_tool_regex',
  'tool_search_tool_bm25',
];

ModelCapabilityProfile describeAnthropicChatModel(
  String modelId, {
  AnthropicChatModelSettings settings = const AnthropicChatModelSettings(),
}) {
  final deferredToolNames = _normalizeToolNames(settings.deferredToolNames);

  return ModelCapabilityProfile(
    providerId: 'anthropic',
    modelId: modelId,
    kind: ModelCapabilityKind.language,
    sharedFeatures: const [
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageStreaming,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageTextInput,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageImageInput,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageFileInput,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageFunctionTools,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageToolChoice,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageReasoningOutput,
      ),
      CapabilityDescriptor(
        id: ModelCapabilityFeatureIds.languageSourceOutput,
      ),
    ],
    providerFeatures: [
      const ProviderFeatureDescriptor(
        providerId: 'anthropic',
        featureId: 'api.route',
        detail: 'messages',
      ),
      ProviderFeatureDescriptor(
        providerId: 'anthropic',
        featureId: 'anthropic.nativeTools',
        detail: {
          'builtInTools': _anthropicNativeToolFamilies,
          'configuredTools': [
            for (final tool in settings.tools) tool.name,
          ],
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'anthropic',
        featureId: 'anthropic.thinking',
        detail: {
          'extendedThinking': true,
          'interleavedThinking': true,
          'defaultBudgetTokens': 1024,
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'anthropic',
        featureId: 'anthropic.mcpServers',
        detail: {
          'configuration': true,
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'anthropic',
        featureId: 'anthropic.citations',
        detail: {
          'resultSurface': 'sources',
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'anthropic',
        featureId: 'anthropic.toolChoiceGuardrails',
        detail: {
          'specificCommonToolsOnly': true,
          'thinkingCompatibleModes': ['auto', 'none'],
        },
      ),
      const ProviderFeatureDescriptor(
        providerId: 'anthropic',
        featureId: 'anthropic.toolCacheControl',
        detail: {
          'supported': true,
        },
      ),
      if (deferredToolNames.isNotEmpty)
        ProviderFeatureDescriptor(
          providerId: 'anthropic',
          featureId: 'anthropic.deferredToolLoading',
          detail: {
            'configuredToolNames': deferredToolNames,
          },
        ),
      if (settings.betaFeatures.isNotEmpty)
        ProviderFeatureDescriptor(
          providerId: 'anthropic',
          featureId: 'anthropic.requestBetas',
          detail: {
            'defaultBetas': List<String>.unmodifiable(settings.betaFeatures),
          },
        ),
    ],
  );
}

List<String> _normalizeToolNames(List<String> names) {
  final normalized = <String>{};
  for (final name in names) {
    final value = name.trim();
    if (value.isNotEmpty) {
      normalized.add(value);
    }
  }

  return normalized.toList(growable: false)..sort();
}
