import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    final builder = LLMBuilder();
    expect(builder, isA<LLMBuilder>());
    final message = ChatPromptBuilder.user().text('hi').build();
    expect(message, isNotNull);
  });
}
