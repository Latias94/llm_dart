import 'package:llm_dart/core/provider_defaults.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderDefaults', () {
    test('exposes only static endpoint/model constants for legacy root configs',
        () {
      expect(
        ProviderDefaults.openaiBaseUrl,
        equals('https://api.openai.com/v1/'),
      );
      expect(ProviderDefaults.deepseekDefaultModel, equals('deepseek-chat'));
    });
  });
}
