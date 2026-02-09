import 'dart:convert';

import 'package:llm_dart/llm_dart.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('xAI Chat Completions citations (AI SDK parity)', () {
    test('includes search_parameters.return_citations when live search enabled',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
        providerOptions: const {
          'xai': {
            'liveSearch': true,
            'returnCitations': true,
          },
        },
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'xai',
        providerName: 'xAI',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = const {
          'id': 'chatcmpl_test',
          'model': 'grok-3',
          'choices': [
            {
              'index': 0,
              'message': {
                'role': 'assistant',
                'content': 'ok',
              },
              'finish_reason': 'stop',
            }
          ],
        };

      final chat = OpenAIChat(client, config);
      await chat.chat([ChatMessage.user('Hi')]);

      final body = client.lastJsonBody;
      expect(body, isNotNull);
      expect(body!['return_citations'], isNull);
      expect(body['search_parameters'], isA<Map>());
      final sp = body['search_parameters'] as Map;
      expect(sp['return_citations'], isTrue);
      expect(sp['sources'], isA<List>());
      expect(
        (sp['sources'] as List).map((e) => (e as Map)['type']).toList(),
        equals(['web', 'x']),
      );
    });

    test('exposes citations in providerMetadata for non-stream responses',
        () async {
      final llmConfig = LLMConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
      );

      final config = OpenAICompatibleConfig.fromLLMConfig(
        llmConfig,
        providerId: 'xai',
        providerName: 'xAI',
      );

      final client = FakeOpenAIClient(config)
        ..jsonResponse = const {
          'id': 'citations-test',
          'model': 'grok-3',
          'citations': [
            'https://example.com/source1',
            'https://example.com/source2',
          ],
          'choices': [
            {
              'index': 0,
              'message': {
                'role': 'assistant',
                'content': 'Answer',
              },
              'finish_reason': 'stop',
            }
          ],
        };

      final chat = OpenAIChat(client, config);
      final response = await chat.chat([ChatMessage.user('Hi')]);

      final meta = response.providerMetadata?['xai'] as Map?;
      expect(meta, isNotNull);
      expect(
          meta!['citations'],
          equals(const [
            'https://example.com/source1',
            'https://example.com/source2',
          ]));
    });

    test('streams citations as LLMSourceUrlPart and includes them in finish',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai',
        providerName: 'xAI',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
      );

      final chunks = <String>[
        _sseData({
          'id': 'citations-stream-test',
          'model': 'grok-3',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'citations-stream-test',
          'model': 'grok-3',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello'},
            }
          ],
        }),
        _sseData({
          'id': 'citations-stream-test',
          'model': 'grok-3',
          'citations': [
            'https://example.com/source1',
            'https://example.com/source2',
          ],
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

      final parts = await chat
          .chatStreamParts([ChatMessage.user('Hi')], tools: const []).toList();

      final sources = parts.whereType<LLMSourceUrlPart>().toList();
      expect(sources, hasLength(2));
      expect(
          sources.map((s) => s.url),
          containsAll(const [
            'https://example.com/source1',
            'https://example.com/source2',
          ]));

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata?['xai'] as Map?;
      expect(meta, isNotNull);
      expect(
          meta!['citations'],
          equals(const [
            'https://example.com/source1',
            'https://example.com/source2',
          ]));
    });
  });
}
