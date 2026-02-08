import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('OpenAI-compatible chatStreamParts (think tags)', () {
    test('extracts reasoning from split <think> tags', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello <thi'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'nk>ana'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'lyzing</th'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'ink>world'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'stop',
            }
          ],
        }),
        'data: [DONE]\n\n',
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final chat = OpenAIChat(client, config);

      final parts = await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(parts.whereType<LLMTextStartPart>(), hasLength(2));
      expect(
        parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join(),
        equals('Hello world'),
      );
      expect(
        parts.whereType<LLMTextEndPart>().map((p) => p.text).toList(),
        equals(['Hello ', 'world']),
      );

      expect(parts.whereType<LLMReasoningStartPart>(), hasLength(1));
      expect(
        parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join(),
        equals('analyzing'),
      );
      expect(
        parts.whereType<LLMReasoningEndPart>().single.thinking,
        equals('analyzing'),
      );

      final finish = parts.last as LLMFinishPart;
      expect(finish.response.text, equals('Hello world'));
      expect(finish.response.thinking, equals('analyzing'));
    });

    test('emits reasoning start/end for empty <think></think>', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai',
        providerName: 'OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_empty',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': '<think></th'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_empty',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'ink>Hello'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_empty',
          'model': 'gpt-4o',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'stop',
            }
          ],
        }),
        'data: [DONE]\n\n',
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final chat = OpenAIChat(client, config);

      final parts = await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(parts.whereType<LLMReasoningStartPart>(), hasLength(1));
      expect(parts.whereType<LLMReasoningDeltaPart>(), isEmpty);
      expect(parts.whereType<LLMReasoningEndPart>().single.thinking, equals(''));

      final finish = parts.last as LLMFinishPart;
      expect(finish.response.text, equals('Hello'));
      expect(finish.response.thinking, isNull);
    });
  });
}

