import 'package:llm_dart_openai/llm_dart_openai.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIResponsesResponse.providerMetadata', () {
    test('should expose web search calls and annotations', () {
      final response = OpenAIResponsesResponse({
        'id': 'resp_123',
        'model': 'gpt-4o-search-preview',
        'output': [
          {
            'type': 'file_search_call',
            'id': 'fs_1',
            'status': 'completed',
            'queries': ['what is llm_dart?'],
            'results': [
              {
                'file_id': 'file_1',
                'filename': 'doc.pdf',
                'score': 0.9,
                'text': '...',
                'attributes': {},
              }
            ],
          },
          {
            'type': 'computer_call',
            'id': 'cc_1',
            'status': 'in_progress',
          },
          {
            'type': 'web_search_call',
            'id': 'ws_search',
            'status': 'completed',
            'action': {
              'type': 'search',
              'query': 'llm_dart repo structure',
              'sources': [
                {'type': 'url', 'url': 'https://example.com/a'},
                {'type': 'api', 'name': 'example-api'},
              ],
            },
          },
          {
            'type': 'web_search_call',
            'id': 'ws_open',
            'status': 'completed',
            'action': {
              'type': 'open_page',
              'url': 'https://example.com/page',
            },
          },
          {
            'type': 'web_search_call',
            'id': 'ws_find',
            'status': 'completed',
            'action': {
              'type': 'find_in_page',
              'url': 'https://example.com/page',
              'pattern': 'pricing',
            },
          },
          {
            'type': 'message',
            'id': 'msg_1',
            'status': 'completed',
            'role': 'assistant',
            'content': [
              {
                'type': 'output_text',
                'text': 'Hello',
                'annotations': [
                  {
                    'type': 'url_citation',
                    'url': 'https://example.com/a',
                    'start_index': 0,
                    'end_index': 5,
                  }
                ],
              }
            ],
          },
        ],
      });

      final metadata = response.providerMetadata!;
      final openai = metadata['openai'] as Map<String, dynamic>;

      expect(openai['id'], equals('resp_123'));
      expect(openai['model'], equals('gpt-4o-search-preview'));

      final fileSearchCalls = openai['fileSearchCalls'] as List;
      expect(fileSearchCalls, hasLength(1));
      expect(
        fileSearchCalls.single,
        equals({
          'id': 'fs_1',
          'status': 'completed',
          'queries': ['what is llm_dart?'],
          'results': [
            {
              'file_id': 'file_1',
              'filename': 'doc.pdf',
              'score': 0.9,
              'text': '...',
              'attributes': {},
            }
          ],
        }),
      );

      final computerCalls = openai['computerCalls'] as List;
      expect(computerCalls, hasLength(1));
      expect(
        computerCalls.single,
        equals({'id': 'cc_1', 'status': 'in_progress'}),
      );

      final webSearchCalls = openai['webSearchCalls'] as List;
      expect(webSearchCalls, hasLength(3));

      expect(
        webSearchCalls[0],
        equals({
          'id': 'ws_search',
          'status': 'completed',
          'action': {'type': 'search', 'query': 'llm_dart repo structure'},
          'sources': [
            {'type': 'url', 'url': 'https://example.com/a'},
            {'type': 'api', 'name': 'example-api'},
          ],
        }),
      );
      expect(
        webSearchCalls[1],
        equals({
          'id': 'ws_open',
          'status': 'completed',
          'action': {'type': 'openPage', 'url': 'https://example.com/page'},
        }),
      );
      expect(
        webSearchCalls[2],
        equals({
          'id': 'ws_find',
          'status': 'completed',
          'action': {
            'type': 'findInPage',
            'url': 'https://example.com/page',
            'pattern': 'pricing',
          },
        }),
      );

      final annotations = openai['annotations'] as List;
      expect(annotations, hasLength(1));
      expect(
        annotations.single,
        containsPair('type', 'url_citation'),
      );
    });

    test('should not treat web search calls as function toolCalls', () {
      final response = OpenAIResponsesResponse({
        'id': 'resp_123',
        'model': 'gpt-4o-search-preview',
        'output': [
          {
            'type': 'web_search_call',
            'id': 'ws_search',
            'status': 'completed',
            'action': {'type': 'search', 'query': 'test'},
          },
        ],
      });

      expect(response.toolCalls, isNull);
    });
  });
}
