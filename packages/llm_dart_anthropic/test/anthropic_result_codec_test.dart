import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  const codec = AnthropicMessagesResultCodec();

  group('AnthropicMessagesResultCodec', () {
    test('decodes text responses with citations', () {
      final result = codec.decodeResponse({
        'id': 'msg_1',
        'model': 'claude-sonnet-4-5',
        'content': [
          {
            'type': 'text',
            'text': 'Hello',
            'citations': [
              {
                'type': 'web_search_result_location',
                'cited_text': 'Hello',
                'url': 'https://example.com',
                'title': 'Example',
                'encrypted_index': 'enc_1',
              },
            ],
          },
        ],
        'stop_reason': 'end_turn',
        'stop_sequence': null,
        'usage': {
          'input_tokens': 12,
          'output_tokens': 34,
        },
      });

      expect(result.text, 'Hello');
      expect(result.finishReason, FinishReason.stop);
      expect(result.responseId, 'msg_1');
      expect(result.responseModelId, 'claude-sonnet-4-5');
      expect(result.usage?.inputTokens, 12);
      expect(result.usage?.outputTokens, 34);
      expect(result.content.length, 2);
      expect(result.content.first, isA<TextContentPart>());
      expect(result.content.last, isA<SourceContentPart>());

      final source = (result.content.last as SourceContentPart).source;
      expect(source.kind, SourceReferenceKind.url);
      expect(source.uri.toString(), 'https://example.com');
      expect(source.title, 'Example');
    });

    test('decodes mcp tool use and result content', () {
      final result = codec.decodeResponse({
        'id': 'msg_2',
        'model': 'claude-sonnet-4-5',
        'content': [
          {
            'type': 'mcp_tool_use',
            'id': 'mcptoolu_1',
            'name': 'echo',
            'server_name': 'workspace',
            'input': {
              'message': 'hello world',
            },
          },
          {
            'type': 'mcp_tool_result',
            'tool_use_id': 'mcptoolu_1',
            'is_error': false,
            'content': [
              {
                'type': 'text',
                'text': 'Tool echo: hello world',
              },
            ],
          },
          {
            'type': 'text',
            'text': 'done',
          },
        ],
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 20,
          'output_tokens': 10,
        },
      });

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;

      expect(toolCall.toolCall.toolName, 'mcp.echo');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.isDynamic, isTrue);
      expect(toolCall.toolCall.title, 'workspace');

      expect(toolResult.toolResult.toolName, 'mcp.echo');
      expect(toolResult.toolResult.isDynamic, isTrue);
      expect(toolResult.toolResult.isError, isFalse);
      expect(
        toolResult.providerMetadata?.values['anthropic'],
        {
          'serverName': 'workspace',
          'partType': 'mcp_tool_result',
        },
      );
      expect(result.text, 'done');
    });

    test('decodes reasoning and provider-executed tool results', () {
      final result = codec.decodeResponse({
        'id': 'msg_3',
        'model': 'claude-sonnet-4-5',
        'content': [
          {
            'type': 'thinking',
            'thinking': 'plan',
            'signature': 'sig_1',
          },
          {
            'type': 'redacted_thinking',
            'data': 'secret',
          },
          {
            'type': 'server_tool_use',
            'id': 'srvtoolu_1',
            'name': 'web_search',
            'input': {
              'query': 'dart sdk',
            },
          },
          {
            'type': 'web_search_tool_result',
            'tool_use_id': 'srvtoolu_1',
            'content': [
              {
                'url': 'https://dart.dev',
                'title': 'Dart',
                'page_age': '1d',
                'encrypted_content': 'enc_1',
                'type': 'web_search_result',
              },
            ],
          },
        ],
        'stop_reason': 'end_turn',
        'usage': {
          'input_tokens': 30,
          'output_tokens': 15,
        },
      });

      final reasoningParts =
          result.content.whereType<ReasoningContentPart>().toList();
      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;
      final source = result.content.whereType<SourceContentPart>().single;

      expect(reasoningParts, hasLength(2));
      expect(reasoningParts.first.text, 'plan');
      expect(
        reasoningParts.first.providerMetadata?.values['anthropic'],
        {
          'signature': 'sig_1',
        },
      );
      expect(reasoningParts.last.text, '');
      expect(
        reasoningParts.last.providerMetadata?.values['anthropic'],
        {
          'redactedData': 'secret',
        },
      );

      expect(toolCall.toolCall.toolName, 'web_search');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.isDynamic, isTrue);

      expect(toolResult.toolResult.toolName, 'web_search');
      expect(toolResult.toolResult.isDynamic, isTrue);
      expect(source.source.uri.toString(), 'https://dart.dev');
      expect(source.source.title, 'Dart');
    });
  });
}
