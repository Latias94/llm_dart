import 'package:test/test.dart';
import 'package:llm_dart/llm_dart.dart';

void main() {
  group('ProviderConfig', () {
    late ProviderConfig config;

    setUp(() {
      config = ProviderConfig();
    });

    test('creates empty configuration by default', () {
      final result = config.build();
      expect(result, isEmpty);
    });

    group('Provider selection methods', () {
      test('openai() returns self for chaining', () {
        final result = config.openai();
        expect(identical(result, config), isTrue);
      });

      test('anthropic() returns self for chaining', () {
        final result = config.anthropic();
        expect(identical(result, config), isTrue);
      });

      test('ollama() returns self for chaining', () {
        final result = config.ollama();
        expect(identical(result, config), isTrue);
      });
    });

    group('Generic extension method', () {
      test('extension() adds key-value pair', () {
        config.extension('customKey', 'customValue');
        final result = config.build();
        expect(result['customKey'], equals('customValue'));
      });

      test('extension() supports different value types', () {
        config
            .extension('stringValue', 'test')
            .extension('intValue', 42)
            .extension('doubleValue', 3.14)
            .extension('boolValue', true)
            .extension('mapValue', {'nested': 'value'}).extension(
                'listValue', [1, 2, 3]);

        final result = config.build();
        expect(result['stringValue'], equals('test'));
        expect(result['intValue'], equals(42));
        expect(result['doubleValue'], equals(3.14));
        expect(result['boolValue'], isTrue);
        expect(result['mapValue'], equals({'nested': 'value'}));
        expect(result['listValue'], equals([1, 2, 3]));
      });
    });

    group('OpenAI-specific configuration', () {
      test('frequencyPenalty() sets frequency penalty', () {
        config.frequencyPenalty(0.5);
        final result = config.build();
        expect(result['frequencyPenalty'], equals(0.5));
      });

      test('presencePenalty() sets presence penalty', () {
        config.presencePenalty(0.3);
        final result = config.build();
        expect(result['presencePenalty'], equals(0.3));
      });

      test('logitBias() sets logit bias', () {
        final bias = {'token1': 0.5, 'token2': -0.3};
        config.logitBias(bias);
        final result = config.build();
        expect(result['logitBias'], equals(bias));
      });

      test('seed() sets seed value', () {
        config.seed(12345);
        final result = config.build();
        expect(result['seed'], equals(12345));
      });

      test('parallelToolCalls() enables parallel tool calls', () {
        config.parallelToolCalls(true);
        final result = config.build();
        expect(result['parallelToolCalls'], isTrue);
      });

      test('logprobs() enables logprobs', () {
        config.logprobs(true);
        final result = config.build();
        expect(result['logprobs'], isTrue);
      });

      test('topLogprobs() sets top logprobs count', () {
        config.topLogprobs(5);
        final result = config.build();
        expect(result['topLogprobs'], equals(5));
      });

      test('OpenAI configuration chaining', () {
        final result = config
            .openai()
            .frequencyPenalty(0.2)
            .presencePenalty(0.1)
            .seed(67890)
            .parallelToolCalls(false)
            .logprobs(true)
            .topLogprobs(3)
            .build();

        expect(result['frequencyPenalty'], equals(0.2));
        expect(result['presencePenalty'], equals(0.1));
        expect(result['seed'], equals(67890));
        expect(result['parallelToolCalls'], isFalse);
        expect(result['logprobs'], isTrue);
        expect(result['topLogprobs'], equals(3));
      });
    });

    group('Anthropic-specific configuration', () {
      test('reasoning() enables reasoning', () {
        config.reasoning(true);
        final result = config.build();
        expect(result['reasoning'], isTrue);
      });

      test('thinkingBudgetTokens() sets thinking budget tokens', () {
        config.thinkingBudgetTokens(1000);
        final result = config.build();
        expect(result['thinkingBudgetTokens'], equals(1000));
      });

      test('interleavedThinking() enables interleaved thinking', () {
        config.interleavedThinking(true);
        final result = config.build();
        expect(result['interleavedThinking'], isTrue);
      });

      test('metadata() sets metadata', () {
        final metadata = {'userId': '123', 'sessionId': 'abc'};
        config.metadata(metadata);
        final result = config.build();
        expect(result['metadata'], equals(metadata));
      });

      test('Anthropic configuration chaining', () {
        final metadata = {'test': 'value'};
        final result = config
            .anthropic()
            .reasoning(true)
            .thinkingBudgetTokens(2000)
            .interleavedThinking(false)
            .metadata(metadata)
            .build();

        expect(result['reasoning'], isTrue);
        expect(result['thinkingBudgetTokens'], equals(2000));
        expect(result['interleavedThinking'], isFalse);
        expect(result['metadata'], equals(metadata));
      });
    });

    group('Ollama-specific configuration', () {
      test('numCtx() sets context length', () {
        config.numCtx(4096);
        final result = config.build();
        expect(result['numCtx'], equals(4096));
      });

      test('numGpu() sets GPU layers', () {
        config.numGpu(32);
        final result = config.build();
        expect(result['numGpu'], equals(32));
      });

      test('numThread() sets thread count', () {
        config.numThread(8);
        final result = config.build();
        expect(result['numThread'], equals(8));
      });

      test('numa() enables NUMA', () {
        config.numa(true);
        final result = config.build();
        expect(result['numa'], isTrue);
      });

      test('numBatch() sets batch size', () {
        config.numBatch(512);
        final result = config.build();
        expect(result['numBatch'], equals(512));
      });

      test('keepAlive() sets keep alive duration', () {
        config.keepAlive('5m');
        final result = config.build();
        expect(result['keepAlive'], equals('5m'));
      });

      test('raw() enables raw mode', () {
        config.raw(true);
        final result = config.build();
        expect(result['raw'], isTrue);
      });

      test('Ollama configuration chaining', () {
        final result = config
            .ollama()
            .numCtx(8192)
            .numGpu(16)
            .numThread(4)
            .numa(false)
            .numBatch(256)
            .keepAlive('10m')
            .raw(false)
            .build();

        expect(result['numCtx'], equals(8192));
        expect(result['numGpu'], equals(16));
        expect(result['numThread'], equals(4));
        expect(result['numa'], isFalse);
        expect(result['numBatch'], equals(256));
        expect(result['keepAlive'], equals('10m'));
        expect(result['raw'], isFalse);
      });
    });

    test('build() returns a copy of the configuration', () {
      config.extension('test', 'value');
      final result1 = config.build();
      final result2 = config.build();

      expect(identical(result1, result2), isFalse);
      expect(result1, equals(result2));
    });

    test('mixed provider configurations', () {
      final result = config
          .frequencyPenalty(0.1) // OpenAI
          .reasoning(true) // Anthropic
          .numCtx(4096) // Ollama
          .extension('custom', 'value') // Generic
          .build();

      expect(result['frequencyPenalty'], equals(0.1));
      expect(result['reasoning'], isTrue);
      expect(result['numCtx'], equals(4096));
      expect(result['custom'], equals('value'));
    });

    group('LLMBuilder Integration', () {
      test('providerConfig() merges into providerOptions for current provider',
          () {
        final builder = LLMBuilder()
            .provider('ollama')
            .providerConfig((p) => p.numCtx(4096).keepAlive('5m'));

        expect(
          builder.currentConfig.getProviderOption<int>('ollama', 'numCtx'),
          equals(4096),
        );
        expect(
          builder.currentConfig
              .getProviderOption<String>('ollama', 'keepAlive'),
          equals('5m'),
        );
      });

      test('providerConfig() throws when provider not selected', () {
        expect(
          () => LLMBuilder().providerConfig((p) => p.numCtx(4096)),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
