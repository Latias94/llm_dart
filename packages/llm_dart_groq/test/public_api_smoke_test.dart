import 'package:llm_dart_groq/llm_dart_groq.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(registerGroqProvider, isNotNull);
    expect(createGroq, isNotNull);
    expect(groq, isNotNull);
  });
}
