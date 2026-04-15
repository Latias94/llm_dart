// ignore_for_file: avoid_print

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

Future<void> main() async {
  final controller = ChatController(
    session: DefaultChatSession(
      transport: HttpChatTransport(
        endpoint: Uri.parse('https://backend.example/chat'),
        transport: _InProcessBackendTransport(_DemoFlutterBackend()),
        prepareSendMessagesRequest: (context) {
          return HttpChatTransportPreparedSendMessagesRequest(
            headers: {
              ...context.headers,
              'x-app-surface': 'flutter',
            },
            payload: HttpChatTransportRequestPayload(
              chatId: context.payload.chatId,
              prompt: context.payload.prompt,
              generateOptions: context.payload.generateOptions,
              streamProtocol: context.payload.streamProtocol,
              metadata: {
                ...context.payload.metadata,
                'tenantId': 'acme-mobile',
                'providerProfile': 'anthropic-thinking',
                'screen': 'chat-home',
              },
            ),
          );
        },
      ),
    ),
  );

  controller.addListener(() {
    _printState(controller.state);
  });

  try {
    await controller.sendMessage(
      ChatInput.text('Plan a short release-summary message for the user.'),
      options: const ChatRequestOptions(
        generateOptions: GenerateTextOptions(
          maxOutputTokens: 180,
          temperature: 0.1,
        ),
        metadata: {
          'clientRequestId': 'flutter-client-1',
        },
      ),
    );

    await _waitUntilReady(controller);

    final latest = controller.state.messages.last;
    final mapped = const ChatMessageMapper().map(latest);

    print('\nFinal assistant text:');
    print(mapped.text);

    print('\nMessage metadata:');
    print(latest.metadata);
  } finally {
    await controller.close();
  }
}

Future<void> _waitUntilReady(ChatController controller) async {
  if (controller.status == ChatStatus.ready) {
    return;
  }

  await controller.session.states.firstWhere(
    (state) => state.status == ChatStatus.ready,
  );
}

void _printState(ChatState state) {
  print('status=${state.status}');

  if (state.messages.isEmpty) {
    return;
  }

  final latest = state.messages.last;
  if (latest.role != ChatUiRole.assistant) {
    return;
  }

  final mapped = const ChatMessageMapper().map(latest);
  if (mapped.text.isNotEmpty) {
    print('assistantText=${mapped.text}');
  }
}

final class _InProcessBackendTransport implements TransportClient {
  final _DemoFlutterBackend backend;

  const _InProcessBackendTransport(this.backend);

  @override
  Future<TransportResponse> send(TransportRequest request) {
    throw UnsupportedError('This demo only supports streaming chat requests.');
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

final class _DemoFlutterBackend {
  static const _requestCodec = HttpChatTransportRequestJsonCodec();
  static const _adapter = HttpChatTransportServerAdapter();

  Stream<List<int>> handle(TransportRequest request) {
    final payload = _requestCodec.decodeRequest(request.body);
    final plan = _BackendExecutionPlan.fromMetadata(payload.metadata);

    return _adapter.encodeEventSseStream(
      eventStream: _eventStream(
        plan: plan,
        prompt: _latestUserText(payload.prompt),
        generateOptions: payload.generateOptions,
      ),
      requestId: 'flutter-backend-${payload.chatId}',
      messageId: 'assistant-${payload.chatId}',
      messageMetadata: {
        'backendPlan': plan.toJson(),
        'clientRequestId': payload.metadata['clientRequestId'],
      },
      finalMessageMetadata: const {
        'backendCompleted': true,
        'uiSurface': 'flutter',
      },
    );
  }

  Stream<TextStreamEvent> _eventStream({
    required _BackendExecutionPlan plan,
    required String prompt,
    required GenerateTextOptions generateOptions,
  }) async* {
    yield StartEvent();
    yield ResponseMetadataEvent(
      responseId: 'flutter-resp-1',
      modelId: plan.modelId,
      providerMetadata: ProviderMetadata({
        'backend': {
          'providerProfile': plan.profile,
          'uiSurface': 'flutter',
        },
      }),
    );
    yield const TextStartEvent(id: 'text-1');
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'Flutter controller is using backend-owned ${plan.providerId} ',
    );
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'routing with ${plan.description}. ',
    );
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'Shared maxOutputTokens=${generateOptions.maxOutputTokens}. ',
    );
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'Prompt summary: "$prompt"',
    );
    yield const TextEndEvent(id: 'text-1');
    yield const FinishEvent(
      finishReason: FinishReason.stop,
    );
  }

  String _latestUserText(List<PromptMessage> prompt) {
    for (final message in prompt.reversed) {
      if (message is! UserPromptMessage) {
        continue;
      }

      final text = message.parts
          .whereType<TextPromptPart>()
          .map((part) => part.text)
          .join(' ')
          .trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'no user text';
  }
}

final class _BackendExecutionPlan {
  final String profile;
  final String providerId;
  final String modelId;
  final String description;
  final Map<String, Object?> providerOptionsPreview;

  _BackendExecutionPlan({
    required this.profile,
    required this.providerId,
    required this.modelId,
    required this.description,
    required Map<String, Object?> providerOptionsPreview,
  }) : providerOptionsPreview = Map.unmodifiable(providerOptionsPreview);

  factory _BackendExecutionPlan.fromMetadata(Map<String, Object?> metadata) {
    return switch (metadata['providerProfile']) {
      'openai-web-search' => _BackendExecutionPlan(
          profile: 'openai-web-search',
          providerId: 'openai',
          modelId: 'gpt-4.1-mini',
          description: 'OpenAI built-in web-search options',
          providerOptionsPreview: const {
            'openai': {
              'builtInTools': ['web_search_preview'],
            },
          },
        ),
      _ => _BackendExecutionPlan(
          profile: 'anthropic-thinking',
          providerId: 'anthropic',
          modelId: 'claude-sonnet-4-5',
          description: 'Anthropic extended-thinking options',
          providerOptionsPreview: const {
            'anthropic': {
              'extendedThinking': true,
              'thinkingBudgetTokens': 2048,
            },
          },
        ),
    };
  }

  Map<String, Object?> toJson() {
    return {
      'profile': profile,
      'providerId': providerId,
      'modelId': modelId,
      'description': description,
      'providerOptionsPreview': providerOptionsPreview,
    };
  }
}
