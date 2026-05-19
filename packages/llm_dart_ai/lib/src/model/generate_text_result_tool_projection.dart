import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide
        CustomEvent,
        ErrorEvent,
        FileEvent,
        FinishEvent,
        RawChunkEvent,
        ReasoningDeltaEvent,
        ReasoningEndEvent,
        ReasoningFileEvent,
        ReasoningStartEvent,
        ResponseMetadataEvent,
        SourceEvent,
        StartEvent,
        TextDeltaEvent,
        TextEndEvent,
        TextStartEvent,
        ToolApprovalRequestEvent,
        ToolCallEvent,
        ToolInputDeltaEvent,
        ToolInputEndEvent,
        ToolInputErrorEvent,
        ToolInputStartEvent,
        ToolResultEvent;

import '../common/tool_input_stream_state.dart';
import '../stream/text_stream_event.dart';
import 'generate_text_result_content_buffer.dart';

final class GenerateTextResultToolProjector {
  final GenerateTextResultContentBuffer _content;
  final Map<String, StreamingToolInputState> _partialToolCalls =
      <String, StreamingToolInputState>{};

  GenerateTextResultToolProjector(this._content);

  ProviderMetadata? apply(TextStreamEvent event) {
    switch (event) {
      case ToolInputStartEvent():
        _partialToolCalls[event.toolCallId] = StreamingToolInputState(
          toolName: event.toolName,
          providerExecuted: event.providerExecuted,
          isDynamic: event.isDynamic,
          title: event.title,
          providerMetadata: event.providerMetadata,
        );
        return event.providerMetadata;
      case ToolInputDeltaEvent():
        final partial = _requirePartialToolCall(event.toolCallId);
        partial.append(event.delta);
        partial.mergeProviderMetadata(event.providerMetadata);
        return event.providerMetadata;
      case ToolInputEndEvent():
        final partial = _requirePartialToolCall(event.toolCallId);
        final providerMetadata = ProviderMetadata.mergeNullable(
          partial.providerMetadata,
          event.providerMetadata,
        );
        _content.upsertToolCallPart(
          ToolCallContentPart(
            ToolCallContent(
              toolCallId: event.toolCallId,
              toolName: partial.toolName,
              input: partial.input,
              providerExecuted: partial.providerExecuted,
              isDynamic: partial.isDynamic,
              title: partial.title,
            ),
            providerMetadata: providerMetadata,
          ),
        );
        _partialToolCalls.remove(event.toolCallId);
        return event.providerMetadata;
      case ToolInputErrorEvent():
        _content.upsertToolCallPart(
          ToolCallContentPart(
            ToolCallContent(
              toolCallId: event.toolCallId,
              toolName: event.toolName,
              input: event.input,
              providerExecuted: event.providerExecuted,
              isDynamic: event.isDynamic,
              title: event.title,
            ),
            providerMetadata: event.providerMetadata,
          ),
        );
        _content.appendToolResultPart(
          ToolResultContentPart(
            ToolResultContent(
              toolCallId: event.toolCallId,
              toolName: event.toolName,
              output: event.errorText,
              isError: true,
              isDynamic: event.isDynamic,
            ),
            providerMetadata: event.providerMetadata,
          ),
        );
        _partialToolCalls.remove(event.toolCallId);
        return event.providerMetadata;
      case ToolCallEvent():
        final current = _content.toolCallPart(event.toolCall.toolCallId);
        _content.upsertToolCallPart(
          ToolCallContentPart(
            event.toolCall,
            providerMetadata: ProviderMetadata.mergeNullable(
              current?.providerMetadata,
              event.providerMetadata,
            ),
          ),
        );
        _partialToolCalls.remove(event.toolCall.toolCallId);
        return event.providerMetadata;
      case ToolResultEvent():
        _partialToolCalls.remove(event.toolResult.toolCallId);
        _content.appendToolResultPart(
          ToolResultContentPart(
            event.toolResult,
            providerMetadata: event.providerMetadata,
          ),
        );
        return event.providerMetadata;
      case ToolApprovalRequestEvent():
        _content.appendToolApprovalRequestPart(
          ToolApprovalRequestContentPart(
            ToolApprovalRequestContent(
              approvalId: event.approvalId,
              toolCallId: event.toolCallId,
            ),
            providerMetadata: event.providerMetadata,
          ),
        );
        return event.providerMetadata;
      case ToolOutputDeniedEvent():
        _partialToolCalls.remove(event.toolCallId);
        final toolCall = _content.requireToolCallPart(event.toolCallId);
        _content.appendToolResultPart(
          ToolResultContentPart(
            ToolResultContent(
              toolCallId: event.toolCallId,
              toolName: toolCall.toolCall.toolName,
              toolOutput: ExecutionDeniedToolOutput(event.reason),
              isDynamic: toolCall.toolCall.isDynamic,
            ),
            providerMetadata: event.providerMetadata,
          ),
        );
        return event.providerMetadata;
      default:
        throw ArgumentError.value(
          event,
          'event',
          'Expected a tool stream event.',
        );
    }
  }

  StreamingToolInputState _requirePartialToolCall(String toolCallId) {
    final value = _partialToolCalls[toolCallId];
    if (value != null) {
      return value;
    }

    throw StateError(
      'Received tool-input update for missing tool call with ID "$toolCallId". '
      'Ensure a "tool-input-start" event is applied before later tool-input events.',
    );
  }
}
