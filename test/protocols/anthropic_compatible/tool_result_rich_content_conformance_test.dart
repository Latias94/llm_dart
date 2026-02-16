import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic-compatible tool_result rich content', () {
    test('decodes JSON array tool result content into content blocks', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'test-model',
      );
      final config = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(config);

      final body = builder.buildRequestBody(
        [
          ChatMessage.user('hi'),
          ChatMessage.toolResult(
            results: [
              ToolCall(
                id: 'call_1',
                callType: 'function',
                function: const FunctionCall(
                  name: 'computer',
                  arguments: '[{"type":"text","text":"ok"}]',
                ),
              ),
            ],
          ),
        ],
        const [],
        false,
      );

      final messages = body['messages'] as List<dynamic>;
      expect(messages, hasLength(2));

      final toolResultMsg = messages[1] as Map;
      expect(toolResultMsg['role'], equals('user'));

      final content = toolResultMsg['content'] as List<dynamic>;
      final toolResultBlock = content.first as Map;
      expect(toolResultBlock['type'], equals('tool_result'));

      final decoded = toolResultBlock['content'];
      expect(decoded, isA<List>());

      final blocks = (decoded as List).whereType<Map>().toList();
      expect(blocks, hasLength(1));
      expect(blocks.first['type'], equals('text'));
      expect(blocks.first['text'], equals('ok'));
    });

    test('keeps JSON object tool result content as string', () {
      final llmConfig = LLMConfig(
        apiKey: 'k',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'test-model',
      );
      final config = AnthropicConfig.fromLLMConfig(llmConfig);
      final builder = AnthropicRequestBuilder(config);

      final body = builder.buildRequestBody(
        [
          ChatMessage.user('hi'),
          ChatMessage.toolResult(
            results: [
              ToolCall(
                id: 'call_2',
                callType: 'function',
                function: const FunctionCall(
                  name: 'bash',
                  arguments: '{"stdout":"hi"}',
                ),
              ),
            ],
          ),
        ],
        const [],
        false,
      );

      final messages = body['messages'] as List<dynamic>;
      final toolResultMsg = messages[1] as Map;
      final content = toolResultMsg['content'] as List<dynamic>;
      final toolResultBlock = content.first as Map;

      expect(toolResultBlock['content'], equals('{"stdout":"hi"}'));
    });
  });
}
