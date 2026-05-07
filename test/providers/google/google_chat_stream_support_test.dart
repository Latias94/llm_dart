import 'package:llm_dart/core/capability.dart';
import 'package:llm_dart/providers/google/config.dart';
import 'package:llm_dart/src/compatibility/providers/google/client.dart';
import 'package:llm_dart/src/compatibility/providers/google/google_chat_stream_support.dart';
import 'package:test/test.dart';

void main() {
  group('Google chat stream support extraction', () {
    test('preserves split SSE frames across transport chunks', () {
      final support = _buildSupport();

      final events = _collectEvents(support, const [
        'data: {"candidates":[{"content":{"parts":[{"text":"Hel',
        'lo"}]},"finishReason":"STOP"}],"usageMetadata":{"candidatesTokenCount":2}}\n\n',
      ]);

      expect(
        events.whereType<TextDeltaEvent>().map((event) => event.delta),
        ['Hello'],
      );

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.usage?.completionTokens, 2);
    });

    test('skips malformed SSE payloads and keeps parsing later frames', () {
      final support = _buildSupport();

      final events = _collectEvents(support, const [
        'data: {not-json}\n\n',
        'data: {"candidates":[{"content":{"parts":[{"text":"Hi"}]},'
            '"finishReason":"STOP"}],"usageMetadata":{"candidatesTokenCount":1}}\n\n',
      ]);

      expect(events.whereType<TextDeltaEvent>().map((event) => event.delta), [
        'Hi',
      ]);
      expect(events.whereType<CompletionEvent>(), hasLength(1));
    });

    test('preserves split non-SSE JSON array chunks', () {
      final support = _buildSupport();

      final events = _collectEvents(support, const [
        '[{"candidates":[{"content":{"parts":[{"text":"Hel',
        'lo"}]}}]}]',
      ]);

      expect(
        events.whereType<TextDeltaEvent>().map((event) => event.delta),
        ['Hello'],
      );
    });

    test('maps thinking, generated images, and completion metadata', () {
      final support = _buildSupport();

      final events = _collectEvents(support, const [
        'data: {"candidates":[{"content":{"parts":[{"thought":true,"text":"Plan carefully."},{"inlineData":{"mimeType":"image/png","data":"AA=="}}]},"finishReason":"STOP"}],"usageMetadata":{"promptTokenCount":3,"candidatesTokenCount":7,"totalTokenCount":10,"thoughtsTokenCount":2}}\n\n',
      ]);

      expect(
        events.whereType<ThinkingDeltaEvent>().map((event) => event.delta),
        ['Plan carefully.'],
      );
      expect(
        events.whereType<TextDeltaEvent>().map((event) => event.delta),
        ['[Generated image: image/png]'],
      );

      final completion = events.whereType<CompletionEvent>().single;
      expect(completion.response.usage?.promptTokens, 3);
      expect(completion.response.usage?.completionTokens, 7);
      expect(completion.response.usage?.totalTokens, 10);
      expect(completion.response.usage?.reasoningTokens, 2);
    });

    test('maps streamed function calls into tool call events', () {
      final support = _buildSupport();

      final events = _collectEvents(support, const [
        'data: {"candidates":[{"content":{"parts":[{"functionCall":{"name":"get_wea',
        'ther","args":{"city":"Hong Kong"}}}]}}]}\n\n',
      ]);

      final toolEvent = events.whereType<ToolCallDeltaEvent>().single;
      expect(toolEvent.toolCall.id, 'call_get_weather');
      expect(toolEvent.toolCall.function.name, 'get_weather');
      expect(toolEvent.toolCall.function.arguments, '{"city":"Hong Kong"}');
    });
  });
}

GoogleChatStreamSupport _buildSupport() {
  final config = GoogleConfig(
    apiKey: 'test-key',
    model: 'gemini-2.0-flash',
  );

  return GoogleChatStreamSupport(
    client: GoogleClient(config),
  );
}

List<ChatStreamEvent> _collectEvents(
  GoogleChatStreamSupport support,
  List<String> chunks,
) {
  final events = <ChatStreamEvent>[];
  for (final chunk in chunks) {
    events.addAll(support.parseChunk(chunk));
  }
  return events;
}
