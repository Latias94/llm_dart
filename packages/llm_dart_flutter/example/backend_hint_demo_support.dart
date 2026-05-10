import 'package:flutter/foundation.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

const String defaultBackendHintDemoProfile = 'anthropic-thinking';

const List<String> backendHintDemoProfiles = <String>[
  defaultBackendHintDemoProfile,
  'openai-web-search',
];

HttpChatTransport createBackendHintDemoTransport({
  required ValueListenable<String> providerProfileListenable,
  String uiSurface = 'flutter',
  Map<String, Object?> fixedMetadata = const {},
}) {
  return HttpChatTransport(
    endpoint: Uri.parse('https://backend.example/chat'),
    transport: _InProcessBackendTransport(
      BackendHintDemoBackend(uiSurface: uiSurface),
    ),
    prepareSendMessagesRequest: (context) {
      return HttpChatTransportPreparedSendMessagesRequest(
        headers: {
          ...context.headers,
          'x-app-surface': uiSurface,
        },
        payload: HttpChatTransportRequestPayload(
          chatId: context.payload.chatId,
          prompt: context.payload.prompt,
          generateOptions: context.payload.generateOptions,
          streamProtocol: context.payload.streamProtocol,
          metadata: {
            ...context.payload.metadata,
            ...fixedMetadata,
            'providerProfile': providerProfileListenable.value,
            'uiSurface': uiSurface,
          },
        ),
      );
    },
  );
}

String backendPlanSummary(ChatUiMessage message) {
  final raw = message.metadata['backendPlan'];
  if (raw is! Map) {
    return '';
  }

  final providerId = raw['providerId'];
  final modelId = raw['modelId'];
  if (providerId is String && modelId is String) {
    return '$providerId / $modelId';
  }

  return '';
}

String backendHintProfileLabel(String profile) {
  return switch (profile) {
    'openai-web-search' => 'OpenAI web search',
    _ => 'Anthropic thinking',
  };
}

final class BackendHintDemoBackend {
  static const _requestCodec = HttpChatTransportRequestJsonCodec();
  static const _adapter = HttpChatTransportServerAdapter();

  final String uiSurface;

  const BackendHintDemoBackend({
    this.uiSurface = 'flutter',
  });

  Stream<List<int>> handle(TransportRequest request) {
    final payload = _requestCodec.decodeRequest(request.body);
    final plan = BackendHintExecutionPlan.fromMetadata(payload.metadata);

    return _adapter.encodeEventSseStream(
      eventStream: _eventStream(
        plan: plan,
        prompt: _latestUserText(payload.prompt),
        generateOptions: payload.generateOptions,
      ),
      requestId: '$uiSurface-backend-${payload.chatId}',
      messageId: 'assistant-${payload.chatId}',
      messageMetadata: {
        'backendPlan': plan.toJson(),
        'clientRequestId': payload.metadata['clientRequestId'],
      },
      leadingDataParts: [
        DataUiPart<Object?>(
          id: 'backend-plan',
          key: 'backend-plan',
          data: plan.toJson(),
        ),
      ],
      finalMessageMetadata: {
        'backendCompleted': true,
        'uiSurface': uiSurface,
      },
    );
  }

  Stream<TextStreamEvent> _eventStream({
    required BackendHintExecutionPlan plan,
    required String prompt,
    required GenerateTextOptions generateOptions,
  }) async* {
    yield StartEvent();
    yield ResponseMetadataEvent(
      responseId: '$uiSurface-resp-1',
      modelId: plan.modelId,
      providerMetadata: ProviderMetadata({
        'backend': {
          'providerProfile': plan.profile,
          'uiSurface': uiSurface,
        },
      }),
    );
    yield const TextStartEvent(id: 'text-1');
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'Flutter UI is using backend-owned ${plan.providerId} routing. ',
    );
    yield TextDeltaEvent(
      id: 'text-1',
      delta: 'The backend mapped metadata into ${plan.description}. ',
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

final class BackendHintExecutionPlan {
  final String profile;
  final String providerId;
  final String modelId;
  final String description;
  final Map<String, Object?> providerOptionsPreview;

  BackendHintExecutionPlan({
    required this.profile,
    required this.providerId,
    required this.modelId,
    required this.description,
    required Map<String, Object?> providerOptionsPreview,
  }) : providerOptionsPreview = Map.unmodifiable(providerOptionsPreview);

  factory BackendHintExecutionPlan.fromMetadata(Map<String, Object?> metadata) {
    return switch (metadata['providerProfile']) {
      'openai-web-search' => BackendHintExecutionPlan(
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
      _ => BackendHintExecutionPlan(
          profile: defaultBackendHintDemoProfile,
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

final class _InProcessBackendTransport implements TransportClient {
  final BackendHintDemoBackend backend;

  const _InProcessBackendTransport(this.backend);

  @override
  Future<TransportResponse> send(TransportRequest request) {
    throw UnsupportedError(
      'This demo backend only supports streaming chat requests.',
    );
  }

  @override
  Future<StreamingTransportResponse> sendStream(
    TransportRequest request,
  ) async {
    return StreamingTransportResponse(
      statusCode: 200,
      headers: const {
        'content-type': 'text/event-stream',
      },
      stream: backend.handle(request),
    );
  }
}
