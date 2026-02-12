import 'dart:convert';

import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
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
    CancelToken? cancelToken,
  }) async {
    return (stream: _stream, headers: const <String, String>{});
  }
}

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('OpenAI-compatible streaming usage tail conformance', () {
    test(
        'chatStreamParts captures usage from trailing chunk after finish_reason',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'azure-openai',
        providerName: 'Azure OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://azure.example.com/v1/',
        model: 'gpt-4o-mini',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'system_fingerprint': 'fp_1',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello'},
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
        // Azure may send usage in a trailing chunk with empty choices.
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'gpt-4o-mini',
          'choices': [],
          'usage': {
            'prompt_tokens': 3,
            'completion_tokens': 2,
            'total_tokens': 5,
          },
        }),
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.response.text, equals('Hello'));
      expect(finish.response.providerMetadata, isNotNull);
      expect(finish.response.providerMetadata!['azure-openai']['finishReason'],
          equals('stop'));

      final usage = finish.response.usage;
      expect(usage, isNotNull);
      expect(usage!.promptTokens, equals(3));
      expect(usage.completionTokens, equals(2));
      expect(usage.totalTokens, equals(5));
    });

    test('chatStreamParts maps cached and reasoning tokens into UsageInfo',
        () async {
      final config = OpenAICompatibleConfig(
        providerId: 'azure-openai',
        providerName: 'Azure OpenAI',
        apiKey: 'test-key',
        baseUrl: 'https://azure.example.com/v1/',
        model: 'gpt-4o-mini',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_2',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_2',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_2',
          'model': 'gpt-4o-mini',
          'choices': [
            {
              'index': 0,
              'delta': <String, dynamic>{},
              'finish_reason': 'stop',
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_2',
          'model': 'gpt-4o-mini',
          'choices': [],
          'usage': {
            'prompt_tokens': 10,
            'completion_tokens': 9,
            'total_tokens': 19,
            'prompt_tokens_details': {'cached_tokens': 7},
            'completion_tokens_details': {'reasoning_tokens': 4},
          },
        }),
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final finish = parts.whereType<LLMFinishPart>().single;
      final usage = finish.response.usage!;
      expect(usage.promptTokens, equals(10));
      expect(usage.completionTokens, equals(9));
      expect(usage.promptTokensCacheRead, equals(7));
      expect(usage.promptTokensNoCache, equals(3));
      expect(usage.reasoningTokens, equals(4));
      expect(usage.completionTokensText, equals(5));
      expect(usage.raw, isNotNull);
    });
  });
}
