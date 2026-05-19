import 'package:llm_dart_anthropic/src/anthropic_result_tool_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic result tool projection', () {
    test('projects common tool use parts', () {
      final projected = projectAnthropicResultToolUsePart({
        'type': 'tool_use',
        'id': 'toolu_1',
        'name': 'weather',
        'input': {
          'city': 'Hong Kong',
        },
        'caller': {
          'type': 'direct',
        },
      });

      expect(projected?.toolCallId, 'toolu_1');
      expect(projected?.toolName, 'weather');
      expect(projected?.input, {
        'city': 'Hong Kong',
      });
      expect(projected?.content.providerExecuted, isFalse);
      expect(projected?.contentPart.providerMetadata?.values['anthropic'], {
        'caller': {
          'type': 'direct',
        },
      });
    });

    test('projects MCP tool use parts with dynamic provider execution', () {
      final projected = projectAnthropicResultMcpToolUsePart({
        'type': 'mcp_tool_use',
        'id': 'mcptoolu_1',
        'name': 'search',
        'server_name': 'workspace',
        'input': {
          'query': 'dart sdk',
        },
      });

      expect(projected?.toolName, 'mcp.search');
      expect(projected?.providerExecuted, isTrue);
      expect(projected?.isDynamic, isTrue);
      expect(projected?.title, 'workspace');
      expect(projected?.contentPart.providerMetadata?.values['anthropic'], {
        'serverName': 'workspace',
      });
    });

    test('projects web search tool result parts and sources', () {
      final descriptorMetadata = ProviderMetadata.forNamespace('anthropic', {
        'providerToolName': 'web_search',
      });
      final parts = projectAnthropicResultToolResultParts(
        blockType: 'web_search_tool_result',
        block: {
          'type': 'web_search_tool_result',
          'tool_use_id': 'srvtoolu_1',
          'content': [
            {
              'url': 'https://dart.dev',
              'title': 'Dart',
              'type': 'web_search_result',
              'page_age': '1d',
            },
          ],
        },
        descriptorProviderMetadata: descriptorMetadata,
        descriptorToolName: 'web_search',
        descriptorIsDynamic: true,
      ).toList();

      expect(parts[0], isA<ToolResultContentPart>());
      expect(parts[1], isA<CustomContentPart>());
      expect(parts[2], isA<SourceContentPart>());

      final resultPart = parts[0] as ToolResultContentPart;
      expect(resultPart.toolResult.toolCallId, 'srvtoolu_1');
      expect(resultPart.toolResult.toolName, 'web_search');
      expect(resultPart.toolResult.isDynamic, isTrue);
      expect(resultPart.providerMetadata?.values['anthropic'], {
        'providerToolName': 'web_search',
        'partType': 'web_search_tool_result',
      });

      final customPart = parts[1] as CustomContentPart;
      expect(customPart.kind, 'anthropic.result.web_search');
      expect(customPart.providerMetadata, resultPart.providerMetadata);

      final sourcePart = parts[2] as SourceContentPart;
      expect(sourcePart.source.sourceId, 'https://dart.dev');
      expect(sourcePart.source.title, 'Dart');
      expect(sourcePart.source.providerMetadata?.values['anthropic'], {
        'pageAge': '1d',
        'resultType': 'web_search_result',
      });
    });

    test('ignores result blocks without tool_use_id', () {
      final parts = projectAnthropicResultToolResultParts(
        blockType: 'web_fetch_tool_result',
        block: {
          'type': 'web_fetch_tool_result',
          'content': {
            'type': 'web_fetch_result',
          },
        },
        descriptorProviderMetadata: null,
        descriptorToolName: null,
        descriptorIsDynamic: null,
      ).toList();

      expect(parts, isEmpty);
    });
  });
}
