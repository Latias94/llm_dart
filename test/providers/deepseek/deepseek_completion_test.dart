import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/testing.dart';
import 'package:test/test.dart';
import 'deepseek_test_utils.dart';

void main() {
  group('DeepSeekCompletion', () {
    test('complete should send prompt and map response text/usage', () async {
      final config = DeepSeekConfig(
        apiKey: 'test-key',
        model: 'deepseek-chat',
        baseUrl: 'https://api.deepseek.com/v1/',
      );

      final client = CapturingDeepSeekClient(config);
      final completion = DeepSeekCompletion(client, config);

      final request = const CompletionRequest(
        prompt: 'Hello',
        maxTokens: 32,
        temperature: 0.5,
        topP: 0.9,
        topK: 40,
        stop: ['\n'],
      );

      final response = await completion.complete(request);

      expect(client.lastEndpoint, equals('completions'));
      final body = client.lastRequestBody;
      expect(body, isNotNull);
      expect(body!['model'], equals('deepseek-chat'));
      expect(body['prompt'], equals('Hello'));
      expect(body['max_tokens'], equals(32));
      expect(body['temperature'], equals(0.5));
      expect(body['top_p'], equals(0.9));
      expect(body['top_k'], equals(40));
      expect(body['stop'], equals(['\n']));

      expect(response.text, equals('completed text'));
      expect(response.usage, isNotNull);
      expect(response.usage!.promptTokens, equals(5));
      expect(response.usage!.completionTokens, equals(10));
      expect(response.usage!.totalTokens, equals(15));
    });

    test('completeFim should map prefix/suffix correctly', () async {
      final config = DeepSeekConfig(
        apiKey: 'test-key',
        model: 'deepseek-chat',
        baseUrl: 'https://api.deepseek.com/v1/',
        maxTokens: 64,
      );

      final client = CapturingDeepSeekClient(config);
      final completion = DeepSeekCompletion(client, config);

      final response = await completion.completeFim(
        prefix: 'def add(a, b):',
        suffix: '    return result',
        temperature: 0.3,
        topP: 0.8,
        topK: 20,
        stop: const ['\n\n'],
      );

      expect(client.lastEndpoint, equals('completions'));
      final body = client.lastRequestBody;
      expect(body, isNotNull);
      expect(body!['model'], equals('deepseek-chat'));
      expect(body['prompt'], equals('def add(a, b):'));
      expect(body['suffix'], equals('    return result'));

      // Uses explicit parameter values where provided, falls back to config for others.
      expect(body['max_tokens'], equals(64));
      expect(body['temperature'], equals(0.3));
      expect(body['top_p'], equals(0.8));
      expect(body['top_k'], equals(20));
      expect(body['stop'], equals(const ['\n\n']));

      expect(response.text, equals('completed text'));
      expect(response.usage, isNotNull);
      expect(response.usage!.totalTokens, equals(15));
    });
  });
}
