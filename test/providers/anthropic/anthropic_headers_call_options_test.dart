import 'package:dio/dio.dart';
import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_anthropic/testing.dart' as anthropic_pkg;
import 'package:test/test.dart';

class CapturingAnthropicClient extends anthropic_pkg.AnthropicClient {
  Map<String, dynamic>? lastRequestBody;
  String? lastEndpoint;
  Map<String, String>? lastHeaders;

  CapturingAnthropicClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    lastEndpoint = endpoint;
    lastRequestBody = data;
    lastHeaders = headers;

    return {
      'content': [
        {'type': 'text', 'text': 'ok'}
      ],
      'usage': {'input_tokens': 1, 'output_tokens': 1},
    };
  }
}

void main() {
  group('AnthropicChat call options', () {
    test('headers in options are passed to the client', () async {
      final config = anthropic_pkg.AnthropicConfig(
        apiKey: 'test',
        model: 'claude-sonnet-4-20250514',
      );

      final client = CapturingAnthropicClient(config);
      final chat = anthropic_pkg.AnthropicChat(client, config);

      await chat.chat(
        [ModelMessage.userText('Hello')],
        options: const LanguageModelCallOptions(headers: {'X-Test': '1'}),
      );

      expect(client.lastEndpoint, equals('messages'));
      expect(client.lastHeaders, equals({'X-Test': '1'}));
    });
  });
}
