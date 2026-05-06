import 'package:llm_dart/builder/llm_builder.dart';
import 'package:test/test.dart';

void main() {
  group('OpenRouterBuilder', () {
    test('onlineSearch enables the audited online-intent migration flag', () {
      final builder =
          LLMBuilder().openRouter((openrouter) => openrouter.onlineSearch());

      expect(
        builder.currentConfig.getExtension<bool>('webSearchEnabled'),
        isTrue,
      );
    });
  });
}
