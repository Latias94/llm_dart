// ignore_for_file: avoid_print

import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

Future<void> main() async {
  final backend = _DemoChatBackend();
  final session = DefaultChatSession(
    transport: HttpChatTransport(
      endpoint: Uri.parse('https://backend.example/chat'),
      transport: _InProcessBackendTransport(backend),
      prepareSendMessagesRequest: (context) {
        return HttpChatTransportPreparedSendMessagesRequest(
          headers: {
            ...context.headers,
            'x-app-session': context.payload.chatId,
          },
          payload: HttpChatTransportRequestPayload(
            chatId: context.payload.chatId,
            prompt: context.payload.prompt,
            generateOptions: context.payload.generateOptions,
            streamProtocol: context.payload.streamProtocol,
            metadata: {
              ...context.payload.metadata,
              'tenantId': 'acme-mobile',
              'providerProfile': 'openai-web-search',
            },
          ),
        );
      },
    ),
  );
  final subscription = session.states.listen(_printState);

  try {
    await session.sendMessage(
      ChatInput.text('Find recent release-note highlights.'),
      options: const ChatRequestOptions(
        generateOptions: GenerateTextOptions(
          temperature: 0.2,
          maxOutputTokens: 160,
        ),
        metadata: {
          'clientRequestId': 'client-req-1',
        },
      ),
    );
    await _waitUntilReady(session);

    final latest = session.state.messages.last;
    final mapped = const ChatMessageMapper().map(latest);
    print('\nFinal assistant text:');
    print(mapped.text);
    print('\nPersistent data parts:');
    for (final part in mapped.dataParts) {
      print('${part.key}: ${part.data}');
    }
    print('\nMessage metadata:');
    print(latest.metadata);
  } finally {
    await subscription.cancel();
    await session.dispose();
  }
}

Future<void> _waitUntilReady(ChatSession session) async {
  if (session.state.status == ChatStatus.ready) {
    return;
  }

  await session.states.firstWhere((state) => state.status == ChatStatus.ready);
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
    print('streamingText=${mapped.text}');
  }
}

final class _InProcessBackendTransport implements TransportClient {
  final _DemoChatBackend backend;

  const _InProcessBackendTransport(this.backend);

  @override
  Future<TransportResponse> send(TransportRequest request) {
    throw UnsupportedError(
      'This demo backend only implements streaming chat requests.',
    );
  }

  @override
  Future<StreamingTransportResponse> sendStream(
      TransportRequest request) async {
    if (request.method != TransportMethod.post) {
      return const StreamingTransportResponse(
        statusCode: 405,
        stream: Stream<List<int>>.empty(),
      );
    }

    return StreamingTransportResponse(
      statusCode: 200,
      headers: const {
        'content-type': 'text/event-stream',
      },
      stream: backend.handleChat(request),
    );
  }
}

final class _DemoChatBackend {
  static const _requestCodec = HttpChatTransportRequestJsonCodec();
  static const _adapter = HttpChatTransportServerAdapter();

  Stream<List<int>> handleChat(TransportRequest request) {
    final payload = _requestCodec.decodeRequest(request.body);
    final plan = _BackendProviderPlan.fromMetadata(payload.metadata);
    final promptText = _latestUserText(payload.prompt);

    return _adapter.encodeEventSseStream(
      eventStream: _streamResponse(
        plan: plan,
        promptText: promptText,
        generateOptions: payload.generateOptions,
      ),
      requestId: 'backend-req-${payload.chatId}',
      messageId: 'assistant-${payload.chatId}',
      resumeToken: 'resume-${payload.chatId}-1',
      messageMetadata: {
        'clientRequestId': payload.metadata['clientRequestId'],
        'backendPlan': plan.toJson(),
      },
      leadingDataParts: [
        DataUiPart<Object?>(
          id: 'backend-plan',
          key: 'backend-plan',
          data: plan.toJson(),
        ),
      ],
      finalMessageMetadata: const {
        'backendCompleted': true,
        'hintMapping': 'metadata-to-provider-options',
      },
    );
  }

  Stream<TextStreamEvent> _streamResponse({
    required _BackendProviderPlan plan,
    required String promptText,
    required GenerateTextOptions generateOptions,
  }) async* {
    yield StartEvent();
    yield ResponseMetadataEvent(
      responseId: 'resp-demo-1',
      modelId: plan.modelId,
      providerMetadata: ProviderMetadata({
        'backend': {
          'providerProfile': plan.profile,
        },
      }),
    );
    yield const TextStartEvent(id: 'text-1');
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'Backend selected ${plan.providerId}/${plan.modelId}. ',
    );
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'It mapped app metadata into ${plan.description}. ',
    );
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'Shared maxOutputTokens=${generateOptions.maxOutputTokens}. ',
    );
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'Prompt summary: "$promptText"',
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

      final textParts = message.parts.whereType<TextPromptPart>();
      if (textParts.isEmpty) {
        continue;
      }

      return textParts.map((part) => part.text).join(' ');
    }

    return 'no user text';
  }
}

final class _BackendProviderPlan {
  final String profile;
  final String providerId;
  final String modelId;
  final String description;
  final Map<String, Object?> providerOptionsPreview;

  _BackendProviderPlan({
    required this.profile,
    required this.providerId,
    required this.modelId,
    required this.description,
    required Map<String, Object?> providerOptionsPreview,
  }) : providerOptionsPreview = Map.unmodifiable(providerOptionsPreview);

  factory _BackendProviderPlan.fromMetadata(Map<String, Object?> metadata) {
    return switch (metadata['providerProfile']) {
      'anthropic-thinking' => _BackendProviderPlan(
          profile: 'anthropic-thinking',
          providerId: 'anthropic',
          modelId: 'claude-sonnet-4-5',
          description: 'Anthropic extended-thinking options on the backend',
          providerOptionsPreview: const {
            'anthropic': {
              'extendedThinking': true,
              'thinkingBudgetTokens': 2048,
            },
          },
        ),
      _ => _BackendProviderPlan(
          profile: 'openai-web-search',
          providerId: 'openai',
          modelId: 'gpt-4.1-mini',
          description: 'OpenAI web-search tool options on the backend',
          providerOptionsPreview: const {
            'openai': {
              'builtInTools': ['web_search_preview'],
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
