import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_request_payload.dart';

typedef HttpChatTransportResumeStateClearer = void Function();

final class HttpChatTransportResumeState {
  final HttpChatTransportCallOptionsPayload callOptionsPayload;
  final Duration? requestTimeout;
  final int? maxRetries;
  final ProviderCancellation? cancellation;
  final List<ChatUiStreamChunk> replayChunks = [];
  String? resumeToken;
  bool isTerminal = false;

  HttpChatTransportResumeState({
    required this.callOptionsPayload,
    required this.requestTimeout,
    required this.maxRetries,
    required this.cancellation,
  });

  bool get canReconnect => !isTerminal && resumeToken != null;

  void markTerminal() {
    isTerminal = true;
  }
}
