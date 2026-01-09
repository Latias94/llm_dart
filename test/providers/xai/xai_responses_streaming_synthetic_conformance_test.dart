import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/responses.dart';
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('xAI Responses streaming (synthetic conformance)', () {
    test('captures x_search_call as server tool metadata', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast-reasoning',
      );

      final chunks = <String>[
        _sseData({
          'type': 'response.created',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'model': 'grok-4-fast-reasoning',
            'output': [],
            'status': 'in_progress',
          },
        }),
        _sseData({
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'type': 'x_search_call',
            'id': 'fc_1',
            'name': 'x_semantic_search',
            'arguments': '{"query":"AI"}',
            'status': 'completed',
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'item_id': 'msg_1',
          'output_index': 1,
          'content_index': 0,
          'delta': 'Hello',
        }),
        _sseData({
          'type': 'response.output_text.annotation.added',
          'item_id': 'msg_1',
          'output_index': 1,
          'content_index': 0,
          'annotation_index': 0,
          'annotation': {
            'type': 'url_citation',
            'url': 'https://x.com/i/status/1',
          },
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_1',
            'model': 'grok-4-fast-reasoning',
            'status': 'completed',
            'output': [
              {
                'type': 'x_search_call',
                'id': 'fc_1',
                'name': 'x_semantic_search',
                'arguments': '{"query":"AI"}',
                'status': 'completed',
              },
              {
                'type': 'message',
                'id': 'msg_1',
                'role': 'assistant',
                'status': 'completed',
                'content': [
                  {
                    'type': 'output_text',
                    'text': 'Hello',
                    'annotations': [
                      {
                        'type': 'url_citation',
                        'url': 'https://x.com/i/status/1',
                      },
                    ],
                  },
                ],
              },
            ],
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
            },
          },
        }),
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Hello'));
      expect(finish.response.toolCalls, isNull);

      final meta = finish.response.providerMetadata?['xai.responses'];
      expect(meta, isNotNull);
      expect((meta!['serverToolCalls'] as List?)?.length, equals(1));
      expect(((meta['serverToolCalls'] as List).first as Map)['type'],
          equals('x_search_call'));
      expect((meta['sources'] as List?)?.length, equals(1));
    });

    test('captures code_interpreter_call as server tool metadata', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast-reasoning',
      );

      final chunks = <String>[
        _sseData({
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'type': 'code_interpreter_call',
            'id': 'fc_2',
            'name': 'code_execution',
            'arguments': '{"code":"print(1)"}',
            'status': 'completed',
          },
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_2',
            'model': 'grok-4-fast-reasoning',
            'status': 'completed',
            'output': [
              {
                'type': 'code_interpreter_call',
                'id': 'fc_2',
                'name': 'code_execution',
                'arguments': '{"code":"print(1)"}',
                'status': 'completed',
              },
              {
                'type': 'message',
                'id': 'msg_2',
                'role': 'assistant',
                'status': 'completed',
                'content': [
                  {
                    'type': 'output_text',
                    'text': '1',
                    'annotations': const [],
                  },
                ],
              },
            ],
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
            },
          },
        }),
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('1'));
      expect(finish.response.toolCalls, isNull);

      final meta = finish.response.providerMetadata?['xai.responses'];
      expect(meta, isNotNull);
      expect((meta!['serverToolCalls'] as List?)?.length, equals(1));
      expect(((meta['serverToolCalls'] as List).first as Map)['type'],
          equals('code_interpreter_call'));
    });

    test('streams function_call as local toolCalls', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-fast-reasoning',
      );

      final chunks = <String>[
        _sseData({
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'type': 'function_call',
            'id': 'fc_call_1',
            'call_id': 'call_1',
            'name': 'weather',
            'arguments': '{"location":"SF"}',
          },
        }),
        _sseData({
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'type': 'function_call',
            'id': 'fc_call_1',
            'call_id': 'call_1',
            'name': 'weather',
            'arguments': '{"location":"SF"}',
          },
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'object': 'response',
            'id': 'resp_3',
            'model': 'grok-4-fast-reasoning',
            'status': 'completed',
            'output': [
              {
                'type': 'function_call',
                'id': 'fc_call_1',
                'call_id': 'call_1',
                'name': 'weather',
                'arguments': '{"location":"SF"}',
              },
            ],
            'usage': {
              'input_tokens': 1,
              'output_tokens': 1,
              'total_tokens': 2,
            },
          },
        }),
      ];

      final client = FakeOpenAIClient(config)
        ..streamResponse = Stream<String>.fromIterable(chunks);
      final responses = XAIResponses(client, config);

      final parts =
          await responses.chatStreamParts([ChatMessage.user('Hi')]).toList();

      expect(parts.whereType<LLMToolCallStartPart>(), hasLength(1));
      expect(parts.whereType<LLMToolCallEndPart>(), hasLength(1));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.toolCalls, isNotNull);
      expect(finish.response.toolCalls, hasLength(1));
      expect(
          finish.response.toolCalls!.single.function.name, equals('weather'));
      expect(finish.response.toolCalls!.single.function.arguments,
          equals('{"location":"SF"}'));
    });
  });
}
