import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('GoogleChat chatStream SSE', () {
    test('emits text delta and completion for SSE data blocks', () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream.fromIterable([
          'data: {"candidates":[{"content":{"parts":[{"text":"Hello"}],"role":"model"},"finishReason":"STOP","index":0}],"usageMetadata":{"totalTokenCount":3}}\n\n',
        ]);

      final chat = GoogleChat(client, config);

      final events = await chat
          .chatStream([ChatMessage.user('hi')])
          .where((e) => e is TextDeltaEvent || e is CompletionEvent)
          .toList();

      expect(events.whereType<TextDeltaEvent>().map((e) => e.delta).join(),
          equals('Hello'));
      expect(events.whereType<CompletionEvent>(), isNotEmpty);
    });

    test('detects SSE when stream starts with comment lines', () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream.fromIterable([
          ': keep-alive\n\n',
          'data: {"candidates":[{"content":{"parts":[{"text":"Hello"}],"role":"model"},"finishReason":"STOP","index":0}]}\n\n',
        ]);

      final chat = GoogleChat(client, config);

      final events = await chat
          .chatStream([ChatMessage.user('hi')])
          .where((e) => e is TextDeltaEvent || e is CompletionEvent)
          .toList();

      expect(
        events.whereType<TextDeltaEvent>().map((e) => e.delta).join(),
        equals('Hello'),
      );
      expect(events.whereType<CompletionEvent>(), isNotEmpty);
    });

    test('emits completion when stream ends with [DONE] without finishReason',
        () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream.fromIterable([
          'data: {"candidates":[{"content":{"parts":[{"text":"Hello"}],"role":"model"},"index":0}]}\n\n',
          'data: [DONE]\n\n',
        ]);

      final chat = GoogleChat(client, config);

      final events = await chat
          .chatStream([ChatMessage.user('hi')])
          .where((e) => e is TextDeltaEvent || e is CompletionEvent)
          .toList();

      expect(
        events.whereType<TextDeltaEvent>().map((e) => e.delta).join(),
        equals('Hello'),
      );
      expect(events.whereType<CompletionEvent>(), hasLength(1));

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.providerMetadata, isNotNull);
    });
  });
}
