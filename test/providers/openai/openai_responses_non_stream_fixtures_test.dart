import 'dart:convert';
import 'dart:io';

import 'package:llm_dart/llm_dart.dart';
import 'package:llm_dart_openai/client.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_client;
import 'package:llm_dart_openai/responses.dart' as openai_responses;
import 'package:test/test.dart';

class _FakeJsonOpenAIClient extends OpenAIClient {
  final Map<String, dynamic> _response;

  _FakeJsonOpenAIClient(
    super.config, {
    required Map<String, dynamic> response,
  }) : _response = response;

  @override
  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    return _response;
  }
}

void main() {
  group('OpenAI Responses non-streaming fixtures (Vercel)', () {
    test('parses web_search_call + annotations + function_call', () async {
      const fixturePath =
          'test/fixtures/openai/responses/openai-web-search.1.json';
      final raw = jsonDecode(File(fixturePath).readAsStringSync())
          as Map<String, dynamic>;

      final config = openai_client.OpenAIConfig(
        apiKey: 'test-key',
        baseUrl: 'https://api.openai.com/v1/',
        model: raw['model'] as String? ?? 'gpt-4.1-mini',
        useResponsesAPI: true,
      );

      final client = _FakeJsonOpenAIClient(config, response: raw);
      final responses = openai_responses.OpenAIResponses(client, config);

      final response =
          await responses.chatWithTools([ChatMessage.user('Hi')], null);

      expect(response.text, equals('Hello'));

      final toolCalls = response.toolCalls;
      expect(toolCalls, isNotNull);
      expect(toolCalls, hasLength(1));
      expect(toolCalls!.single.function.name, equals('get_weather'));
      expect(toolCalls.single.function.arguments, contains('Beijing'));

      final meta = response.providerMetadata?['openai'];
      expect(meta, isNotNull);
      expect(meta!['id'], equals('resp_123'));
      expect(meta['model'], equals('gpt-4.1-mini'));

      final webSearchCalls = meta['webSearchCalls'] as List?;
      expect(webSearchCalls, isNotNull);
      final webSearchCall = webSearchCalls!.single as Map;
      expect(webSearchCall['id'], equals('ws_1'));
      expect((webSearchCall['action'] as Map?)?['type'], equals('openPage'));

      final annotations = meta['annotations'] as List?;
      expect(annotations, isNotNull);
      expect(annotations, hasLength(1));
      expect(
          (annotations!.single as Map)['url'], equals('https://example.com'));
    });
  });
}
