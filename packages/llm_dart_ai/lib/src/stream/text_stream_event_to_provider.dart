import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import 'text_stream_event.dart';

provider.LanguageModelStreamEvent textStreamEventToProvider(
  TextStreamEvent event,
) {
  return switch (event) {
    StartEvent(:final warnings) => provider.StartEvent(warnings: warnings),
    ResponseMetadataEvent(
      :final responseMetadata,
      :final responseId,
      :final timestamp,
      :final modelId,
      :final providerMetadata,
    ) =>
      provider.ResponseMetadataEvent(
        responseMetadata: responseMetadata,
        responseId: responseId,
        timestamp: timestamp,
        modelId: modelId,
        providerMetadata: providerMetadata,
      ),
    TextStartEvent(:final id, :final providerMetadata) =>
      provider.TextStartEvent(id: id, providerMetadata: providerMetadata),
    TextDeltaEvent(:final id, :final delta, :final providerMetadata) =>
      provider.TextDeltaEvent(
        id: id,
        delta: delta,
        providerMetadata: providerMetadata,
      ),
    TextEndEvent(:final id, :final providerMetadata) =>
      provider.TextEndEvent(id: id, providerMetadata: providerMetadata),
    ReasoningStartEvent(:final id, :final providerMetadata) =>
      provider.ReasoningStartEvent(id: id, providerMetadata: providerMetadata),
    ReasoningDeltaEvent(
      :final id,
      :final delta,
      :final providerMetadata,
    ) =>
      provider.ReasoningDeltaEvent(
        id: id,
        delta: delta,
        providerMetadata: providerMetadata,
      ),
    ReasoningEndEvent(:final id, :final providerMetadata) =>
      provider.ReasoningEndEvent(id: id, providerMetadata: providerMetadata),
    ReasoningFileEvent(:final file, :final providerMetadata) =>
      provider.ReasoningFileEvent(file, providerMetadata: providerMetadata),
    ToolInputStartEvent(
      :final toolCallId,
      :final toolName,
      :final providerExecuted,
      :final isDynamic,
      :final title,
      :final providerMetadata,
    ) =>
      provider.ToolInputStartEvent(
        toolCallId: toolCallId,
        toolName: toolName,
        providerExecuted: providerExecuted,
        isDynamic: isDynamic,
        title: title,
        providerMetadata: providerMetadata,
      ),
    ToolInputDeltaEvent(
      :final toolCallId,
      :final delta,
      :final providerMetadata,
    ) =>
      provider.ToolInputDeltaEvent(
        toolCallId: toolCallId,
        delta: delta,
        providerMetadata: providerMetadata,
      ),
    ToolInputEndEvent(:final toolCallId, :final providerMetadata) =>
      provider.ToolInputEndEvent(
        toolCallId: toolCallId,
        providerMetadata: providerMetadata,
      ),
    ToolInputErrorEvent(
      :final toolCallId,
      :final toolName,
      :final input,
      :final errorText,
      :final providerExecuted,
      :final isDynamic,
      :final title,
      :final providerMetadata,
    ) =>
      provider.ToolInputErrorEvent(
        toolCallId: toolCallId,
        toolName: toolName,
        input: input,
        errorText: errorText,
        providerExecuted: providerExecuted,
        isDynamic: isDynamic,
        title: title,
        providerMetadata: providerMetadata,
      ),
    ToolCallEvent(:final toolCall, :final providerMetadata) =>
      provider.ToolCallEvent(
        toolCall: toolCall,
        providerMetadata: providerMetadata,
      ),
    ToolResultEvent(:final toolResult, :final providerMetadata) =>
      provider.ToolResultEvent(
        toolResult: toolResult,
        providerMetadata: providerMetadata,
      ),
    ToolApprovalRequestEvent(
      :final approvalId,
      :final toolCallId,
      :final providerMetadata,
    ) =>
      provider.ToolApprovalRequestEvent(
        approvalId: approvalId,
        toolCallId: toolCallId,
        providerMetadata: providerMetadata,
      ),
    SourceEvent(:final source) => provider.SourceEvent(source),
    FileEvent(:final file, :final providerMetadata) =>
      provider.FileEvent(file, providerMetadata: providerMetadata),
    FinishEvent(
      :final finishReason,
      :final rawFinishReason,
      :final usage,
      :final providerMetadata,
    ) =>
      provider.FinishEvent(
        finishReason: finishReason,
        rawFinishReason: rawFinishReason,
        usage: usage,
        providerMetadata: providerMetadata,
      ),
    CustomEvent(:final kind, :final data, :final providerMetadata) =>
      provider.CustomEvent(
        kind: kind,
        data: data,
        providerMetadata: providerMetadata,
      ),
    RawChunkEvent(:final raw) => provider.RawChunkEvent(raw),
    ErrorEvent(:final error) => provider.ErrorEvent(error),
    RunStartEvent() ||
    RunFinishEvent() ||
    ToolOutputDeniedEvent() ||
    StepStartEvent() ||
    StepFinishEvent() ||
    AbortEvent() =>
      _throwRuntimeOnlyAiEvent(event),
  };
}

Never _throwRuntimeOnlyAiEvent(TextStreamEvent event) {
  throw StateError(
    'AI runtime-only event ${event.runtimeType} cannot be converted to a '
    'provider language model stream event.',
  );
}
