import 'dart:async';

import 'chat_session.dart';

typedef ToolExecutionHandler = FutureOr<ToolExecutionResult?> Function(
  ToolExecutionRequest request,
);

final class ToolExecutionRegistry {
  final Map<String, ToolExecutionHandler> _handlers;
  final ToolExecutionHandler? fallback;

  ToolExecutionRegistry({
    Map<String, ToolExecutionHandler> handlers = const {},
    this.fallback,
  }) : _handlers =
            Map.unmodifiable(Map<String, ToolExecutionHandler>.from(handlers));

  bool hasHandlerFor(String toolName) {
    return _handlers.containsKey(toolName) || fallback != null;
  }

  FutureOr<ToolExecutionResult?> call(ToolExecutionRequest request) {
    final handler = _handlers[request.toolName] ?? fallback;
    return handler?.call(request);
  }

  ToolExecutionRegistry withHandler(
    String toolName,
    ToolExecutionHandler handler,
  ) {
    return ToolExecutionRegistry(
      handlers: {
        ..._handlers,
        toolName: handler,
      },
      fallback: fallback,
    );
  }
}
