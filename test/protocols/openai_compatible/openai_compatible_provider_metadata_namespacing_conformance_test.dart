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
}

String _sseData(Map<String, dynamic> json) => 'data: ${jsonEncode(json)}\n\n';

void main() {
  group('OpenAI-compatible providerMetadata namespacing conformance', () {
    test('uses providerId and providerId.chat keys (groq-openai)', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'groq-openai',
        providerName: 'Groq (OpenAI-compatible)',
        apiKey: 'test-key',
        baseUrl: 'https://api.groq.com/openai/v1/',
        model: 'llama-3.3-70b-versatile',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'llama-3.3-70b-versatile',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_1',
          'model': 'llama-3.3-70b-versatile',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hello'},
              'finish_reason': 'stop',
            }
          ],
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
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);

      expect(meta!.containsKey('groq-openai'), isTrue);
      expect(meta.containsKey('groq-openai.chat'), isTrue);
      expect(meta['groq-openai.chat'], equals(meta['groq-openai']));

      // Ensure we do not accidentally inject a different namespace.
      expect(meta.containsKey('groq'), isFalse);
      expect(meta.containsKey('groq.chat'), isFalse);

      final typed = finish.finishReason;
      expect(typed, isNotNull);
      expect(typed!.unified, equals(LLMUnifiedFinishReason.stop));
      expect(typed.raw, equals('stop'));

      final usage = finish.response.usage;
      expect(usage, isNotNull);
      expect(usage!.totalTokens, equals(5));
    });

    test('captures citations for xai-openai under providerId key', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'xai-openai',
        providerName: 'xAI (OpenAI-compatible)',
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
      expect(
        sources.map((s) => s.url).toSet(),
        equals({'https://example.com/1', 'https://example.com/2'}),
      );

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);

      expect(meta!.containsKey('xai-openai'), isTrue);
      expect(meta.containsKey('xai-openai.chat'), isTrue);
      expect(meta['xai-openai.chat'], equals(meta['xai-openai']));

      expect(
        (meta['xai-openai'] as Map<String, dynamic>)['citations'],
        equals(['https://example.com/1', 'https://example.com/2']),
      );
    });

    test('uses providerId and providerId.chat keys (google-openai)', () async {
      final config = OpenAICompatibleConfig(
        providerId: 'google-openai',
        providerName: 'Google Gemini (OpenAI-compatible)',
        apiKey: 'test-key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/',
        model: 'gemini-2.0-flash',
      );

      final chunks = <String>[
        _sseData({
          'id': 'chatcmpl_g',
          'model': 'gemini-2.0-flash',
          'choices': [
            {
              'index': 0,
              'delta': {'content': 'Hi'},
            }
          ],
        }),
        _sseData({
          'id': 'chatcmpl_g',
          'model': 'gemini-2.0-flash',
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

      final finish = parts.whereType<LLMFinishPart>().single;
      final meta = finish.response.providerMetadata;
      expect(meta, isNotNull);

      expect(meta!.containsKey('google-openai'), isTrue);
      expect(meta.containsKey('google-openai.chat'), isTrue);
      expect(meta['google-openai.chat'], equals(meta['google-openai']));

      expect(meta.containsKey('google'), isFalse);
      expect(meta.containsKey('google.chat'), isFalse);
    });
  });
}
