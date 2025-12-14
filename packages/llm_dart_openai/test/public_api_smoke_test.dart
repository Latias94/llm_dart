import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(registerOpenAIProvider, isNotNull);
    expect(createOpenAI, isNotNull);
    expect(openai, isNotNull);
  });
}
