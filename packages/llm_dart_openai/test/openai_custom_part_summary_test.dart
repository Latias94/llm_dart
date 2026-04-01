import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAICustomPartSummary', () {
    test('summarizes image generation payloads', () {
      final summary = OpenAICustomPartSummary.tryParseContentPart(
        CustomContentPart(
          kind: OpenAIImageGenerationCallCustomPart.customKind,
          data: {
            'id': 'img_1',
            'result': 'AAEC',
          },
        ),
      );

      expect(summary, isNotNull);
      expect(summary!.title, 'Image Generation');
      expect(summary.subtitle, 'Generated Image');
      expect(summary.previewText, 'Image available');
      expect(
        summary.fields.map((field) => '${field.label}:${field.value}'),
        contains('Item ID:img_1'),
      );
    });

    test('summarizes MCP tool discovery payloads', () {
      final summary = OpenAICustomPartSummary.tryParseUiPart(
        CustomUiPart(
          kind: OpenAIMcpListToolsCustomPart.customKind,
          data: {
            'server_label': 'zip1',
            'tools': [
              {
                'name': 'create_short_url',
              },
              {
                'name': 'get_status',
              },
            ],
          },
        ),
      );

      expect(summary, isNotNull);
      expect(summary!.title, 'zip1');
      expect(summary.subtitle, 'Available Tools');
      expect(summary.previewText, 'create_short_url, get_status');
      expect(
        summary.fields.map((field) => '${field.label}:${field.value}'),
        contains('Tool Count:2'),
      );
    });
  });
}
