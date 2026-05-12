import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAICustomPart', () {
    test('parses image_generation_call content parts', () {
      final parsed = OpenAICustomPart.tryParseContentPart(
        CustomContentPart(
          kind: OpenAIImageGenerationCallCustomPart.customKind,
          data: {
            'id': 'img_1',
            'result': 'AAEC',
          },
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'itemId': 'img_1',
            },
          ),
        ),
      );

      expect(parsed, isA<OpenAIImageGenerationCallCustomPart>());
      final imagePart = parsed! as OpenAIImageGenerationCallCustomPart;
      expect(imagePart.itemId, 'img_1');
      expect(imagePart.hasImage, isTrue);
      expect(imagePart.decodeImageBytes(), [0, 1, 2]);
      expect(
        imagePart.toGeneratedFile(filename: 'result.png')?.filename,
        'result.png',
      );
    });

    test('parses partial image custom events', () {
      final parsed = OpenAICustomPart.tryParseEvent(
        CustomEvent(
          kind: OpenAIImageGenerationPartialCustomPart.customKind,
          data: {
            'item_id': 'img_1',
            'output_index': 2,
            'partial_image_b64': 'AQID',
          },
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'itemId': 'img_1',
              'outputIndex': 2,
            },
          ),
        ),
      );

      expect(parsed, isA<OpenAIImageGenerationPartialCustomPart>());
      final partial = parsed! as OpenAIImageGenerationPartialCustomPart;
      expect(partial.itemId, 'img_1');
      expect(partial.outputIndex, 2);
      expect(partial.decodeImageBytes(), [1, 2, 3]);
    });

    test('parses mcp_list_tools content parts', () {
      final parsed = OpenAICustomPart.tryParseContentPart(
        CustomContentPart(
          kind: OpenAIMcpListToolsCustomPart.customKind,
          data: {
            'id': 'mcp_tools_1',
            'server_label': 'zip1',
            'tools': [
              {
                'name': 'create_short_url',
                'description': 'Create a short URL',
              },
              {
                'name': 'get_status',
              },
            ],
          },
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'itemId': 'mcp_tools_1',
              'serverLabel': 'zip1',
            },
          ),
        ),
      );

      expect(parsed, isA<OpenAIMcpListToolsCustomPart>());
      final mcpPart = parsed! as OpenAIMcpListToolsCustomPart;
      expect(mcpPart.itemId, 'mcp_tools_1');
      expect(mcpPart.serverLabel, 'zip1');
      expect(mcpPart.toolCount, 2);
      expect(mcpPart.toolNames, ['create_short_url', 'get_status']);
      expect(mcpPart.hasError, isFalse);
    });
  });
}
