import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Google Vertex registry', () {
    test('registers vertex provider id (and legacy alias)', () {
      // `ai()` ensures the umbrella built-ins are registered.
      ai();
      expect(LLMProviderRegistry.isRegistered('vertex'), isTrue);
      expect(LLMProviderRegistry.isRegistered('google-vertex'), isTrue);

      final vertexFactory = LLMProviderRegistry.getFactory('vertex');
      expect(vertexFactory, isNotNull);
      expect(vertexFactory!.providerId, equals('vertex'));

      final factory = LLMProviderRegistry.getFactory('google-vertex');
      expect(factory, isNotNull);
      expect(factory!.providerId, equals('google-vertex'));
    });
  });
}
