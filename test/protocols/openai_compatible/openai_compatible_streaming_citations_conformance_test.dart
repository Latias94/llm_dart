import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
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

  @override
  Future<({Stream<String> stream, Map<String, String> headers})>
      postStreamRawWithHeaders(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    return (stream: _stream, headers: const <String, String>{});
  }
}

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('OpenAI-compatible streaming citations conformance', () {
    test('maps Chat Completions annotations.url_citation into source parts',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'openai-compatible',
        providerName: 'OpenAI-compatible',
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1/',
        model: 'gpt-4o-mini',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {
                'content': 'Hello',
                'annotations': [
                  {
                    'url_citation': {
                      'url': 'https://example.com/a',
                      'title': 'A',
                    }
                  },
                  {
                    // Duplicate citation should be deduped.
                    'url_citation': {
                      'url': 'https://example.com/a',
                      'title': 'A (dup)',
                    }
                  },
                ],
              },
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'stop',
            }
          ],
        }),
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, hasLength(1));
      expect(sources.single.url, equals('https://example.com/a'));
      expect(sources.single.title, equals('A'));
      expect(sources.single.providerMetadata, isNotNull);
      expect(
        sources.single.providerMetadata!.containsKey('openai-compatible'),
        isTrue,
      );

      final md = sources.single.providerMetadata!['openai-compatible'];
      expect(md, isA<Map<String, dynamic>>());
      expect((md as Map<String, dynamic>)['type'], equals('url_citation'));

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Hello'));
    });

    test('maps xAI top-level citations into source parts and providerMetadata',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai',
        providerName: 'xAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-4-latest',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_x',
          'model': 'grok-4-latest',
          'citations': [
            'https://example.com/1',
            'https://example.com/2',
            'https://example.com/2', // dup
          ],
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hi'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_x',
          'model': 'grok-4-latest',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'stop',
            }
          ],
        }),
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources.map((s) => s.url).toSet(),
          equals({'https://example.com/1', 'https://example.com/2'}));

      // xAI citations also appear in providerMetadata for round-tripping.
      final finish = parts.whereType<LLMFinishPart>().single;
      final md = finish.response.providerMetadata;
      expect(md, isNotNull);
      expect(md!['xai']['citations'],
          equals(['https://example.com/1', 'https://example.com/2']));
      expect(md.containsKey('xai.chat'), isFalse);
    });
  });
}
