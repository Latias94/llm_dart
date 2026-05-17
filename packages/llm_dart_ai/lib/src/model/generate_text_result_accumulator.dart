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

import '../stream/text_stream_event.dart';
import 'generate_text_result_content_buffer.dart';
import 'generate_text_result_lifecycle.dart';
import 'generate_text_result_tool_projection.dart';

final class GenerateTextResultAccumulator {
  final GenerateTextResultContentBuffer _content =
      GenerateTextResultContentBuffer();
  late final GenerateTextResultToolProjector _tools =
      GenerateTextResultToolProjector(_content);
  final GenerateTextResultLifecycle _lifecycle = GenerateTextResultLifecycle();

  bool get hasFinishEvent => _lifecycle.hasFinishEvent;

  String get text => _content.text;

  void apply(TextStreamEvent event) {
    switch (event) {
      case StartEvent(:final warnings):
        _lifecycle.addWarnings(warnings);
      case ResponseMetadataEvent():
        _lifecycle.applyResponseMetadata(
          responseId: event.responseId,
          timestamp: event.timestamp,
          modelId: event.modelId,
          providerMetadata: event.providerMetadata,
        );
      case TextStartEvent():
        _lifecycle.mergeProviderMetadata(event.providerMetadata);
        _content.startTextPart(
          id: event.id,
          providerMetadata: event.providerMetadata,
        );
      case TextDeltaEvent():
        _lifecycle.mergeProviderMetadata(event.providerMetadata);
        _content.appendTextDelta(
          id: event.id,
          delta: event.delta,
          providerMetadata: event.providerMetadata,
        );
      case TextEndEvent():
        _lifecycle.mergeProviderMetadata(event.providerMetadata);
        _content.endTextPart(
          id: event.id,
          providerMetadata: event.providerMetadata,
        );
      case ReasoningStartEvent():
        _lifecycle.mergeProviderMetadata(event.providerMetadata);
        _content.startReasoningPart(
          id: event.id,
          providerMetadata: event.providerMetadata,
        );
      case ReasoningDeltaEvent():
        _lifecycle.mergeProviderMetadata(event.providerMetadata);
        _content.appendReasoningDelta(
          id: event.id,
          delta: event.delta,
          providerMetadata: event.providerMetadata,
        );
      case ReasoningEndEvent():
        _lifecycle.mergeProviderMetadata(event.providerMetadata);
        _content.endReasoningPart(
          id: event.id,
          providerMetadata: event.providerMetadata,
        );
      case ReasoningFileEvent():
        _lifecycle.mergeProviderMetadata(event.providerMetadata);
        _content.appendReasoningFile(
          file: event.file,
          providerMetadata: event.providerMetadata,
        );
      case ToolInputStartEvent() ||
            ToolInputDeltaEvent() ||
            ToolInputEndEvent() ||
            ToolInputErrorEvent() ||
            ToolCallEvent() ||
            ToolResultEvent() ||
            ToolApprovalRequestEvent() ||
            ToolOutputDeniedEvent():
        _lifecycle.mergeProviderMetadata(_tools.apply(event));
      case SourceEvent():
        _content.appendSource(event.source);
        _lifecycle.mergeProviderMetadata(event.source.providerMetadata);
      case FileEvent():
        _lifecycle.mergeProviderMetadata(event.providerMetadata);
        _content.appendFile(
          file: event.file,
          providerMetadata: event.providerMetadata,
        );
      case RunStartEvent() ||
            StepStartEvent() ||
            StepFinishEvent() ||
            AbortEvent() ||
            RawChunkEvent():
        break;
      case RunFinishEvent():
        _lifecycle.applyRunFinish(
          finishReason: event.finishReason,
          rawFinishReason: event.rawFinishReason,
          usage: event.usage,
        );
      case FinishEvent():
        _lifecycle.applyFinish(
          finishReason: event.finishReason,
          rawFinishReason: event.rawFinishReason,
          usage: event.usage,
          providerMetadata: event.providerMetadata,
        );
      case CustomEvent():
        _lifecycle.mergeProviderMetadata(event.providerMetadata);
        _content.appendCustom(
          kind: event.kind,
          data: event.data,
          providerMetadata: event.providerMetadata,
        );
      case ErrorEvent():
        _lifecycle.setError(event.error);
    }
  }

  GenerateTextResult build() {
    return _lifecycle.build(
      content: _content.content,
    );
  }
}

Future<GenerateTextResult> collectGenerateTextResult(
  Stream<TextStreamEvent> events,
) async {
  final accumulator = GenerateTextResultAccumulator();
  await for (final event in events) {
    accumulator.apply(event);
  }
  return accumulator.build();
}
