import '../../../core/capability.dart';
import '../../../core/config.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../legacy_chat_adapter.dart';

typedef CompatBridgePredicate = bool Function(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
);

final class CompatChatBridgeRouter {
  final LLMConfig originalConfig;
  final LegacyChatCapabilityAdapter adapter;
  final CompatBridgePredicate canUseBridge;

  const CompatChatBridgeRouter({
    required this.originalConfig,
    required this.adapter,
    required this.canUseBridge,
  });

  Future<ChatResponse> chatWithTools({
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    TransportCancellation? cancelToken,
    required Future<ChatResponse> Function() fallback,
  }) {
    return executeCompatBridge(
      canUseBridge: canUseBridge(originalConfig, messages, tools),
      bridge: () => adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
      fallback: fallback,
    );
  }

  Stream<ChatStreamEvent> chatStream({
    required List<ChatMessage> messages,
    List<Tool>? tools,
    TransportCancellation? cancelToken,
    required Stream<ChatStreamEvent> Function() fallback,
  }) {
    return executeCompatBridgeStream(
      canUseBridge: canUseBridge(originalConfig, messages, tools),
      bridge: () => adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: fallback,
    );
  }
}

mixin CompatChatBridgeRoutingMixin on ChatCapability {
  CompatChatBridgeRouter get compatChatRouter;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return compatChatRouter.chatWithTools(
      messages: messages,
      tools: tools,
      cancelToken: cancelToken,
      fallback: () => super.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return compatChatRouter.chatStream(
      messages: messages,
      tools: tools,
      cancelToken: cancelToken,
      fallback: () => super.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}

Future<T> executeCompatBridge<T>({
  required bool canUseBridge,
  required Future<T> Function() bridge,
  required Future<T> Function() fallback,
}) async {
  if (canUseBridge) {
    try {
      return await bridge();
    } catch (error) {
      if (!isCompatibilityError(error)) {
        rethrow;
      }
    }
  }

  return fallback();
}

Stream<T> executeCompatBridgeStream<T>({
  required bool canUseBridge,
  required Stream<T> Function() bridge,
  required Stream<T> Function() fallback,
}) async* {
  if (canUseBridge) {
    try {
      yield* bridge();
      return;
    } catch (error) {
      if (!isCompatibilityError(error)) {
        rethrow;
      }
    }
  }

  yield* fallback();
}

bool isCompatibilityError(Object error) {
  return error is UnsupportedError ||
      error is ArgumentError ||
      error is FormatException ||
      error is StateError;
}
