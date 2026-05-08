import 'package:llm_dart/builder/llm_builder.dart';
import 'package:llm_dart/models/tool_models.dart';
import 'package:llm_dart/src/compatibility/config/legacy_config_keys.dart';
import 'package:llm_dart/src/compatibility/config/legacy_provider_options.dart';
import 'package:test/test.dart';

void main() {
  group('OpenRouterBuilder', () {
    test('onlineSearch enables the audited online-intent migration flag', () {
      final builder =
          LLMBuilder().openRouter((openrouter) => openrouter.onlineSearch());
      final openRouterOptions = legacyProviderOptionsNamespace(
        builder.currentConfig,
        LegacyProviderOptionNamespaces.openrouter,
      );

      expect(
        openRouterOptions[LegacyExtensionKeys.webSearchEnabled],
        isTrue,
      );
    });

    test('jsonSchema stores structured output under OpenRouter options', () {
      const schema = StructuredOutputFormat(
        name: 'answer',
        schema: {
          'type': 'object',
          'properties': {
            'value': {'type': 'string'},
          },
        },
      );
      final builder = LLMBuilder()
          .openRouter((openrouter) => openrouter.jsonSchema(schema));
      final openRouterOptions = legacyProviderOptionsNamespace(
        builder.currentConfig,
        LegacyProviderOptionNamespaces.openrouter,
      );

      expect(
        openRouterOptions[LegacyExtensionKeys.jsonSchema],
        same(schema),
      );
    });
  });
}
