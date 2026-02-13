import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:test/test.dart';

class _FakeAnthropicClient extends AnthropicClient {
  final Stream<String> _stream;

  _FakeAnthropicClient(
    super.config, {
    required Stream<String> stream,
  }) : _stream = stream;

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    return _stream;
  }

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    return (stream: _stream, headers: const <String, String>{});
  }
}

Map<String, dynamic> _anthropicPayload(ChatMessage message) {
  return message.getProtocolPayload<Map<String, dynamic>>('anthropic') ??
      const <String, dynamic>{};
}

void main() {
  group('Anthropic streaming thinking signatures', () {
    test('chatStreamParts preserves thinking.signature in assistantMessage',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
      final anthropicConfig = AnthropicConfig.fromLLMConfig(llmConfig);

      final sse = [
        'event: message_start\n'
            'data: {"type":"message_start","message":{"id":"msg_123","model":"claude-sonnet-4-20250514","usage":{"input_tokens":1,"output_tokens":0}}}\n'
            '\n'
            'event: content_block_start\n'
            'data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":""}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"I am thinking..."}}\n'
            '\n'
            'event: content_block_delta\n'
            'data: {"type":"content_block_delta","index":0,"delta":{"type":"signature_delta","signature":"sig_123"}}\n'
            '\n'
            'event: content_block_stop\n'
            'data: {"type":"content_block_stop","index":0}\n'
            '\n'
            'event: message_delta\n'
            'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":2}}\n'
            '\n'
            'event: message_stop\n'
            'data: {"type":"message_stop"}\n'
            '\n',
      ];

      final client = _FakeAnthropicClient(
        anthropicConfig,
        stream: Stream<String>.fromIterable(sse),
      );
      final chat = AnthropicChat(client, anthropicConfig);

      final parts = await chat
          .chatStreamParts([ChatMessage.user('Hi')], tools: const []).toList();

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response, isA<ChatResponseWithAssistantMessage>());

      final assistantMessage =
          (finish.response as ChatResponseWithAssistantMessage)
              .assistantMessage;
      final blocks =
          _anthropicPayload(assistantMessage)['contentBlocks'] as List?;
      expect(blocks, isNotNull);

      final thinking = blocks!
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .firstWhere((b) => b['type'] == 'thinking');

      expect(thinking['thinking'], equals('I am thinking...'));
      expect(thinking['signature'], equals('sig_123'));
    });
  });
}
