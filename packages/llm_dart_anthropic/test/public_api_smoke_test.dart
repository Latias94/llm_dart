import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(registerAnthropicProvider, isNotNull);
    expect(createAnthropic, isNotNull);
    expect(anthropic, isNotNull);
  });
}
