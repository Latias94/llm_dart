import 'package:llm_dart/core/config.dart';
import 'package:llm_dart/core/web_search.dart';
import 'package:llm_dart/providers/factories/openai_compatible_factory.dart';
import 'package:llm_dart/providers/factories/openai_factory.dart';
import 'package:llm_dart/providers/openai/openai.dart';
import 'package:llm_dart/src/compatibility/compat_providers.dart';
import 'package:llm_dart/src/config/legacy_config_keys.dart';
import 'package:llm_dart/src/config/legacy_provider_options.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIProviderFactory Tests', () {
    late OpenAIProviderFactory factory;

    setUp(() {
      factory = OpenAIProviderFactory();
    });

    test('should read namespaced OpenAI providerOptions', () {
      final config = LLMConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        extensions: {
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.openai: {
              LegacyExtensionKeys.useResponsesApi: true,
              LegacyExtensionKeys.previousResponseId: 'resp_123',
              LegacyExtensionKeys.builtInTools: [
                OpenAIBuiltInTools.webSearch(),
              ],
            },
          },
        },
      );

      final provider = factory.create(config) as OpenAIProvider;

      expect(provider, isA<CompatOpenAIProvider>());
      expect(provider.config.useResponsesAPI, isTrue);
      expect(provider.config.previousResponseId, equals('resp_123'));
      expect(provider.config.builtInTools, hasLength(1));
    });

    test('should fall back to flat OpenAI compatibility extensions', () {
      final config = LLMConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-4o',
        extensions: {
          LegacyExtensionKeys.useResponsesApi: true,
          LegacyExtensionKeys.previousResponseId: 'resp_flat',
        },
      );

      final provider = factory.create(config) as OpenAIProvider;

      expect(provider, isA<CompatOpenAIProvider>());
      expect(provider.config.useResponsesAPI, isTrue);
      expect(provider.config.previousResponseId, equals('resp_flat'));
    });
  });

  group('OpenAICompatibleProviderFactory Tests', () {
    test('should read namespaced OpenRouter search config', () {
      final factory = OpenAICompatibleProviderFactory.createFactory(
        'openrouter',
      )!;
      final config = LLMConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://openrouter.ai/api/v1/',
        model: 'openai/gpt-4o-mini',
        extensions: {
          legacyProviderOptionsBagKey: {
            LegacyProviderOptionNamespaces.openrouter: {
              LegacyExtensionKeys.webSearchConfig: WebSearchConfig.openRouter(
                maxResults: 5,
              ),
            },
          },
        },
      );

      final provider = factory.create(config) as OpenAIProvider;

      expect(provider.config.model, equals('openai/gpt-4o-mini:online'));
    });
  });
}
