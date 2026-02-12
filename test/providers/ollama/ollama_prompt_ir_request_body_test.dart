import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_ollama/client.dart';
import 'package:test/test.dart';

class _CapturingOllamaClient extends OllamaClient {
  Map<String, dynamic>? lastRequestBody;

  _CapturingOllamaClient(super.config);

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    final responseWithHeaders = await postJsonWithHeaders(
      endpoint,
      data,
      cancelToken: cancelToken,
    );
    return responseWithHeaders.json;
  }

  @override
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      postJsonWithHeaders(
    String endpoint,
    Map<String, dynamic> data, {
    CancelToken? cancelToken,
  }) async {
    lastRequestBody = data;
    return (
      json: {
        'model': 'test-model',
        'message': {
          'role': 'assistant',
          'content': 'ok',
        },
        'done': true,
      },
      headers: const <String, String>{},
    );
  }
}

void main() {
  group('Ollama Prompt IR request body', () {
    test('groups text + image parts into a single message with images',
        () async {
      final config = OllamaConfig(
        baseUrl: 'http://localhost:11434',
        model: 'test-model',
      );

      final client = _CapturingOllamaClient(config);
      final chat = OllamaChat(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.user,
            parts: [
              const TextPart('Describe:'),
              ImagePart(
                mime: ImageMime.png,
                data: const [1, 2, 3],
                text: 'A small icon.',
              ),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final messages = body!['messages'] as List<dynamic>;
      expect(messages, hasLength(1));

      final msg = messages.single as Map;
      expect(msg['role'], equals('user'));
      expect(msg['content'], equals('Describe:\nA small icon.'));
      expect(
        msg['images'],
        equals([
          base64Encode(const [1, 2, 3])
        ]),
      );
    });

    test('compiles tool call + tool result into assistant + tool messages',
        () async {
      final config = OllamaConfig(
        baseUrl: 'http://localhost:11434',
        model: 'test-model',
      );

      final client = _CapturingOllamaClient(config);
      final chat = OllamaChat(client, config);

      final prompt = Prompt(
        messages: [
          PromptMessage(
            role: PromptRole.assistant,
            parts: [
              ToolCallPart.fromToolCall(
                const ToolCall(
                  id: 'call_1',
                  callType: 'function',
                  function: FunctionCall(
                    name: 'get_weather',
                    arguments: '{"city":"Tokyo"}',
                  ),
                ),
              ),
            ],
          ),
          PromptMessage(
            role: PromptRole.tool,
            parts: [
              ToolResultPart.fromToolCall(
                const ToolCall(
                  id: 'call_1',
                  callType: 'function',
                  function: FunctionCall(
                    name: 'get_weather',
                    arguments: '11 degrees celsius',
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      await chat.chatPrompt(prompt);

      final body = client.lastRequestBody;
      expect(body, isNotNull);

      final messages = body!['messages'] as List<dynamic>;
      expect(messages, hasLength(2));

      final assistant = messages[0] as Map;
      expect(assistant['role'], equals('assistant'));
      expect(assistant['content'], equals(''));
      expect(
        assistant['tool_calls'],
        equals([
          {
            'function': {
              'name': 'get_weather',
              'arguments': {'city': 'Tokyo'},
            }
          }
        ]),
      );

      final tool = messages[1] as Map;
      expect(tool['role'], equals('tool'));
      expect(tool['content'], equals('11 degrees celsius'));
      expect(tool['tool_name'], equals('get_weather'));
    });
  });
}
