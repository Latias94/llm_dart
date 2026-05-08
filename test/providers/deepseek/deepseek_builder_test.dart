import 'package:llm_dart/builder/llm_builder.dart';
import 'package:llm_dart/providers/deepseek/deepseek.dart';
import 'package:llm_dart/src/compatibility/config/legacy_config_keys.dart';
import 'package:llm_dart/src/compatibility/config/legacy_provider_options.dart';
import 'package:test/test.dart';

void main() {
  group('DeepSeekBuilder', () {
    test('stores callback options under namespaced providerOptions', () {
      final builder = LLMBuilder().deepseek(
        (deepseek) => deepseek
            .logprobs(true)
            .topLogprobs(3)
            .frequencyPenalty(0.1)
            .presencePenalty(0.2)
            .responseFormat({'type': 'json_object'}),
      );
      final deepSeekOptions = legacyProviderOptionsNamespace(
        builder.currentConfig,
        LegacyProviderOptionNamespaces.deepseek,
      );

      expect(deepSeekOptions[LegacyExtensionKeys.logprobs], isTrue);
      expect(deepSeekOptions[LegacyExtensionKeys.deepSeekTopLogprobs], 3);
      expect(
        deepSeekOptions[LegacyExtensionKeys.deepSeekFrequencyPenalty],
        0.1,
      );
      expect(
        deepSeekOptions[LegacyExtensionKeys.deepSeekPresencePenalty],
        0.2,
      );
      expect(deepSeekOptions[LegacyExtensionKeys.deepSeekResponseFormat], {
        'type': 'json_object',
      });
    });

    test('builds provider from namespaced callback options', () async {
      final provider = await LLMBuilder()
          .deepseek(
            (deepseek) => deepseek
                .logprobs(true)
                .topLogprobs(2)
                .responseFormat({'type': 'json_object'}),
          )
          .apiKey('test-key')
          .model('deepseek-chat')
          .build();

      expect(provider, isA<DeepSeekProvider>());

      final deepSeekProvider = provider as DeepSeekProvider;
      expect(deepSeekProvider.config.logprobs, isTrue);
      expect(deepSeekProvider.config.topLogprobs, 2);
      expect(deepSeekProvider.config.responseFormat, {
        'type': 'json_object',
      });
    });
  });
}
