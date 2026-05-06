import 'package:flutter_test/flutter_test.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

void main() {
  group('ChatController HttpChatTransport', () {
    test('keeps provider-specific routing backend-owned', () async {
      final backend = _RecordingBackend();
      final controller = ChatController(
        session: DefaultChatSession(
          transport: HttpChatTransport(
            endpoint: Uri.parse('https://backend.example/chat'),
            transport: _InProcessBackendTransport(backend),
            prepareSendMessagesRequest: (context) {
              return HttpChatTransportPreparedSendMessagesRequest(
                payload: HttpChatTransportRequestPayload(
                  chatId: context.payload.chatId,
                  prompt: context.payload.prompt,
                  generateOptions: context.payload.generateOptions,
                  streamProtocol: context.payload.streamProtocol,
                  metadata: {
                    ...context.payload.metadata,
                    'providerProfile': 'anthropic-thinking',
                  },
                ),
              );
            },
          ),
        ),
      );

      try {
        await controller.sendMessage(
          ChatInput.text('Summarize the rollout status.'),
          options: const ChatRequestOptions(
            generateOptions: GenerateTextOptions(
              maxOutputTokens: 120,
            ),
            metadata: {
              'clientRequestId': 'flutter-test-1',
            },
          ),
        );

        expect(
          backend.lastPayload?.metadata['providerProfile'],
          'anthropic-thinking',
        );
        expect(
          backend.lastPlan?.providerOptionsPreview,
          {
            'anthropic': {
              'extendedThinking': true,
              'thinkingBudgetTokens': 2048,
            },
          },
        );

        final latest = controller.messages.last;
        final mapped = const ChatMessageMapper().map(latest);
        expect(mapped.text, contains('backend-owned anthropic'));
        expect(latest.metadata['backendCompleted'], isTrue);
      } finally {
        await controller.close();
      }
    });
  });
}

final class _InProcessBackendTransport implements TransportClient {
  final _RecordingBackend backend;

  const _InProcessBackendTransport(this.backend);

  @override
  Future<TransportResponse> send(TransportRequest request) {
    throw UnsupportedError('This test backend only supports streaming.');
  }

  @override
  Future<StreamingTransportResponse> sendStream(
      TransportRequest request) async {
    return StreamingTransportResponse(
      statusCode: 200,
      headers: const {
        'content-type': 'text/event-stream',
      },
      stream: backend.handle(request),
    );
  }
}

final class _RecordingBackend {
  static const _requestCodec = HttpChatTransportRequestJsonCodec();
  static const _adapter = HttpChatTransportServerAdapter();

  HttpChatTransportRequestPayload? lastPayload;
  _BackendExecutionPlan? lastPlan;

  Stream<List<int>> handle(TransportRequest request) {
    final payload = _requestCodec.decodeRequest(request.body);
    final plan = _BackendExecutionPlan.fromMetadata(payload.metadata);
    lastPayload = payload;
    lastPlan = plan;

    return _adapter.encodeEventSseStream(
      eventStream: _stream(plan),
      requestId: 'req-1',
      messageId: 'assistant-1',
      finalMessageMetadata: const {
        'backendCompleted': true,
      },
    );
  }

  Stream<TextStreamEvent> _stream(_BackendExecutionPlan plan) async* {
    yield StartEvent();
    yield const TextStartEvent(id: 'text-1');
    yield TextDeltaEvent(
      id: 'text-1',
      delta:
          'Flutter controller is using backend-owned ${plan.providerId} routing.',
    );
    yield const TextEndEvent(id: 'text-1');
    yield const FinishEvent(
      finishReason: FinishReason.stop,
    );
  }
}

final class _BackendExecutionPlan {
  final String providerId;
  final Map<String, Object?> providerOptionsPreview;

  _BackendExecutionPlan({
    required this.providerId,
    required Map<String, Object?> providerOptionsPreview,
  }) : providerOptionsPreview = Map.unmodifiable(providerOptionsPreview);

  factory _BackendExecutionPlan.fromMetadata(Map<String, Object?> metadata) {
    return switch (metadata['providerProfile']) {
      'openai-web-search' => _BackendExecutionPlan(
          providerId: 'openai',
          providerOptionsPreview: const {
            'openai': {
              'builtInTools': ['web_search_preview'],
            },
          },
        ),
      _ => _BackendExecutionPlan(
          providerId: 'anthropic',
          providerOptionsPreview: const {
            'anthropic': {
              'extendedThinking': true,
              'thinkingBudgetTokens': 2048,
            },
          },
        ),
    };
  }
}
