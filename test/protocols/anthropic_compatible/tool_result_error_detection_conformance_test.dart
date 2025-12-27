import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:test/test.dart';

void main() {
  group('Anthropic-compatible tool_result is_error conformance', () {
    test('marks is_error=true when result JSON contains error fields', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      final message = ChatMessage.toolResult(
        results: const [
          ToolCall(
            id: 'toolu_1',
            callType: 'function',
            function: FunctionCall(
              name: 't',
              arguments: '{"error":"boom"}',
            ),
          ),
        ],
      );

      final body = builder.buildRequestBody([message], const [], false);
      final messages = body['messages'] as List<dynamic>;
      final content =
          (messages.single as Map<String, dynamic>)['content'] as List<dynamic>;
      final toolResult = content.single as Map<String, dynamic>;
      expect(toolResult['type'], equals('tool_result'));
      expect(toolResult['tool_use_id'], equals('toolu_1'));
      expect(toolResult['content'], equals('{"error":"boom"}'));
      expect(toolResult['is_error'], isTrue);
    });

    test('marks is_error=true when result text looks like an error', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      final message = ChatMessage.toolResult(
        results: const [
          ToolCall(
            id: 'toolu_1',
            callType: 'function',
            function: FunctionCall(
              name: 't',
              arguments: 'FAILED to fetch',
            ),
          ),
        ],
      );

      final body = builder.buildRequestBody([message], const [], false);
      final messages = body['messages'] as List<dynamic>;
      final content =
          (messages.single as Map<String, dynamic>)['content'] as List<dynamic>;
      final toolResult = content.single as Map<String, dynamic>;
      expect(toolResult['is_error'], isTrue);
    });

    test('marks is_error=false for non-error JSON result', () {
      const config = AnthropicConfig(
        apiKey: 'k',
        model: 'test-model',
        providerId: 'anthropic',
      );
      final builder = AnthropicRequestBuilder(config);

      final message = ChatMessage.toolResult(
        results: const [
          ToolCall(
            id: 'toolu_1',
            callType: 'function',
            function: FunctionCall(
              name: 't',
              arguments: '{"ok":true}',
            ),
          ),
        ],
      );

      final body = builder.buildRequestBody([message], const [], false);
      final messages = body['messages'] as List<dynamic>;
      final content =
          (messages.single as Map<String, dynamic>)['content'] as List<dynamic>;
      final toolResult = content.single as Map<String, dynamic>;
      expect(toolResult['is_error'], isFalse);
    });
  });
}
