import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIBuilder providerTools integration', () {
    test('webSearchTool() writes ProviderTool as well as builtInTools', () {
      final builder = ai().openai((openai) => openai.webSearchTool());

      expect(builder.currentConfig.providerTools, isNotNull);
      expect(
        builder.currentConfig.providerTools!.map((t) => t.id).toList(),
        contains('openai.web_search_preview'),
      );
    });

    test('fileSearchTool() writes ProviderTool', () {
      final builder = ai().openai(
        (openai) => openai.fileSearchTool(vectorStoreIds: const ['vs_123']),
      );

      expect(builder.currentConfig.providerTools, isNotNull);
      expect(
        builder.currentConfig.providerTools!.map((t) => t.id).toList(),
        contains('openai.file_search'),
      );
    });

    test('computerUseTool() writes ProviderTool', () {
      final builder = ai().openai(
        (openai) => openai.computerUseTool(
          displayWidth: 1024,
          displayHeight: 768,
          environment: 'browser',
        ),
      );

      expect(builder.currentConfig.providerTools, isNotNull);
      expect(
        builder.currentConfig.providerTools!.map((t) => t.id).toList(),
        contains('openai.computer_use_preview'),
      );
    });
  });
}
