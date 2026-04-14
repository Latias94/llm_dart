import '../../../../core/capability.dart';
import 'client.dart';
import 'openai_responses_response.dart';
import 'stream_parsing_support.dart';

/// Stateful Responses-API stream parser that owns incremental stream state and
/// completion response reconstruction.
class OpenAIResponsesStreamParser {
  final OpenAIClient client;
  final OpenAIStreamParsingState _state = OpenAIStreamParsingState();

  OpenAIResponsesStreamParser(this.client);

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
    final eventType = json['type'] as String?;

    if (eventType == 'response.output_text.delta') {
      final delta = json['delta'] as String?;
      if (delta != null && delta.isNotEmpty) {
        addOpenAITextDeltaEvents(
          state: _state,
          events: events,
          content: delta,
        );
        return events;
      }
    }

    if (eventType == 'response.completed') {
      final response = json['response'] as Map<String, dynamic>?;
      if (response != null) {
        flushOpenAIPendingContentEvents(
          state: _state,
          events: events,
        );

        events.add(
          CompletionEvent(
            OpenAIResponsesResponse.fromResponseData(
              response,
              thinkingContent: _state.thinkingContent,
            ),
          ),
        );

        _state.reset();
        return events;
      }
    }

    if (addOpenAIReasoningDeltaEvents(
      state: _state,
      events: events,
      delta: json,
    )) {
      return events;
    }

    final content = json['output_text_delta'] as String?;
    if (content != null && content.isNotEmpty) {
      addOpenAITextDeltaEvents(
        state: _state,
        events: events,
        content: content,
        reasoningDelta: {'content': content},
      );
    }

    addOpenAIToolCallDeltaEvents(
      state: _state,
      events: events,
      toolCalls: json['tool_calls'] as List?,
      onWarning: client.logger.warning,
    );

    final finishReason = json['finish_reason'] as String?;
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
          OpenAIResponsesResponse.fromResponseData(
            {
              'output_text': streamedText,
              if (streamedToolCalls.isNotEmpty)
                'tool_calls': streamedToolCalls
                    .map((toolCall) => toolCall.toJson())
                    .toList(),
              if (usage != null) 'usage': usage,
            },
            thinkingContent: _state.thinkingContent,
          ),
        ),
      );

      _state.reset();
    }

    return events;
  }
}
