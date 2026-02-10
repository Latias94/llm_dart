import 'dart:convert';
import 'dart:math';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

import '../../utils/fakes/fakes.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

List<String> _splitRandom(String input, {required int seed, int maxLen = 11}) {
  final random = Random(seed);
  final chunks = <String>[];
  var i = 0;
  while (i < input.length) {
    final remaining = input.length - i;
    final size = min(remaining, 1 + random.nextInt(maxLen));
    chunks.add(input.substring(i, i + size));
    i += size;
  }
  return chunks;
}

void main() {
  group('OpenAI Responses streaming fuzz (chunk boundaries)', () {
    test('handles arbitrary chunk splits without losing provider tool/sources',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: true,
      );

      final sse = [
        _sseData({
          'type': 'response.created',
          'response': {
            'id': 'resp_fuzz',
            'model': 'gpt-5-mini',
            'status': 'in_progress',
            'created_at': 1739145600,
            'system_fingerprint': 'fp_fuzz',
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'delta': 'Hello ',
        }),
        _sseData({
          'type': 'response.output_text.annotation.added',
          'annotation': {
            'type': 'url_citation',
            'url': 'https://citation.example/',
            'title': 'Citation',
            'start_index': 0,
            'end_index': 5,
          },
        }),
        // Duplicate citation should be deduped into a single source part.
        _sseData({
          'type': 'response.output_text.annotation.added',
          'annotation': {
            'type': 'url_citation',
            'url': 'https://citation.example/',
            'title': 'Citation',
            'start_index': 0,
            'end_index': 5,
          },
        }),
        _sseData({
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'type': 'web_search_call',
            'id': 'ws_1',
            'arguments': {'query': 'OpenAI'},
            'status': 'in_progress',
          },
        }),
        _sseData({
          'type': 'response.web_search_call.in_progress',
          'item_id': 'ws_1',
          'progress': 0.5,
        }),
        _sseData({
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'type': 'web_search_call',
            'id': 'ws_1',
            'status': 'completed',
            'action': {
              'type': 'search',
              'sources': [
                {
                  'type': 'url',
                  'url': 'https://search.example/',
                  'title': 'Search',
                },
                // Duplicate sources should be deduped.
                {
                  'type': 'url',
                  'url': 'https://search.example/',
                  'title': 'Search',
                },
              ],
            },
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'delta': 'world',
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'id': 'resp_fuzz',
            'model': 'gpt-5-mini',
            'status': 'completed',
            'created_at': 1739145600,
            'usage': {
              'input_tokens': 10,
              'output_tokens': 5,
              'total_tokens': 15,
            },
            'output': [
              {
                'type': 'message',
                'role': 'assistant',
                'content': [
                  {
                    'type': 'output_text',
                    'text': 'Hello world',
                    'annotations': [
                      {
                        'type': 'url_citation',
                        'url': 'https://citation.example/',
                        'title': 'Citation',
                        'start_index': 0,
                        'end_index': 5,
                      }
                    ],
                  }
                ],
              },
              {
                'type': 'web_search_call',
                'id': 'ws_1',
                'status': 'completed',
                'action': {
                  'type': 'search',
                  'sources': [
                    {
                      'type': 'url',
                      'url': 'https://search.example/',
                      'title': 'Search',
                    },
                  ],
                },
              }
            ],
          },
        }),
        'data: [DONE]\n\n',
      ].join();

      for (final seed in [1, 7, 42]) {
        final client = FakeOpenAIClient(config)
          ..streamResponse =
              Stream<String>.fromIterable(_splitRandom(sse, seed: seed));
        final responses = openai_responses.OpenAIResponses(client, config);

        final parts = await responses.chatStreamParts([ChatMessage.user('Hi')],
            tools: const []).toList();

        final text =
            parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
        expect(text, equals('Hello world'));

        final calls = parts.whereType<LLMProviderToolCallPart>().toList();
        final results = parts.whereType<LLMProviderToolResultPart>().toList();
        expect(calls, hasLength(1));
        expect(results, hasLength(1));
        expect(calls.single.toolName, equals('web_search'));
        expect(results.single.toolName, equals('web_search'));
        expect(results.single.toolCallId, equals(calls.single.toolCallId));

        final deltas = parts.whereType<LLMProviderToolDeltaPart>().toList();
        expect(deltas, isEmpty);

        final sources = parts.whereType<LLMSourceUrlPart>().toList();
        final urls = sources.map((p) => p.url).toSet();
        expect(urls,
            equals({'https://citation.example/', 'https://search.example/'}));

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.usage?.totalTokens, equals(15));
        expect(
            finish.finishReason?.unified, equals(LLMUnifiedFinishReason.stop));
      }
    });

    test('handles arbitrary chunk splits without losing function tool input',
        () async {
      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: 'gpt-5-mini',
        useResponsesAPI: true,
      );

      final tools = [
        Tool.function(
          name: 'getWeather',
          description: 'Get the weather for a city.',
          parameters: const ParametersSchema(
            schemaType: 'object',
            properties: {
              'city': ParameterProperty(
                propertyType: 'string',
                description: 'City name.',
              ),
            },
            required: ['city'],
          ),
        ),
      ];

      final fullArgs = '{"city":"London"}';
      final sse = [
        _sseData({
          'type': 'response.created',
          'response': {
            'id': 'resp_fn_fuzz',
            'model': 'gpt-5-mini',
            'status': 'in_progress',
            'created_at': 1739145600,
            'output': [],
          },
        }),
        _sseData({
          'type': 'response.output_item.added',
          'output_index': 0,
          'item': {
            'type': 'function_call',
            'id': 'fc_1',
            'call_id': 'call_1',
            'name': 'getWeather',
            'status': 'in_progress',
          },
        }),
        _sseData({
          'type': 'response.function_call_arguments.delta',
          'output_index': 0,
          'delta': '{"city":"Lon',
        }),
        _sseData({
          'type': 'response.function_call_arguments.delta',
          'output_index': 0,
          'delta': 'don"}',
        }),
        _sseData({
          'type': 'response.output_item.done',
          'output_index': 0,
          'item': {
            'type': 'function_call',
            'id': 'fc_1',
            'call_id': 'call_1',
            'name': 'getWeather',
            'arguments': fullArgs,
            'status': 'completed',
          },
        }),
        _sseData({
          'type': 'response.output_text.delta',
          'delta': 'OK',
        }),
        _sseData({
          'type': 'response.completed',
          'response': {
            'id': 'resp_fn_fuzz',
            'model': 'gpt-5-mini',
            'status': 'completed',
            'created_at': 1739145600,
            'usage': {
              'input_tokens': 10,
              'output_tokens': 5,
              'total_tokens': 15,
            },
            'output': [
              {
                'type': 'function_call',
                'id': 'fc_1',
                'call_id': 'call_1',
                'name': 'getWeather',
                'arguments': fullArgs,
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
                    'text': 'OK',
                    'annotations': const [],
                  },
                ],
              },
            ],
          },
        }),
        'data: [DONE]\n\n',
      ].join();

      for (final seed in [1, 7, 42]) {
        final client = FakeOpenAIClient(config)
          ..streamResponse =
              Stream<String>.fromIterable(_splitRandom(sse, seed: seed));
        final responses = openai_responses.OpenAIResponses(client, config);

        final parts = await responses
            .chatStreamParts([ChatMessage.user('Hi')], tools: tools).toList();

        final toolStarts = parts.whereType<LLMToolCallStartPart>().toList();
        final toolDeltas = parts.whereType<LLMToolCallDeltaPart>().toList();
        final toolEnds = parts.whereType<LLMToolCallEndPart>().toList();

        expect(toolStarts, hasLength(1));
        expect(toolDeltas, hasLength(2));
        expect(toolEnds, hasLength(1));

        expect(toolStarts.single.toolCall.id, equals('call_1'));
        expect(toolStarts.single.toolCall.function.name, equals('getWeather'));
        expect(toolStarts.single.toolCall.function.arguments, isEmpty);

        expect(toolDeltas[0].toolCall.id, equals('call_1'));
        expect(toolDeltas[1].toolCall.id, equals('call_1'));
        expect(
            toolDeltas[0].toolCall.function.arguments, equals('{"city":"Lon'));
        expect(toolDeltas[1].toolCall.function.arguments, equals('don"}'));

        expect(toolEnds.single.toolCallId, equals('call_1'));

        final idxStart = parts.indexOf(toolStarts.single);
        final idxDelta0 = parts.indexOf(toolDeltas[0]);
        final idxDelta1 = parts.indexOf(toolDeltas[1]);
        final idxEnd = parts.indexOf(toolEnds.single);
        expect(idxStart, lessThan(idxDelta0));
        expect(idxDelta0, lessThan(idxDelta1));
        expect(idxDelta1, lessThan(idxEnd));

        final finish = parts.whereType<LLMFinishPart>().single;
        expect(finish.response.text, equals('OK'));
        expect(finish.finishReason?.unified,
            equals(LLMUnifiedFinishReason.toolCalls));

        final calls = finish.response.toolCalls;
        expect(calls, isNotNull);
        expect(calls, hasLength(1));
        expect(calls!.single.id, equals('call_1'));
        expect(calls.single.function.name, equals('getWeather'));
        expect(jsonDecode(calls.single.function.arguments),
            equals(jsonDecode(fullArgs)));

        final v3 = encodeV3StreamParts(parts);
        final toolInputStart =
            v3.where((p) => p['type'] == 'tool-input-start').toList();
        final toolInputDelta =
            v3.where((p) => p['type'] == 'tool-input-delta').toList();
        final toolInputEnd =
            v3.where((p) => p['type'] == 'tool-input-end').toList();
        final toolCall = v3.where((p) => p['type'] == 'tool-call').toList();

        expect(toolInputStart, hasLength(1));
        expect(toolInputEnd, hasLength(1));
        expect(toolInputDelta, hasLength(2));
        expect(toolCall, hasLength(1));
        expect(toolInputStart.single['id'], equals('call_1'));
        expect(toolInputStart.single['toolName'], equals('getWeather'));
        expect(toolInputEnd.single['id'], equals('call_1'));
        expect(toolCall.single['toolCallId'], equals('call_1'));
        expect(toolCall.single['toolName'], equals('getWeather'));
        expect(toolCall.single['input'], equals(fullArgs));
      }
    });
  });
}
