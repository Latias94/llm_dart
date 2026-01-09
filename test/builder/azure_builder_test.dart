import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

void main() {
  group('AzureBuilder', () {
    test('writes providerOptions for azure', () {
      final builder = ai().azure(
        (azure) => azure
            .apiVersion('2024-10-01-preview')
            .useDeploymentBasedUrls(true)
            .useResponsesAPI(false),
      );

      expect(
        builder.currentConfig.getProviderOption<String>('azure', 'apiVersion'),
        equals('2024-10-01-preview'),
      );
      expect(
        builder.currentConfig.getProviderOption<bool>(
            'azure', 'useDeploymentBasedUrls'),
        isTrue,
      );
      expect(
        builder.currentConfig.getProviderOption<bool>('azure', 'useResponsesAPI'),
        isFalse,
      );
    });

    test('provider-native tool helpers write ProviderTool ids', () {
      final builder = ai().azure(
        (azure) => azure
            .webSearchPreviewTool()
            .fileSearchTool(vectorStoreIds: const ['vs_123'])
            .codeInterpreterTool()
            .imageGenerationTool(),
      );

      final ids = builder.currentConfig.providerTools?.map((t) => t.id).toList();
      expect(ids, isNotNull);
      expect(
        ids!,
        containsAll([
          'openai.web_search_preview',
          'openai.file_search',
          'openai.code_interpreter',
          'openai.image_generation',
        ]),
      );
    });
  });
}

