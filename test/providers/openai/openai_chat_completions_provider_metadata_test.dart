import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI Chat Completions providerMetadata', () {
    test('namespaces metadata under providerId (openai)', () {
      final response = OpenAIChatResponse(
        {
          'id': 'chatcmpl_123',
          'model': 'gpt-4.1-mini',
          'system_fingerprint': 'fp_1',
          'choices': [
            {
              'index': 0,
              'message': {'role': 'assistant', 'content': 'hi'},
              'finish_reason': 'stop',
            }
          ],
        },
        null,
        'openai',
      );

      final metadata = response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata!.keys, contains('openai'));

      final openai = metadata['openai'] as Map<String, dynamic>;
      expect(openai['id'], equals('chatcmpl_123'));
      expect(openai['model'], equals('gpt-4.1-mini'));
      expect(openai['systemFingerprint'], equals('fp_1'));
      expect(openai['finishReason'], equals('stop'));
    });
  });
}

