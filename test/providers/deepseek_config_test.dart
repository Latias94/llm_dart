import 'package:test/test.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/deepseek.dart';

void main() {
  group('DeepSeekConfig.fromLLMConfig providerOptions mapping', () {
    test('reads canonical keys from providerOptions', () {
      final config = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
        providerOptions: const {
          'deepseek': {
            'logprobs': true,
            'topLogprobs': 5,
            'frequencyPenalty': 0.2,
            'presencePenalty': 0.1,
            'responseFormat': {'type': 'json_object'},
          },
        },
      );

      final deepseek = DeepSeekConfig.fromLLMConfig(config);

      expect(deepseek.logprobs, isTrue);
      expect(deepseek.topLogprobs, 5);
      expect(deepseek.frequencyPenalty, 0.2);
      expect(deepseek.presencePenalty, 0.1);
      expect(deepseek.responseFormat, {'type': 'json_object'});
    });

    test('does not read options from other namespaces', () {
      final config = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
        providerOptions: const {
          'openai': {
            'logprobs': true,
            'topLogprobs': 7,
            'frequencyPenalty': 0.25,
            'presencePenalty': 0.15,
            'responseFormat': {'type': 'json_object'},
          },
        },
      );

      final deepseek = DeepSeekConfig.fromLLMConfig(config);

      expect(deepseek.logprobs, isNull);
      expect(deepseek.topLogprobs, isNull);
      expect(deepseek.frequencyPenalty, isNull);
      expect(deepseek.presencePenalty, isNull);
      expect(deepseek.responseFormat, isNull);
    });
  });
}
