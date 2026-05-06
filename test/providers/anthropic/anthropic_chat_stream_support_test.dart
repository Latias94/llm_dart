import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/core/llm_error.dart';
import 'package:llm_dart/models/chat_models.dart';
import 'package:llm_dart/providers/anthropic/chat.dart' as anthropic_chat;
import 'package:llm_dart/providers/anthropic/client.dart' as anthropic_client;
import 'package:llm_dart/providers/anthropic/config.dart' as anthropic_config;
import 'package:test/test.dart';

void main() {
  group('Anthropic chat stream support extraction', () {
    test('preserves split SSE frames across transport chunks', () async {
      final config = anthropic_config.AnthropicConfig(
        apiKey: 'test-key',
        model: 'claude-3-7-sonnet-20250219',
      );

      final client = _SplitFrameAnthropicClient(config);
      final chat = anthropic_chat.AnthropicChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('test')]).toList();

      expect(
        events.whereType<TextDeltaEvent>().map((event) => event.delta).toList(),
        ['Hello'],
      );

      final completion = events.whereType<CompletionEvent>().last;
      expect(completion.response.usage?.completionTokens, 2);
    });

    test('preserves thinking deltas and pause_turn completion metadata',
        () async {
      final config = anthropic_config.AnthropicConfig(
        apiKey: 'test-key',
        model: 'claude-3-7-sonnet-20250219',
      );

      final client = _ThinkingAnthropicClient(config);
      final chat = anthropic_chat.AnthropicChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('test')]).toList();

      expect(
        events
            .whereType<ThinkingDeltaEvent>()
            .map((event) => event.delta)
            .toList(),
        ['Plan carefully.'],
      );

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.usage?.completionTokens, 7);
    });

    test('aggregates partial tool JSON into a stable tool call event',
        () async {
      final config = anthropic_config.AnthropicConfig(
        apiKey: 'test-key',
        model: 'claude-3-7-sonnet-20250219',
      );

      final client = _ToolUseAnthropicClient(config);
      final chat = anthropic_chat.AnthropicChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('test')]).toList();

      final toolEvent = events.whereType<ToolCallDeltaEvent>().single;
      expect(toolEvent.toolCall.id, 'toolu_1');
      expect(toolEvent.toolCall.function.name, 'get_weather');
      expect(toolEvent.toolCall.function.arguments, '{"city":"Hong Kong"}');
    });

    test('maps anthropic stream errors into typed error events', () async {
      final config = anthropic_config.AnthropicConfig(
        apiKey: 'test-key',
        model: 'claude-3-7-sonnet-20250219',
      );

      final client = _ErrorAnthropicClient(config);
      final chat = anthropic_chat.AnthropicChat(client, config);

      final events = await chat.chatStream([ChatMessage.user('test')]).toList();

      final errorEvent = events.whereType<ErrorEvent>().single;
      expect(errorEvent.error, isA<RateLimitError>());
      expect(errorEvent.error.message, contains('too many requests'));
    });
  });
}

class _SplitFrameAnthropicClient extends anthropic_client.AnthropicClient {
  _SplitFrameAnthropicClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    const chunks = <String>[
      'event: content_block_delta\ndata: {"type":"content_block_delta","index":0,',
      '"delta":{"type":"text_delta","text":"Hello"}}\n',
      'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"input_tokens":3,"output_tokens":2}}\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

class _ThinkingAnthropicClient extends anthropic_client.AnthropicClient {
  _ThinkingAnthropicClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    const chunks = <String>[
      'data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking"}}\n',
      'data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"Plan carefully."}}\n',
      'data: {"type":"message_delta","delta":{"stop_reason":"pause_turn"},"usage":{"input_tokens":4,"output_tokens":7}}\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

class _ToolUseAnthropicClient extends anthropic_client.AnthropicClient {
  _ToolUseAnthropicClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    const chunks = <String>[
      'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"get_weather"}}\n',
      'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"city\\":\\""}}\n',
      'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"Hong Kong\\"}"}}\n',
      'data: {"type":"content_block_stop","index":1}\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

class _ErrorAnthropicClient extends anthropic_client.AnthropicClient {
  _ErrorAnthropicClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    TransportCancellation? cancelToken,
  }) async* {
    const chunks = <String>[
      'data: {"type":"error","error":{"type":"rate_limit_error","message":"too many requests"}}\n',
    ];

    for (final chunk in chunks) {
      yield chunk;
    }
  }
}
