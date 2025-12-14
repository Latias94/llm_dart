import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Provider-specific builder shortcuts', () {
    test('LLMBuilder.extension() stores custom keys', () {
      final builder = LLMBuilder().extension('customKey', 'customValue');
      expect(builder.currentConfig.getExtension<String>('customKey'),
          'customValue');
    });

    test('openai builder sets OpenAI-related extensions', () {
      final builder = ai().openai(
        (o) => o
            .frequencyPenalty(0.2)
            .presencePenalty(0.1)
            .seed(67890)
            .parallelToolCalls(false)
            .logprobs(true)
            .topLogprobs(3)
            .logitBias({'token1': 0.5, 'token2': -0.3}),
      );

      final config = builder.currentConfig;
      expect(config.getExtension<double>(LLMConfigKeys.frequencyPenalty), 0.2);
      expect(config.getExtension<double>(LLMConfigKeys.presencePenalty), 0.1);
      expect(config.getExtension<int>(LLMConfigKeys.seed), 67890);
      expect(
          config.getExtension<bool>(LLMConfigKeys.parallelToolCalls), isFalse);
      expect(config.getExtension<bool>(LLMConfigKeys.logprobs), isTrue);
      expect(config.getExtension<int>(LLMConfigKeys.topLogprobs), 3);
      expect(
        config.getExtension<Map<String, double>>(LLMConfigKeys.logitBias),
        equals({'token1': 0.5, 'token2': -0.3}),
      );
    });

    test('anthropic builder sets Anthropic-related extensions', () {
      final builder = ai().anthropic(
        (a) => a
            .thinkingBudgetTokens(2000)
            .interleavedThinking(false)
            .metadata({'test': 'value'}),
      );

      final config = builder.currentConfig;
      expect(
          config.getExtension<int>(LLMConfigKeys.thinkingBudgetTokens), 2000);
      expect(config.getExtension<bool>(LLMConfigKeys.interleavedThinking),
          isFalse);
      expect(
        config.getExtension<Map<String, dynamic>>(LLMConfigKeys.metadata),
        equals({'test': 'value'}),
      );
    });

    test('ollama builder sets Ollama-related extensions', () {
      final builder = ai().ollama(
        (o) => o
            .numCtx(8192)
            .numGpu(16)
            .numThread(4)
            .numa(false)
            .numBatch(256)
            .keepAlive('10m')
            .raw(false),
      );

      final config = builder.currentConfig;
      expect(config.getExtension<int>(LLMConfigKeys.numCtx), 8192);
      expect(config.getExtension<int>(LLMConfigKeys.numGpu), 16);
      expect(config.getExtension<int>(LLMConfigKeys.numThread), 4);
      expect(config.getExtension<bool>(LLMConfigKeys.numa), isFalse);
      expect(config.getExtension<int>(LLMConfigKeys.numBatch), 256);
      expect(config.getExtension<String>(LLMConfigKeys.keepAlive), '10m');
      expect(config.getExtension<bool>(LLMConfigKeys.raw), isFalse);
    });
  });
}
