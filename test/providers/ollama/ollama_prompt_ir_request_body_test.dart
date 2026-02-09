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
    lastRequestBody = data;
    return {
      'model': 'test-model',
      'message': {
        'role': 'assistant',
        'content': 'ok',
      },
      'done': true,
    };
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
            role: ChatRole.user,
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
        equals([base64Encode(const [1, 2, 3])]),
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
            role: ChatRole.assistant,
            parts: [
              ToolCallPart(
                ToolCall(
                  id: 'call_1',
                  callType: 'function',
                  function: const FunctionCall(
                    name: 'get_weather',
                    arguments: '{"city":"Tokyo"}',
                  ),
                ),
              ),
            ],
          ),
          PromptMessage(
            role: ChatRole.user,
            parts: [
              ToolResultPart(
                ToolCall(
                  id: 'call_1',
                  callType: 'function',
                  function: const FunctionCall(
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

