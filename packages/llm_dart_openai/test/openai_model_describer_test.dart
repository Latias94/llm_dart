import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI model describers', () {
    test('describeOpenAIChatModel describes the default Responses-first path',
        () {
      final profile = describeOpenAIChatModel('gpt-5.4');

      expect(profile.providerId, 'openai');
      expect(profile.kind, ModelCapabilityKind.language);
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStreaming),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageStructuredOutput),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageReasoningOutput),
        isTrue,
      );
      expect(
        profile.providerFeature('openai', 'api.route')?.detail,
        'responses',
      );
      expect(
        profile.providerFeature('openai', 'responses.nativeFeatures')?.detail,
        {
          'persistence': ['previousResponseId', 'conversation', 'store'],
          'builtInTools': [
            'webSearch',
            'fileSearch',
            'computerUse',
            'imageGeneration',
            'mcp',
            'codeInterpreter',
          ],
        },
      );
      expect(
        profile.providerFeature('openai', 'modelCapabilities')?.detail,
        {
          'isReasoningModel': true,
          'systemMessageMode': 'developer',
          'supportsFlexProcessing': true,
          'supportsPriorityProcessing': true,
          'supportsNonReasoningParameters': true,
        },
      );
    });

    test('describeOpenAIChatModel aligns GPT-5 family predicates', () {
      final gpt55 = describeOpenAIChatModel('gpt-5.5');
      final gpt5Chat = describeOpenAIChatModel('gpt-5-chat-latest');
      final gpt51Chat = describeOpenAIChatModel('gpt-5.1-chat-latest');

      expect(
        gpt55.providerFeature('openai', 'modelCapabilities')?.detail,
        {
          'isReasoningModel': true,
          'systemMessageMode': 'developer',
          'supportsFlexProcessing': true,
          'supportsPriorityProcessing': true,
          'supportsNonReasoningParameters': true,
        },
      );
      expect(
        gpt5Chat.providerFeature('openai', 'modelCapabilities')?.detail,
        {
          'isReasoningModel': false,
          'systemMessageMode': 'system',
          'supportsFlexProcessing': false,
          'supportsPriorityProcessing': false,
          'supportsNonReasoningParameters': false,
        },
      );
      expect(
        gpt51Chat.providerFeature('openai', 'modelCapabilities')?.detail,
        {
          'isReasoningModel': true,
          'systemMessageMode': 'developer',
          'supportsFlexProcessing': true,
          'supportsPriorityProcessing': true,
          'supportsNonReasoningParameters': true,
        },
      );
    });

    test('describeOpenAIChatModel reflects chat-completions-only defaults', () {
      final profile = describeOpenAIChatModel(
        'deepseek-reasoner',
        profile: const DeepSeekProfile(),
      );

      expect(profile.providerId, 'deepseek');
      expect(
        profile.providerFeature('deepseek', 'api.route')?.detail,
        'chat_completions',
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.languageReasoningOutput),
        isTrue,
      );
      expect(
        profile
            .sharedFeature(ModelCapabilityFeatureIds.languageReasoningOutput)
            ?.confidence,
        CapabilityConfidence.inferred,
      );
      expect(
        profile.providerFeature('deepseek', 'chatCompletions.audioInput'),
        isNotNull,
      );
      expect(
        profile.providerFeature('deepseek', 'deepseek.thinkTagReasoning'),
        isNotNull,
      );
    });

    test(
        'describeOpenAIChatModel tracks OpenRouter online model routing from settings',
        () {
      final profile = describeOpenAIChatModel(
        'openai/gpt-4o-mini',
        profile: const OpenRouterProfile(),
        settings: const OpenRouterChatModelSettings(
          search: OpenRouterSearchOptions.onlineModel(),
        ),
      );

      expect(
        profile
            .providerFeature('openrouter', 'openrouter.onlineModelRouting')
            ?.detail,
        {'mode': 'onlineModel'},
      );
    });

    test('describeOpenAIChatModel rejects invalid profile-specific settings',
        () {
      expect(
        () => describeOpenAIChatModel(
          'deepseek-chat',
          profile: const DeepSeekProfile(),
          settings: const OpenRouterChatModelSettings(),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('only valid for OpenRouter'),
          ),
        ),
      );
    });

    test('describeOpenAIChatModel exposes xAI live-search/source support', () {
      final profile = describeOpenAIChatModel(
        'grok-3',
        profile: const XAIProfile(),
      );

      expect(
        profile.supports(ModelCapabilityFeatureIds.languageSourceOutput),
        isTrue,
      );
      expect(
        profile.providerFeature('xai', 'xai.liveSearch')?.detail,
        {'resultSurface': 'sources'},
      );
    });

    test('describeOpenAIEmbeddingModel reflects dimensions support', () {
      final textEmbedding3 =
          describeOpenAIEmbeddingModel('text-embedding-3-large');
      final ada = describeOpenAIEmbeddingModel('text-embedding-ada-002');

      expect(textEmbedding3.kind, ModelCapabilityKind.embedding);
      expect(
        textEmbedding3.supports(ModelCapabilityFeatureIds.embeddingBatch),
        isTrue,
      );
      expect(
        textEmbedding3.supports(ModelCapabilityFeatureIds.embeddingDimensions),
        isTrue,
      );
      expect(
        ada.supports(ModelCapabilityFeatureIds.embeddingDimensions),
        isFalse,
      );
    });

    test('describeOpenAIImageModel exposes gpt-image edit support', () {
      final gptImage = describeOpenAIImageModel('gpt-image-1');
      final dalle = describeOpenAIImageModel('dall-e-3');

      expect(gptImage.kind, ModelCapabilityKind.image);
      expect(
        gptImage.supports(ModelCapabilityFeatureIds.imageEditing),
        isTrue,
      );
      expect(
        gptImage.providerFeature('openai', 'image.editOptions')?.detail,
        {
          'requestOptions': [
            'mask',
            'inputFidelity',
            'partialImages',
            'outputCompression',
          ],
        },
      );
      expect(
        gptImage.providerFeature('openai', 'image.providerOptions')?.detail,
        {
          'requestOptions': [
            'count',
            'size',
            'style',
            'quality',
            'background',
            'moderation',
            'outputFormat',
            'outputCompression',
            'responseFormat',
            'user',
          ],
        },
      );
      expect(
        dalle.supports(ModelCapabilityFeatureIds.imageEditing),
        isFalse,
      );
    });

    test('describeOpenAISpeechModel exposes speech option surface', () {
      final profile = describeOpenAISpeechModel('gpt-4o-mini-tts');

      expect(profile.kind, ModelCapabilityKind.speech);
      expect(
        profile.supports(ModelCapabilityFeatureIds.speechVoiceSelection),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.speechOutputFormat),
        isTrue,
      );
      expect(
        profile.providerFeature('openai', 'speech.providerOptions')?.detail,
        {
          'supportedOptions': [
            'outputFormat',
            'instructions',
            'speed',
          ],
        },
      );
    });

    test(
        'describeOpenAITranscriptionModel exposes transcription option surface',
        () {
      final profile =
          describeOpenAITranscriptionModel('gpt-4o-mini-transcribe');

      expect(profile.kind, ModelCapabilityKind.transcription);
      expect(
        profile.supports(ModelCapabilityFeatureIds.transcriptionLanguageHints),
        isTrue,
      );
      expect(
        profile.supports(ModelCapabilityFeatureIds.transcriptionTimestamps),
        isTrue,
      );
      expect(
        profile
            .providerFeature('openai', 'transcription.providerOptions')
            ?.detail,
        {
          'supportedOptions': [
            'include',
            'language',
            'prompt',
            'temperature',
            'responseFormat',
            'timestampGranularities',
          ],
        },
      );
    });
  });
}
