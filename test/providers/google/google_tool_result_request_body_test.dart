import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_google/client.dart';
import 'package:test/test.dart';

class _CapturingGoogleClient extends GoogleClient {
  Map<String, dynamic>? lastBody;

  _CapturingGoogleClient(super.config);

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) {
    lastBody = data;
    return Stream<String>.empty();
  }
}

void main() {
  group('Google tool result request shaping', () {
    test('allows plain string tool results (non-JSON)', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final tools = [
        Tool.function(
          name: 'getWeather',
          description: 'Test tool',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        ),
      ];

      await chat.chatStreamParts(
        [
          ChatMessage.toolResult(
            results: [
              ToolCall(
                id: 'call_1',
                callType: 'function',
                function:
                    const FunctionCall(name: 'getWeather', arguments: 'OK'),
              ),
            ],
          ),
        ],
        tools: tools,
      ).toList();

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, isNotEmpty);

      final message = contents!.first as Map;
      expect(message['role'], 'user');
      final parts = message['parts'] as List;
      final functionResponse = (parts.single as Map)['functionResponse'] as Map;
      final response = functionResponse['response'] as Map;
      expect(response['content'], 'OK');
    });

    test('parses JSON tool results when possible', () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
      );

      final config =
          GoogleConfig.fromLLMConfig(llmConfig).copyWith(stream: true);
      final client = _CapturingGoogleClient(config);
      final chat = GoogleChat(client, config);

      final tools = [
        Tool.function(
          name: 'getWeather',
          description: 'Test tool',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {},
            required: [],
          ),
        ),
      ];

      await chat.chatStreamParts(
        [
          ChatMessage.toolResult(
            results: [
              ToolCall(
                id: 'call_1',
                callType: 'function',
                function: const FunctionCall(
                  name: 'getWeather',
                  arguments: '{"temp":42}',
                ),
              ),
            ],
          ),
        ],
        tools: tools,
      ).toList();

      final contents = client.lastBody?['contents'] as List?;
      expect(contents, isNotNull);
      expect(contents, isNotEmpty);

      final message = contents!.first as Map;
      final parts = message['parts'] as List;
      final functionResponse = (parts.single as Map)['functionResponse'] as Map;
      final response = functionResponse['response'] as Map;
      expect(response['content'], equals({'temp': 42}));
    });
  });
}
