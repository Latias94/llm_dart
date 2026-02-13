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
  group('OpenAI-compatible response-metadata ordering conformance', () {
    test('emits response-metadata before the first content delta', () async {
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
          'system_fingerprint': 'fp_1',
          'created': 1700000000,
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
      ];

      final client = _FakeOpenAIClient(
        config,
        stream: Stream<String>.fromIterable(chunks),
      );
      final chat = OpenAIChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('Hi')]).toList();

      final metaIndex =
          parts.indexWhere((part) => part is LLMResponseMetadataPart);
      expect(metaIndex, greaterThanOrEqualTo(0));

      final firstContentIndex = parts.indexWhere((part) =>
          part is LLMReasoningStartPart ||
          part is LLMReasoningDeltaPart ||
          part is LLMTextStartPart ||
          part is LLMTextDeltaPart ||
          part is LLMToolCallStartPart ||
          part is LLMToolInputStartPart);
      expect(firstContentIndex, greaterThanOrEqualTo(0));

      expect(metaIndex, lessThan(firstContentIndex));

      final meta = parts[metaIndex] as LLMResponseMetadataPart;
      expect(meta.id, equals('chatcmpl_1'));
      expect(meta.model, equals('gpt-4o-mini'));
      expect(meta.systemFingerprint, equals('fp_1'));
      expect(meta.timestamp, isNotNull);
    });
  });
}
