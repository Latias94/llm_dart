import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';
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

String _extractOutputText(Map<String, dynamic> response) {
  final output = response['output'] as List?;
  if (output == null) return '';

  final buf = StringBuffer();
  for (final item in output) {
    if (item is! Map) continue;
    if (item['type'] != 'message') continue;
    final content = item['content'] as List?;
    if (content == null) continue;
    for (final part in content) {
      if (part is! Map) continue;
      if (part['type'] != 'output_text') continue;
      final text = part['text'];
      if (text is String) buf.write(text);
    }
  }
  return buf.toString();
}

int _countUrlCitations(Map<String, dynamic> response) {
  final output = response['output'] as List?;
  if (output == null) return 0;

  var count = 0;
  for (final item in output) {
    if (item is! Map) continue;
    if (item['type'] != 'message') continue;
    final content = item['content'] as List?;
    if (content == null) continue;
    for (final part in content) {
      if (part is! Map) continue;
      final annotations = part['annotations'] as List?;
      if (annotations == null) continue;
      for (final a in annotations) {
        if (a is! Map) continue;
        if (a['type'] == 'url_citation') count++;
      }
    }
  }
  return count;
}

String? _firstServerToolType(Map<String, dynamic> response) {
  final output = response['output'] as List?;
  if (output == null) return null;
  for (final item in output) {
    if (item is! Map) continue;
    final type = item['type'];
    if (type is String && type.endsWith('_call')) return type;
  }
  return null;
}

void main() {
  group('xAI Responses non-streaming fixtures (Vercel)', () {
    test('parses web_search_call response JSON', () async {
      const fixturePath =
          'repo-ref/ai/packages/xai/src/responses/__fixtures__/xai-web-search-tool.1.json';
      final raw = jsonDecode(File(fixturePath).readAsStringSync())
          as Map<String, dynamic>;

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: raw['model'] as String? ?? 'grok-4-fast',
      );

      final client = _FakeJsonOpenAIClient(config, response: raw);
      final responses = XAIResponses(client, config);

      final response = await responses.chat([ChatMessage.user('Hi')]);

      expect(response.text, equals(_extractOutputText(raw)));
      expect(response.thinking, isNull);
      expect(response.toolCalls, isNull);

      final meta = response.providerMetadata?['xai.responses'];
      expect(meta, isNotNull);
      expect(meta!['id'], equals(raw['id']));
      expect(meta['model'], equals(raw['model']));
      expect(meta['status'], equals(raw['status']));
      expect(
          (meta['sources'] as List?)?.length, equals(_countUrlCitations(raw)));

      final calls = meta['serverToolCalls'] as List?;
      expect(calls, isNotNull);
      expect((calls!.first as Map)['type'], equals(_firstServerToolType(raw)));
    });

    test('parses x_search_call response JSON', () async {
      const fixturePath =
          'repo-ref/ai/packages/xai/src/responses/__fixtures__/xai-x-search-tool.1.json';
      final raw = jsonDecode(File(fixturePath).readAsStringSync())
          as Map<String, dynamic>;

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: raw['model'] as String? ?? 'grok-4-fast',
      );

      final client = _FakeJsonOpenAIClient(config, response: raw);
      final responses = XAIResponses(client, config);

      final response = await responses.chat([ChatMessage.user('Hi')]);

      expect(response.text, equals(_extractOutputText(raw)));
      expect(response.thinking, isNull);
      expect(response.toolCalls, isNull);

      final meta = response.providerMetadata?['xai.responses'];
      expect(meta, isNotNull);
      final calls = meta!['serverToolCalls'] as List?;
      expect(calls, isNotNull);
      expect((calls!.first as Map)['type'], equals('x_search_call'));
    });

    test('parses code_interpreter_call response JSON', () async {
      const fixturePath =
          'repo-ref/ai/packages/xai/src/responses/__fixtures__/xai-code-execution-tool.1.json';
      final raw = jsonDecode(File(fixturePath).readAsStringSync())
          as Map<String, dynamic>;

      final config = OpenAICompatibleConfig(
        providerId: 'xai.responses',
        providerName: 'xAI (Responses)',
        apiKey: 'test-key',
        baseUrl: 'https://api.x.ai/v1/',
        model: raw['model'] as String? ?? 'grok-4-fast',
      );

      final client = _FakeJsonOpenAIClient(config, response: raw);
      final responses = XAIResponses(client, config);

      final response = await responses.chat([ChatMessage.user('Hi')]);

      expect(response.text, equals(_extractOutputText(raw)));
      expect(response.thinking, isNull);
      expect(response.toolCalls, isNull);

      final meta = response.providerMetadata?['xai.responses'];
      expect(meta, isNotNull);
      final calls = meta!['serverToolCalls'] as List?;
      expect(calls, isNotNull);
      expect((calls!.first as Map)['type'], equals('code_interpreter_call'));
    });
  });
}
