import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIResponsesResponse typed tool outputs', () {
    test('parses web_search_call items', () {
      final response = OpenAIResponsesResponse({
        'output': [
          {
            'type': 'web_search_call',
            'id': 'ws_1',
            'status': 'completed',
            'action': {
              'type': 'search',
              'query': 'dart 3',
              'sources': [
                {'type': 'url', 'url': 'https://dart.dev'},
                {'type': 'api', 'name': 'custom-api'},
              ],
            },
          },
        ],
      });

      final calls = response.webSearchCalls;
      expect(calls, isNotNull);
      expect(calls, hasLength(1));

      final call = calls!.first;
      expect(call.id, equals('ws_1'));
      expect(call.status, equals('completed'));
      expect(call.action.type, equals('search'));
      expect(call.action.query, equals('dart 3'));
      expect(call.action.sources, isNotNull);
      expect(call.action.sources, hasLength(2));
      expect(call.action.sources![0].type, equals('url'));
      expect(call.action.sources![0].url, equals('https://dart.dev'));
      expect(call.action.sources![1].type, equals('api'));
      expect(call.action.sources![1].name, equals('custom-api'));
    });

    test('parses file_search_call items', () {
      final response = OpenAIResponsesResponse({
        'output': [
          {
            'type': 'file_search_call',
            'id': 'fs_1',
            'queries': ['what is dart?'],
            'results': [
              {
                'attributes': {'tag': 'docs'},
                'file_id': 'file_1',
                'filename': 'dart.md',
                'score': 0.95,
                'text': 'Dart is a client-optimized language...',
              },
            ],
          },
        ],
      });

      final calls = response.fileSearchCalls;
      expect(calls, isNotNull);
      expect(calls, hasLength(1));

      final call = calls!.first;
      expect(call.id, equals('fs_1'));
      expect(call.queries, equals(['what is dart?']));
      expect(call.results, isNotNull);
      expect(call.results, hasLength(1));

      final resultItem = call.results!.first;
      expect(resultItem.fileId, equals('file_1'));
      expect(resultItem.filename, equals('dart.md'));
      expect(resultItem.score, closeTo(0.95, 1e-6));
      expect(resultItem.text, contains('Dart is a client-optimized'));
      expect(resultItem.attributes['tag'], equals('docs'));
    });

    test('parses code_interpreter_call items', () {
      final response = OpenAIResponsesResponse({
        'output': [
          {
            'type': 'code_interpreter_call',
            'id': 'ci_1',
            'container_id': 'cont_1',
            'code': 'print("hello")',
            'outputs': [
              {'type': 'logs', 'logs': 'hello\n'},
              {'type': 'image', 'url': 'https://images.example.com/out.png'},
            ],
          },
        ],
      });

      final calls = response.codeInterpreterCalls;
      expect(calls, isNotNull);
      expect(calls, hasLength(1));

      final call = calls!.first;
      expect(call.id, equals('ci_1'));
      expect(call.containerId, equals('cont_1'));
      expect(call.code, equals('print("hello")'));
      expect(call.outputs, isNotNull);
      expect(call.outputs, hasLength(2));

      final logs = call.outputs![0];
      expect(logs.type, equals('logs'));
      expect(logs.logs, equals('hello\n'));

      final image = call.outputs![1];
      expect(image.type, equals('image'));
      expect(image.url, equals('https://images.example.com/out.png'));
    });

    test('parses image_generation_call items', () {
      final response = OpenAIResponsesResponse({
        'output': [
          {
            'type': 'image_generation_call',
            'id': 'img_1',
            'result': 'image://some-result-token',
          },
        ],
      });

      final calls = response.imageGenerationCalls;
      expect(calls, isNotNull);
      expect(calls, hasLength(1));

      final call = calls!.first;
      expect(call.id, equals('img_1'));
      expect(call.result, equals('image://some-result-token'));
    });

    test('returns null when no matching tool calls are present', () {
      final response = OpenAIResponsesResponse({
        'output': [
          {
            'type': 'message',
            'id': 'msg_1',
            'role': 'assistant',
            'content': [
              {'type': 'output_text', 'text': 'Hello'},
            ],
          },
        ],
      });

      expect(response.webSearchCalls, isNull);
      expect(response.fileSearchCalls, isNull);
      expect(response.codeInterpreterCalls, isNull);
      expect(response.imageGenerationCalls, isNull);
    });
  });
}
