import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI provider-defined tools helpers', () {
    test('webSearch() creates openai.web_search spec', () {
      final openai = createOpenAI(apiKey: 'test-key');

      final spec = openai.providerTools.webSearch(
        allowedDomains: const ['example.com'],
        contextSize: WebSearchContextSize.medium,
      );

      expect(spec.id, equals('openai.web_search'));
      expect(spec.args['allowedDomains'], equals(['example.com']));
      expect(spec.args['contextSize'], equals(WebSearchContextSize.medium));
    });

    test('fileSearch() creates openai.file_search spec', () {
      final openai = createOpenAI(apiKey: 'test-key');

      final spec = openai.providerTools.fileSearch(
        vectorStoreIds: const ['vs_1'],
        maxNumResults: 5,
        filters: const {'tag': 'docs'},
      );

      expect(spec.id, equals('openai.file_search'));
      expect(spec.args['vectorStoreIds'], equals(['vs_1']));
      expect(spec.args['maxNumResults'], equals(5));
      expect(spec.args['filters'], equals({'tag': 'docs'}));
    });

    test('codeInterpreter() creates openai.code_interpreter spec', () {
      final openai = createOpenAI(apiKey: 'test-key');

      final spec = openai.providerTools.codeInterpreter(
        parameters: const {'runtime': 'python'},
      );

      expect(spec.id, equals('openai.code_interpreter'));
      expect(spec.args['parameters'], equals({'runtime': 'python'}));
    });

    test('imageGeneration() creates openai.image_generation spec', () {
      final openai = createOpenAI(apiKey: 'test-key');

      final spec = openai.providerTools.imageGeneration(
        model: 'gpt-image-1',
        parameters: const {'size': '1024x1024'},
      );

      expect(spec.id, equals('openai.image_generation'));
      expect(spec.args['model'], equals('gpt-image-1'));
      expect(spec.args['parameters'], equals({'size': '1024x1024'}));
    });
  });
}

