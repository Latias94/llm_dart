import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_xai/responses.dart';
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
    final dir = Directory('test/fixtures/xai/responses');
    final fixtures = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList(growable: false)
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in fixtures) {
      final name = file.uri.pathSegments.last;
      test('parses $name', () async {
        final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

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
          ((meta['sources'] as List?)?.length ?? 0),
          equals(_countUrlCitations(raw)),
        );

        final calls = meta['serverToolCalls'] as List?;
        final expectedType = _firstServerToolType(raw);
        if (expectedType != null) {
          expect(calls, isNotNull);
          expect((calls!.first as Map)['type'], equals(expectedType));
        }
      });
    }
  });
}
