import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Google Vertex registry', () {
    test('registers google-vertex provider id', () {
      // `ai()` ensures the umbrella built-ins are registered.
      ai();
      expect(LLMProviderRegistry.isRegistered('google-vertex'), isTrue);

      final factory = LLMProviderRegistry.getFactory('google-vertex');
      expect(factory, isNotNull);
      expect(factory!.providerId, equals('google-vertex'));
    });
  });
}
