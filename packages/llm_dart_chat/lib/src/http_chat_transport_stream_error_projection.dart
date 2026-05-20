import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'http_chat_transport_resume_state.dart';

typedef HttpChatTransportResumeStateClearer = void Function();

ChatUiEventChunk projectHttpChatTransportStatusError(
  int statusCode,
) {
  return ChatUiEventChunk(
    ErrorEvent(
      ModelError(
        kind: ModelErrorKind.transport,
        message: 'HTTP chat transport request failed.',
        code: 'http-transport-status',
        statusCode: statusCode,
        isRetryable: isHttpChatTransportRetryableStatus(statusCode),
      ),
    ),
  );
}

ChatUiEventChunk projectHttpChatTransportCaughtError({
  required Object error,
  required HttpChatTransportResumeState state,
  required HttpChatTransportResumeStateClearer clearResumeState,
}) {
  if (!state.canReconnect) {
    clearResumeState();
  }
  return ChatUiEventChunk(
    ErrorEvent(transportErrorToModelError(error)),
  );
}

bool isHttpChatTransportRetryableStatus(int statusCode) {
  return statusCode >= 500 ||
      statusCode == 408 ||
      statusCode == 409 ||
      statusCode == 429;
}
