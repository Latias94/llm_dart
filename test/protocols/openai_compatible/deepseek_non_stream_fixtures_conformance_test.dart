import 'dart:convert';
import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:test/test.dart';

import '../../utils/fakes/openai_fake_client.dart';

Map<String, dynamic> _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

Map<String, dynamic> _readJsonFixture(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  final map = _asJsonMap(decoded);
  if (map.isEmpty) {
    throw StateError('Fixture is not a JSON object: $path');
  }
  return map;
}

Map<String, dynamic>? _firstMessage(Map<String, dynamic> raw) {
  final choices = raw['choices'];
  if (choices is! List || choices.isEmpty) return null;
  final choice = _asJsonMap(choices.first);
  final message = choice['message'];
  final messageMap = _asJsonMap(message);
  return messageMap.isEmpty ? null : messageMap;
}

String? _expectedText(Map<String, dynamic> raw) {
  final message = _firstMessage(raw);
  final content = message?['content'];
  return content is String ? content : null;
}

String? _expectedThinking(Map<String, dynamic> raw) {
  final message = _firstMessage(raw);
  final reasoning = message?['reasoning_content'];
  return reasoning is String && reasoning.isNotEmpty ? reasoning : null;
}

List<ToolCall>? _expectedToolCalls(Map<String, dynamic> raw) {
  final message = _firstMessage(raw);
  final rawCalls = message?['tool_calls'];
  if (rawCalls is! List || rawCalls.isEmpty) return null;

  final calls = <ToolCall>[];
  for (final item in rawCalls) {
    final map = _asJsonMap(item);
    if (map.isEmpty) continue;
    calls.add(ToolCall.fromJson(map));
  }
  return calls.isEmpty ? null : calls;
}

void main() {
  group('OpenAI-compatible non-stream fixtures (DeepSeek, Vercel)', () {
    final dir = Directory('test/fixtures/openai_compatible');
    final fixtures = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .where((f) => f.uri.pathSegments.last.startsWith('deepseek-'))
        .toList(growable: false)
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in fixtures) {
      final name = file.uri.pathSegments.last;
      test('parses $name', () async {
        final raw = _readJsonFixture(file.path);

        final config = OpenAICompatibleConfig(
          providerId: 'deepseek',
          providerName: 'DeepSeek',
          apiKey: 'test-key',
          baseUrl: 'https://api.deepseek.com/v1/',
          model: raw['model'] as String? ?? 'deepseek-chat',
        );

        final client = FakeOpenAIClient(config)..jsonResponse = raw;
        final chat = OpenAIChat(client, config);

        final response = await chat.chat([ChatMessage.user('Hi')]);

        expect(client.lastEndpoint, equals('chat/completions'));

        expect(response.text, equals(_expectedText(raw)));
        expect(response.thinking, equals(_expectedThinking(raw)));

        final expectedCalls = _expectedToolCalls(raw);
        final actualCalls = response.toolCalls;
        if (expectedCalls == null) {
          expect(actualCalls, isNull);
        } else {
          expect(actualCalls, isNotNull);
          expect(actualCalls, hasLength(expectedCalls.length));
          for (var i = 0; i < expectedCalls.length; i++) {
            expect(actualCalls![i].toJson(), equals(expectedCalls[i].toJson()));
          }
        }

        final metadata = response.providerMetadata;
        expect(metadata, isNotNull);
        expect(metadata!.containsKey('deepseek'), isTrue);
        expect(metadata.containsKey('deepseek.chat'), isTrue);

        final payload = _asJsonMap(metadata['deepseek']);
        expect(metadata['deepseek.chat'], equals(payload));
        expect(payload['id'], equals(raw['id']));
        expect(payload['model'], equals(raw['model']));
        expect(payload['systemFingerprint'], equals(raw['system_fingerprint']));

        final choices = raw['choices'] as List?;
        final firstChoice = choices != null && choices.isNotEmpty
            ? _asJsonMap(choices.first)
            : const <String, dynamic>{};
        expect(payload['finishReason'], equals(firstChoice['finish_reason']));
      });
    }
  });
}
