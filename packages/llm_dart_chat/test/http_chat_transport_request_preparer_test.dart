import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_chat/src/http_chat_transport_request_preparer.dart';
import 'package:test/test.dart';

void main() {
  group('HttpChatTransportRequestPreparer', () {
    test('prepares send payloads with hook overrides', () async {
      final preparer = HttpChatTransportRequestPreparer(
        endpoint: Uri.parse('https://example.com/chat'),
        headers: const {
          'x-base': '1',
        },
        requestTimeout: const Duration(seconds: 3),
        requestCodec: const HttpChatTransportRequestJsonCodec(),
        streamProtocol: HttpChatTransportStreamProtocol.uiMessageStreamV2,
        providerOptionsEncoder: null,
        prepareSendMessagesRequest: (context) {
          expect(context.endpoint, Uri.parse('https://example.com/chat'));
          expect(context.headers['accept'], 'text/event-stream');
          expect(context.requestTimeout, const Duration(seconds: 3));

          return HttpChatTransportPreparedSendMessagesRequest(
            endpoint: Uri.parse('https://example.com/prepared'),
            headers: {
              ...context.headers,
              'x-prepared': '1',
            },
            requestTimeout: const Duration(seconds: 9),
            overrideRequestTimeout: true,
            payload: HttpChatTransportRequestPayload(
              chatId: context.payload.chatId,
              prompt: context.payload.prompt,
              metadata: const {
                'prepared': true,
              },
            ),
          );
        },
        prepareReconnectRequest: null,
      );
      final request = ChatTransportRequest(
        chatId: 'chat-1',
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
      );
      final state = preparer.createSendMessagesState(request);

      final prepared = await preparer.prepareSendMessages(
        request: request,
        state: state,
      );

      expect(prepared.endpoint, Uri.parse('https://example.com/prepared'));
      expect(prepared.headers['x-prepared'], '1');
      expect(prepared.requestTimeout, const Duration(seconds: 9));

      final decoded = const HttpChatTransportRequestJsonCodec().decodeRequest(
        prepared.payload,
      );
      expect(decoded.chatId, 'chat-1');
      expect(decoded.metadata['prepared'], isTrue);
    });

    test('prepares reconnect payloads with hook overrides', () async {
      final preparer = HttpChatTransportRequestPreparer(
        endpoint: Uri.parse('https://example.com/chat'),
        headers: const {},
        requestTimeout: const Duration(seconds: 3),
        requestCodec: const HttpChatTransportRequestJsonCodec(),
        streamProtocol: HttpChatTransportStreamProtocol.uiMessageStreamV2,
        providerOptionsEncoder: null,
        prepareSendMessagesRequest: null,
        prepareReconnectRequest: (context) {
          expect(context.chatId, 'chat-1');
          expect(context.resumeToken, 'resume-1');

          return HttpChatTransportPreparedReconnectRequest(
            endpoint: Uri.parse('https://example.com/reconnect'),
            requestTimeout: const Duration(seconds: 5),
            overrideRequestTimeout: true,
            payload: HttpChatTransportReconnectRequestPayload(
              chatId: context.payload.chatId,
              resumeToken: context.payload.resumeToken,
              metadata: const {
                'resumeClient': 'mobile',
              },
            ),
          );
        },
      );
      final request = ChatTransportRequest(
        chatId: 'chat-1',
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
      );
      final state = preparer.createSendMessagesState(request);

      final prepared = await preparer.prepareReconnect(
        chatId: 'chat-1',
        resumeToken: 'resume-1',
        state: state,
      );

      expect(prepared.endpoint, Uri.parse('https://example.com/reconnect'));
      expect(prepared.requestTimeout, const Duration(seconds: 5));

      final decoded =
          const HttpChatTransportRequestJsonCodec().decodeReconnectRequest(
        prepared.payload,
      );
      expect(decoded.resumeToken, 'resume-1');
      expect(decoded.metadata['resumeClient'], 'mobile');
    });
  });
}
