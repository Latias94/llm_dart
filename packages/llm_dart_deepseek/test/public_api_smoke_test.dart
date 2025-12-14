import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(registerDeepSeekProvider, isNotNull);
    expect(createDeepSeek, isNotNull);
    expect(deepseek, isNotNull);
  });
}
