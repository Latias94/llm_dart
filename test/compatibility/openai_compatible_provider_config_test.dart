import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/core/openai_compatible_configs.dart';
import 'package:llm_dart/src/compatibility/openai_compatible_provider_config.dart';
import 'package:test/test.dart';

void main() {
  group('ModelCapabilityConfig', () {
    test('should create with default values', () {
      final config = ModelCapabilityConfig();

      expect(config.supportsReasoning, isFalse);
      expect(config.supportsVision, isFalse);
      expect(config.supportsToolCalling, isTrue);
      expect(config.maxContextLength, isNull);
      expect(config.disableTemperature, isFalse);
      expect(config.disableTopP, isFalse);
    });

    test('should create with custom values', () {
      final config = ModelCapabilityConfig(
        supportsReasoning: true,
        supportsVision: true,
        supportsToolCalling: true,
        maxContextLength: 32768,
        disableTemperature: true,
        disableTopP: true,
      );

      expect(config.supportsReasoning, isTrue);
      expect(config.supportsVision, isTrue);
      expect(config.supportsToolCalling, isTrue);
      expect(config.maxContextLength, equals(32768));
      expect(config.disableTemperature, isTrue);
      expect(config.disableTopP, isTrue);
    });
  });

  group('OpenAICompatibleProviderConfig', () {
    test('should prefer explicit default capabilities', () {
      final config = OpenAICompatibleProviderConfig(
        providerId: 'test-provider',
        displayName: 'Test Provider',
        description: 'Test description',
        defaultBaseUrl: 'https://api.test.com',
        defaultModel: 'test-model',
        supportedCapabilities: {
          LLMCapability.chat,
          LLMCapability.streaming,
        },
        defaultCapabilities: {
          LLMCapability.chat,
        },
      );

      expect(
        config.effectiveDefaultCapabilities,
        equals({
          LLMCapability.chat,
        }),
      );
    });

    test('should fall back to supported capabilities', () {
      final config = OpenAICompatibleProviderConfig(
        providerId: 'test-provider',
        displayName: 'Test Provider',
        description: 'Test description',
        defaultBaseUrl: 'https://api.test.com',
        defaultModel: 'test-model',
        supportedCapabilities: {
          LLMCapability.chat,
          LLMCapability.streaming,
        },
      );

      expect(
        config.effectiveDefaultCapabilities,
        equals({
          LLMCapability.chat,
          LLMCapability.streaming,
        }),
      );
    });
  });

  group('OpenAICompatibleConfigs', () {
    test('exposes only compatible presets without dedicated providers', () {
      final providerIds = OpenAICompatibleConfigs.getAllConfigs()
          .map((config) => config.providerId)
          .toSet();

      expect(providerIds, {
        'openrouter',
        'github-copilot',
        'together-ai',
      });
      expect(providerIds, isNot(contains('deepseek-openai')));
      expect(providerIds, isNot(contains('google-openai')));
      expect(providerIds, isNot(contains('xai-openai')));
      expect(providerIds, isNot(contains('groq-openai')));
      expect(providerIds, isNot(contains('phind-openai')));
    });

    test('keeps explicit generic endpoint presets available', () {
      expect(
        OpenAICompatibleConfigs.getConfig('together-ai')?.defaultModel,
        'meta-llama/Llama-3-70b-chat-hf',
      );
      expect(
        OpenAICompatibleConfigs.isOpenAICompatible('deepseek-openai'),
        isFalse,
      );
    });
  });
}
