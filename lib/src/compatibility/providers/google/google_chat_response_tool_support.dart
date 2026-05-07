part of 'google_chat_response.dart';

final class _GoogleChatResponseToolSupport {
  const _GoogleChatResponseToolSupport();

  List<ToolCall>? extractToolCalls(Map<String, dynamic> rawResponse) {
    return _extractToolCalls(rawResponse);
  }
}

List<ToolCall>? _extractToolCalls(Map<String, dynamic> rawResponse) {
  final parts = _extractParts(rawResponse);
  if (parts == null) return null;

  final toolCalls = <ToolCall>[];
  for (final part in parts) {
    final functionCall = _asMap(part['functionCall']);
    if (functionCall == null) {
      continue;
    }

    final name = functionCall['name'] as String?;
    if (name == null || name.isEmpty) {
      continue;
    }

    final args = functionCall['args'];
    final arguments =
        args is Map ? jsonEncode(args) : jsonEncode(<String, dynamic>{});

    toolCalls.add(
      ToolCall(
        id: 'call_$name',
        callType: 'function',
        function: FunctionCall(name: name, arguments: arguments),
      ),
    );
  }

  return toolCalls.isEmpty ? null : toolCalls;
}
