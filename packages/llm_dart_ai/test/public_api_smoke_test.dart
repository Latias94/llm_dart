import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  test('public API smoke', () {
    expect(generateTextWithModel, isNotNull);
    expect(streamTextWithModel, isNotNull);
    expect(runAgentPromptText, isNotNull);
  });
}
