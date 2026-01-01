import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:test/test.dart';

class _FakeOpenAIClient extends OpenAIClient {
  final Stream<String> _stream;

  _FakeOpenAIClient(
    super.config, {
    required Stream<String> stream,
  }) : _stream = stream;

  @override
  Stream<String> postStreamRaw(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) {
    return _stream;
  }
}

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('OpenAI-compatible chatStreamParts (Chat Completions)', () {
    test('streams text + tool call parts and finishes with providerMetadata',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'deepseek',
        providerName: 'DeepSeek',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_123',
          'model': 'gpt-4o',
          'system_fingerprint': 'fp_1',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_123',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello '},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_123',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'world'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_123',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'type': 'function',
                    'function': {
                      'name': 'getWeather',
                      'arguments': '{"city":"Lon',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_123',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'function': {
                      'arguments': 'don"}',
                    },
                  }
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_123',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'tool_calls',
            }
          ],
          'usage': {
            'prompt_tokens': 10,
            'completion_tokens': 5,
            'total_tokens': 15,
          },
        }),
        'data: [DONE]\n\n',
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts = await chat.chatStreamParts(
        [ChatMessage.user('Hi')],
        tools: const [],
      ).toList();

      expect(parts.whereType<LLMTextStartPart>(), hasLength(1));
      expect(parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
          equals('Hello world'));
      expect(
          parts.whereType<LLMTextEndPart>().single.text, equals('Hello world'));

      final toolStart = parts.whereType<LLMToolCallStartPart>().single;
      expect(toolStart.toolCall.id, equals('call_1'));
      expect(toolStart.toolCall.function.name, equals('getWeather'));
      expect(toolStart.toolCall.function.arguments, equals('{"city":"Lon'));

      final toolDeltas = parts.whereType<LLMToolCallDeltaPart>().toList();
      expect(toolDeltas, hasLength(1));
      expect(toolDeltas.single.toolCall.function.arguments, equals('don"}'));

      expect(parts.whereType<LLMToolCallEndPart>().single.toolCallId,
          equals('call_1'));

      final finish = parts.last as LLMFinishPart;
      expect(finish.response.text, equals('Hello world'));
      expect(finish.response.thinking, isNull);

      final calls = finish.response.toolCalls;
      expect(calls, isNotNull);
      expect(calls!, hasLength(1));
      expect(calls.single.function.name, equals('getWeather'));
      expect(calls.single.function.arguments, equals('{"city":"London"}'));

      final metadata = finish.response.providerMetadata;
      expect(metadata, isNotNull);
      expect(metadata!['deepseek']['id'], equals('chatcmpl_123'));
      expect(metadata['deepseek']['model'], equals('gpt-4o'));
      expect(metadata['deepseek']['systemFingerprint'], equals('fp_1'));
    });
  });
}
