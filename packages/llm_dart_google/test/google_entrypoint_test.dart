import 'package:llm_dart_google/llm_dart_google.dart' as google;
import 'package:test/test.dart';

void main() {
  group('Google package entrypoint', () {
    test('exposes short provider factory without the root package', () {
      final provider = google.google(apiKey: 'test-key');
      final model = provider.chatModel('gemini-2.5-flash');

      expect(provider, isA<google.Google>());
      expect(model.providerId, 'google');
      expect(model.modelId, 'gemini-2.5-flash');
    });
  });
}
