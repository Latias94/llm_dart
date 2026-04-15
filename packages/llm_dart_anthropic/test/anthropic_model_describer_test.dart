import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic model describers', () {
    test('describeAnthropicChatModel describes the Messages surface', () {
      final profile = describeAnthropicChatModel(
        'claude-sonnet-4-5',
        settings: const AnthropicChatModelSettings(
          betaFeatures: ['tools-2024-04-04'],
          tools: [
            AnthropicCodeExecutionTool20260120(),
          ],
          deferredToolNames: ['weather', '', 'weather'],
        ),
      );

      expect(profile.providerId, 'anthropic');
      expect(profile.kind, ModelCapabilityKind.language);
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStreaming),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageImageInput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageFileInput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageFunctionTools),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageToolChoice),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageReasoningOutput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageSourceOutput),
        isTrue,
      );
      expect(
        profile.providerFeature('anthropic', 'api.route')?.detail,
        'messages',
      );
      expect(
        profile.providerFeature('anthropic', 'anthropic.nativeTools')?.detail,
        {
          'builtInTools': [
            'web_search',
            'code_execution',
            'tool_search_tool_regex',
            'tool_search_tool_bm25',
          ],
          'configuredTools': ['code_execution'],
        },
      );
      expect(
        profile
            .providerFeature('anthropic', 'anthropic.deferredToolLoading')
            ?.detail,
        {
          'configuredToolNames': ['weather'],
        },
      );
      expect(
        profile.providerFeature('anthropic', 'anthropic.requestBetas')?.detail,
        {
          'defaultBetas': ['tools-2024-04-04'],
        },
      );
      expect(
        profile
            .providerFeature('anthropic', 'anthropic.toolChoiceGuardrails')
            ?.detail,
        {
          'specificCommonToolsOnly': true,
          'thinkingCompatibleModes': ['auto', 'none'],
        },
      );
    });
  });
}
