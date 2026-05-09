import 'package:llm_dart/chat.dart' as chat;
import 'package:test/test.dart';

void main() {
  group('Root chat entrypoint', () {
    test('exports the pure Dart chat runtime and model factories', () async {
      final model = chat.openai(apiKey: 'test-key').chatModel('gpt-5-mini');
      final transport = chat.DirectChatTransport(model: model);
      final session = chat.DefaultChatSession(transport: transport);
      const options = chat.ChatRequestOptions(
        metadata: {'origin': 'root-chat-entrypoint'},
      );

      expect(model.providerId, 'openai');
      expect(transport, isA<chat.ChatTransport>());
      expect(session, isA<chat.ChatSession>());
      expect(options.metadata['origin'], 'root-chat-entrypoint');
      expect(chat.ChatTransportTrigger.sendMessage,
          isA<chat.ChatTransportTrigger>());
      expect(chat.HttpChatTransport, isA<Type>());

      await session.dispose();
    });
  });
}
