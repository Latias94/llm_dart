import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    final config = LLMConfig(baseUrl: 'https://example.com', model: 'test');
    final updated = config.withKey(LLMConfigTypedKeys.metadata, {'a': 1});
    expect(updated.getKey(LLMConfigTypedKeys.metadata)?['a'], 1);
    expect(LLMProviderRegistry.getRegisteredProviders(), isA<List<String>>());
  });
}
