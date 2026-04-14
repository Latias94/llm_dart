import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';

/// OpenAI Responses API response implementation.
class OpenAIResponsesResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;

  OpenAIResponsesResponse(this._rawResponse, [this._thinkingContent]);

  factory OpenAIResponsesResponse.fromResponseData(
    Map<String, dynamic> responseData, {
    String? thinkingContent,
  }) {
    return OpenAIResponsesResponse(
      responseData,
      thinkingContent ?? _extractThinkingContent(responseData),
    );
  }

  @override
  String? get text {
    final output = _rawResponse['output'] as List?;
    if (output != null) {
      for (final item in output) {
        if (item is Map<String, dynamic> && item['type'] == 'message') {
          final content = item['content'] as List?;
          if (content == null) {
            continue;
          }

          for (final contentItem in content) {
            if (contentItem is Map<String, dynamic> &&
                contentItem['type'] == 'output_text') {
              return contentItem['text'] as String?;
            }
          }
        }
      }
    }

    return _rawResponse['output_text'] as String?;
  }

  @override
  List<ToolCall>? get toolCalls {
    final output = _rawResponse['output'] as List?;
    if (output != null) {
      final toolCalls = <ToolCall>[];

      for (final item in output) {
        if (item is Map<String, dynamic> && item['type'] == 'function_call') {
          try {
            toolCalls.add(
              ToolCall(
                id: item['call_id'] as String? ?? item['id'] as String? ?? '',
                callType: 'function',
                function: FunctionCall(
                  name: item['name'] as String? ?? '',
                  arguments: item['arguments'] as String? ?? '{}',
                ),
              ),
            );
          } catch (_) {
            // Ignore malformed tool calls to preserve the old compatibility
            // response behavior.
          }
        }
      }

      if (toolCalls.isNotEmpty) {
        return toolCalls;
      }
    }

    final toolCalls = _rawResponse['tool_calls'] as List?;
    if (toolCalls == null) {
      return null;
    }

    return toolCalls
        .map((toolCall) => ToolCall.fromJson(toolCall as Map<String, dynamic>))
        .toList();
  }

  @override
  UsageInfo? get usage {
    final rawUsage = _rawResponse['usage'];
    if (rawUsage == null) {
      return null;
    }

    final Map<String, dynamic> usageData;
    if (rawUsage is Map<String, dynamic>) {
      usageData = rawUsage;
    } else if (rawUsage is Map) {
      usageData = Map<String, dynamic>.from(rawUsage);
    } else {
      return null;
    }

    return UsageInfo.fromJson(usageData);
  }

  @override
  String? get thinking => _thinkingContent;

  /// Get the response ID for chaining responses.
  String? get responseId => _rawResponse['id'] as String?;

  @override
  String toString() {
    final textContent = text;
    final calls = toolCalls;

    if (textContent != null && calls != null) {
      return '${calls.map((call) => call.toString()).join('\n')}\n$textContent';
    } else if (textContent != null) {
      return textContent;
    } else if (calls != null) {
      return calls.map((call) => call.toString()).join('\n');
    } else {
      return '';
    }
  }
}

String? _extractThinkingContent(Map<String, dynamic> responseData) {
  final output = responseData['output'] as List?;
  if (output != null) {
    for (final item in output) {
      if (item is Map<String, dynamic> && item['type'] == 'reasoning') {
        final summary = item['summary'] as List?;
        if (summary != null && summary.isNotEmpty) {
          final summaryItem = summary.first as Map<String, dynamic>?;
          final text = summaryItem?['text'] as String?;
          if (text != null && text.isNotEmpty) {
            return text;
          }
        }
        break;
      }
    }
  }

  final reasoning = responseData['reasoning'];
  if (reasoning is Map<String, dynamic>) {
    final summary = reasoning['summary'] as String?;
    if (summary != null && summary.isNotEmpty) {
      return summary;
    }
  } else if (reasoning is String && reasoning.isNotEmpty) {
    return reasoning;
  }

  final thinking = responseData['thinking'] as String?;
  if (thinking != null && thinking.isNotEmpty) {
    return thinking;
  }

  final reasoningContent = responseData['reasoning_content'] as String?;
  if (reasoningContent != null && reasoningContent.isNotEmpty) {
    return reasoningContent;
  }

  return null;
}
