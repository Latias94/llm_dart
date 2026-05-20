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

import '../common/tool_input_stream_store.dart';
import '../stream/text_stream_event.dart';
import 'generate_text_result_content_buffer.dart';

final class GenerateTextResultToolProjector {
  final GenerateTextResultContentBuffer _content;
  final ToolInputStreamStore _inputStreams = ToolInputStreamStore(
    createMissingInputError: missingToolInputStateError,
  );

  GenerateTextResultToolProjector(this._content);

  ProviderMetadata? apply(TextStreamEvent event) {
    switch (event) {
      case ToolInputStartEvent():
        _inputStreams.start(event);
        return event.providerMetadata;
      case ToolInputDeltaEvent():
        _inputStreams.appendDelta(event);
        return event.providerMetadata;
      case ToolInputEndEvent():
        final partial = _inputStreams.end(event);
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
        _inputStreams.fail(event);
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
        _inputStreams.remove(event.toolCall.toolCallId);
        return event.providerMetadata;
      case ToolResultEvent():
        _inputStreams.remove(event.toolResult.toolCallId);
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
        _inputStreams.remove(event.toolCallId);
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
}
