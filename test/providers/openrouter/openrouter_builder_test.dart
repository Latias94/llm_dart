import 'package:llm_dart/builder/llm_builder.dart';
import 'package:llm_dart/src/compatibility/config/legacy_config_keys.dart';
import 'package:test/test.dart';

void main() {
  group('OpenRouterBuilder', () {
    test('onlineSearch enables the audited online-intent migration flag', () {
      final builder =
          LLMBuilder().openRouter((openrouter) => openrouter.onlineSearch());

      expect(
        builder.currentConfig.getExtension<bool>(
          LegacyExtensionKeys.webSearchEnabled,
        ),
        isTrue,
      );
    });
  });
}
