import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(OpenAICompatibleConfig.new, isNotNull);
    expect(OpenAICompatibleConfigs, isNotNull);
    expect(OpenAICompatibleProviderRegistrar, isNotNull);
  });
}
