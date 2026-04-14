import '../../../../core/capability.dart';
import 'client.dart';
import 'openai_chat_response.dart';
import 'stream_parsing_support.dart';

/// Stateful Chat Completions stream parser for the OpenAI compatibility shell.
class OpenAIChatStreamParser {
  final OpenAIClient client;
  final String model;
  final OpenAIStreamParsingState _state = OpenAIStreamParsingState();

  OpenAIChatStreamParser({
    required this.client,
    required this.model,
  });

  void reset() {
    _state.reset();
  }

  List<ChatStreamEvent> parseChunk(String chunk) {
    final events = <ChatStreamEvent>[];
    final jsonList = client.parseSSEChunk(chunk);
    if (jsonList.isEmpty) {
      return events;
    }

    for (final json in jsonList) {
      events.addAll(_parseEvent(json));
    }

    return events;
  }

  List<ChatStreamEvent> _parseEvent(Map<String, dynamic> json) {
    final events = <ChatStreamEvent>[];
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return events;
    }

    final choice = choices.first as Map<String, dynamic>;
    final delta = choice['delta'] as Map<String, dynamic>?;
    if (delta == null) {
      return events;
    }

    if (addOpenAIReasoningDeltaEvents(
      state: _state,
      events: events,
      delta: delta,
    )) {
      return events;
    }

    final content = delta['content'] as String?;
    if (content != null && content.isNotEmpty) {
      addOpenAITextDeltaEvents(
        state: _state,
        events: events,
        content: content,
        reasoningDelta: delta,
      );
    }

    addOpenAIToolCallDeltaEvents(
      state: _state,
      events: events,
      toolCalls: delta['tool_calls'] as List?,
      onWarning: client.logger.warning,
    );

    final finishReason = choice['finish_reason'] as String?;
    if (finishReason != null) {
      flushOpenAIPendingContentEvents(
        state: _state,
        events: events,
      );

      final usage = json['usage'] as Map<String, dynamic>?;
      final streamedText = _state.textContent ?? '';
      final streamedToolCalls = _state.buildToolCalls();

      events.add(
        CompletionEvent(
          OpenAIChatResponse.fromResponseData(
            {
              'choices': [
                {
                  'message': {
                    'content': streamedText,
                    'role': 'assistant',
                    if (streamedToolCalls.isNotEmpty)
                      'tool_calls': streamedToolCalls
                          .map((toolCall) => toolCall.toJson())
                          .toList(),
                  },
                },
              ],
              if (usage != null) 'usage': usage,
            },
            model: model,
            thinkingContent: _state.thinkingContent,
          ),
        ),
      );

      _state.reset();
    }

    return events;
  }
}
