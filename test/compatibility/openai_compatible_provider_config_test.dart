import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/core/config.dart';
import 'package:llm_dart/src/compatibility/config/legacy_config_keys.dart';
import 'package:llm_dart/src/compatibility/config/legacy_provider_options.dart';
import 'package:llm_dart/src/compatibility/google_openai_transformers.dart';
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

  group('Google OpenAI-compatible transformers', () {
    test('writes thinking config under extra_body.config', () {
      final config = _googleCompatConfig(
        providerOptions: {
          LegacyExtensionKeys.includeThoughts: true,
          LegacyExtensionKeys.thinkingBudgetTokens: 256,
        },
      );

      final transformed = const GoogleRequestBodyTransformer().transform(
        {'model': 'gemini-2.0-flash'},
        config,
        _providerConfig,
      );

      expect(transformed['extra_body'], {
        'config': {
          'thinkingConfig': {
            'includeThoughts': true,
            'thinkingBudget': 256,
          },
        },
      });
    });
  });
}

const _providerConfig = OpenAICompatibleProviderConfig(
  providerId: 'google-openai',
  displayName: 'Google Gemini',
  description: 'Google OpenAI-compatible test profile',
  defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/',
  defaultModel: 'gemini-2.0-flash',
  supportedCapabilities: {LLMCapability.chat},
);

LLMConfig _googleCompatConfig({
  required Map<String, dynamic> providerOptions,
}) {
  return LLMConfig(
    apiKey: 'test-key',
    baseUrl: _providerConfig.defaultBaseUrl,
    model: _providerConfig.defaultModel,
    extensions: {
      legacyProviderOptionsBagKey: {
        LegacyProviderOptionNamespaces.google: providerOptions,
      },
    },
  );
}
