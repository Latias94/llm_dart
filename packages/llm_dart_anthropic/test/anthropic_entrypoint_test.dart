import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic;
import 'package:test/test.dart';

void main() {
  group('Anthropic package entrypoint', () {
    test('exposes short provider factory without the root package', () {
      final provider = anthropic.anthropic(apiKey: 'test-key');
      final model = provider.chatModel('claude-sonnet-4-5');

      expect(provider, isA<anthropic.Anthropic>());
      expect(model.providerId, 'anthropic');
      expect(model.modelId, 'claude-sonnet-4-5');
    });
  });
}
