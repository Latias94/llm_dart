import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

import '../../utils/fakes/google_fake_client.dart';

void main() {
  group('GoogleChat chatStream malformed chunks', () {
    test('emits InvalidStreamPartError with last json chunk', () async {
      final config = const GoogleConfig(
        apiKey: 'test-key',
        model: 'gemini-2.5-pro',
      );

      final client = FakeGoogleClient(config)
        ..streamResponse = Stream.fromIterable([
          'data: {"candidates":{}}\n\n',
        ]);

      final chat = GoogleChat(client, config);

      final parts =
          await chat.chatStreamParts([ChatMessage.user('hi')]).toList();

      final errors = parts.whereType<LLMErrorPart>().toList();
      expect(errors, hasLength(1));

      final error = errors.single.error;
      expect(error, isA<InvalidStreamPartError>());
      expect(
        (error as InvalidStreamPartError).chunk,
        equals({'candidates': {}}),
      );
    });
  });
}
