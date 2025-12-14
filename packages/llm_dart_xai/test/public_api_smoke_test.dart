import 'package:llm_dart_xai/llm_dart_xai.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(registerXAIProvider, isNotNull);
    expect(createXAI, isNotNull);
    expect(xai, isNotNull);
  });
}
