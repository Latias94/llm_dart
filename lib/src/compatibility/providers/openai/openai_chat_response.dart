import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../utils/reasoning_utils.dart';

/// OpenAI chat response implementation.
class OpenAIChatResponse implements ChatResponse {
  final Map<String, dynamic> _rawResponse;
  final String? _thinkingContent;

  OpenAIChatResponse(this._rawResponse, [this._thinkingContent]);

  factory OpenAIChatResponse.fromResponseData(
    Map<String, dynamic> responseData, {
    required String model,
    String? thinkingContent,
  }) {
    return OpenAIChatResponse(
      responseData,
      thinkingContent ?? _extractThinkingContent(responseData, model: model),
    );
  }

  @override
  String? get text {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return null;
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    return message?['content'] as String?;
  }

  @override
  List<ToolCall>? get toolCalls {
    final choices = _rawResponse['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return null;
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final toolCalls = message?['tool_calls'] as List?;
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

String? _extractThinkingContent(
  Map<String, dynamic> responseData, {
  required String model,
}) {
  final choices = responseData['choices'] as List?;
  if (choices != null && choices.isNotEmpty) {
    final choice = choices.first as Map<String, dynamic>;
    final message = choice['message'] as Map<String, dynamic>?;

    if (message != null) {
      final directThinking = message['reasoning'] as String? ??
          message['thinking'] as String? ??
          message['reasoning_content'] as String?;
      if (directThinking != null && directThinking.isNotEmpty) {
        return directThinking;
      }

      final content = message['content'] as String?;
      if (content != null && ReasoningUtils.containsThinkingTags(content)) {
        final thinkMatch = RegExp(
          r'<think>(.*?)</think>',
          dotAll: true,
        ).firstMatch(content);
        if (thinkMatch != null) {
          message['content'] = ReasoningUtils.filterThinkingContent(content);
          return thinkMatch.group(1)?.trim();
        }
      }
    }
  }

  if (model.contains('deepseek-r1')) {
    final reasoning = responseData['reasoning'] as String?;
    if (reasoning != null && reasoning.isNotEmpty) {
      return reasoning;
    }
  }

  return null;
}
