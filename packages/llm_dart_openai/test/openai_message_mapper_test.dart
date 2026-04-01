import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIMessageMapper', () {
    test('maps custom OpenAI UI parts and provider metadata', () {
      final message = ChatUiMessage(
        id: 'msg_1',
        role: ChatUiRole.assistant,
        parts: const [
          CustomUiPart(
            kind: OpenAIMcpListToolsCustomPart.customKind,
            data: {
              'id': 'mcp_tools_1',
              'server_label': 'zip1',
              'tools': [
                {'name': 'create_short_url'},
              ],
            },
          ),
        ],
        metadata: {
          ChatUiMetadataKeys.responseProviderMetadata: ProviderMetadata({
            'openai': {
              'serviceTier': 'default',
            },
          }),
          ChatUiMetadataKeys.finishProviderMetadata: ProviderMetadata({
            'openai': {
              'status': 'completed',
            },
          }),
        },
      );

      final mapped = const OpenAIMessageMapper().map(message);

      expect(mapped.customParts, hasLength(1));
      expect(mapped.customParts.single, isA<OpenAIMcpListToolsCustomPart>());
      expect(mapped.customPartSummaries, hasLength(1));
      expect(mapped.customPartSummaries.single.subtitle, 'Available Tools');
      expect(mapped.responseMetadata, containsPair('serviceTier', 'default'));
      expect(mapped.finishMetadata, containsPair('status', 'completed'));
      expect(mapped.hasOpenAIMetadata, isTrue);
    });
  });
}
