import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_message_converters.dart';

List<ChatMessage> buildResponseMessagesBestEffort(ChatResponse response) {
  if (response is ChatResponseWithAssistantMessage) {
    return [response.assistantMessage];
  }

  final toolCalls = response.toolCalls;
  if (toolCalls != null && toolCalls.isNotEmpty) {
    return [
      ChatMessage.toolUse(
        toolCalls: toolCalls,
        content: response.text ?? '',
      ),
    ];
  }

  final text = response.text;
  if (text != null && text.isNotEmpty) {
    return [ChatMessage.assistant(text)];
  }

  return const <ChatMessage>[];
}

List<PromptMessage> buildResponsePromptMessagesBestEffort(
    ChatResponse response) {
  if (response is ChatResponseWithAssistantMessage) {
    return [promptMessageFromChatMessage(response.assistantMessage)];
  }

  final toolCalls = response.toolCalls;
  if (toolCalls != null && toolCalls.isNotEmpty) {
    final parts = <PromptPart>[];
    final text = response.text;
    if (text != null && text.trim().isNotEmpty) {
      parts.add(TextPart(text));
    }
    for (final toolCall in toolCalls) {
      parts.add(ToolCallPart.fromToolCall(toolCall));
    }

    return [
      PromptMessage(
        role: PromptRole.assistant,
        parts: List<PromptPart>.unmodifiable(parts),
      ),
    ];
  }

  final text = response.text;
  if (text != null && text.trim().isNotEmpty) {
    return [PromptMessage.assistant(text)];
  }

  return const <PromptMessage>[];
}

PromptMessage buildToolResultPromptMessageBestEffort({
  required List<V3ToolCall> toolCalls,
  required List<ToolResult> toolResults,
}) {
  final toolNameById = <String, String>{};
  for (final call in toolCalls) {
    toolNameById[call.toolCallId] = call.toolName;
  }

  ToolResultOutput toOutput(ToolResult result) {
    final raw = result.result;

    if (raw is Map) {
      final map = raw.cast<String, dynamic>();

      // Best-effort: support the v3 tool-result output envelope, e.g.
      // `{ "type": "execution-denied", ... }`.
      if (map['type'] is String) {
        try {
          return ToolResultOutput.fromJson(map);
        } catch (_) {
          // fall through
        }
      }

      return result.isError
          ? ToolResultErrorJsonOutput(map)
          : ToolResultJsonOutput(map);
    }

    if (raw is List || raw is num || raw is bool) {
      return result.isError
          ? ToolResultErrorJsonOutput(raw)
          : ToolResultJsonOutput(raw);
    }

    final text = raw?.toString() ?? 'null';
    return result.isError
        ? ToolResultErrorTextOutput(text)
        : ToolResultTextOutput(text);
  }

  final parts = toolResults
      .map(
        (r) => ToolResultPart(
          r.toolCallId,
          toolNameById[r.toolCallId] ?? '',
          toOutput(r),
        ),
      )
      .toList(growable: false);

  return PromptMessage.tool(parts: parts);
}
