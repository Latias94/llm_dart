import 'package:llm_dart/providers/google/google.dart';
import 'package:test/test.dart';

void main() {
  group('Google provider barrel', () {
    test('exports the focused Google compatibility surface', () {
      const builderType = GoogleLLMBuilder;

      final provider = GoogleProvider(
        const GoogleConfig(
          apiKey: 'test-key',
          model: 'gemini-2.5-flash',
        ),
      );

      expect(builderType, equals(GoogleLLMBuilder));
      expect(provider, isA<GoogleProvider>());
      expect(provider.config.model, 'gemini-2.5-flash');
    });
  });
}
