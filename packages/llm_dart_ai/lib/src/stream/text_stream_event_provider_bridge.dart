import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import 'text_stream_event.dart';

TextStreamEvent textStreamEventFromProvider(
  provider.LanguageModelStreamEvent event,
) {
  return switch (event) {
    provider.StartEvent(:final warnings) => StartEvent(warnings: warnings),
    provider.ResponseMetadataEvent(
      :final responseId,
      :final timestamp,
      :final modelId,
      :final providerMetadata,
    ) =>
      ResponseMetadataEvent(
        responseId: responseId,
        timestamp: timestamp,
        modelId: modelId,
        providerMetadata: providerMetadata,
      ),
    provider.TextStartEvent(:final id, :final providerMetadata) =>
      TextStartEvent(id: id, providerMetadata: providerMetadata),
    provider.TextDeltaEvent(:final id, :final delta, :final providerMetadata) =>
      TextDeltaEvent(
        id: id,
        delta: delta,
        providerMetadata: providerMetadata,
      ),
    provider.TextEndEvent(:final id, :final providerMetadata) =>
      TextEndEvent(id: id, providerMetadata: providerMetadata),
    provider.ReasoningStartEvent(:final id, :final providerMetadata) =>
      ReasoningStartEvent(id: id, providerMetadata: providerMetadata),
    provider.ReasoningDeltaEvent(
      :final id,
      :final delta,
      :final providerMetadata,
    ) =>
      ReasoningDeltaEvent(
        id: id,
        delta: delta,
        providerMetadata: providerMetadata,
      ),
    provider.ReasoningEndEvent(:final id, :final providerMetadata) =>
      ReasoningEndEvent(id: id, providerMetadata: providerMetadata),
    provider.ReasoningFileEvent(:final file, :final providerMetadata) =>
      ReasoningFileEvent(file, providerMetadata: providerMetadata),
    provider.ToolInputStartEvent(
      :final toolCallId,
      :final toolName,
      :final providerExecuted,
      :final isDynamic,
      :final title,
      :final providerMetadata,
    ) =>
      ToolInputStartEvent(
        toolCallId: toolCallId,
        toolName: toolName,
        providerExecuted: providerExecuted,
        isDynamic: isDynamic,
        title: title,
        providerMetadata: providerMetadata,
      ),
    provider.ToolInputDeltaEvent(
      :final toolCallId,
      :final delta,
      :final providerMetadata,
    ) =>
      ToolInputDeltaEvent(
        toolCallId: toolCallId,
        delta: delta,
        providerMetadata: providerMetadata,
      ),
    provider.ToolInputEndEvent(:final toolCallId, :final providerMetadata) =>
      ToolInputEndEvent(
        toolCallId: toolCallId,
        providerMetadata: providerMetadata,
      ),
    provider.ToolInputErrorEvent(
      :final toolCallId,
      :final toolName,
      :final input,
      :final errorText,
      :final providerExecuted,
      :final isDynamic,
      :final title,
      :final providerMetadata,
    ) =>
      ToolInputErrorEvent(
        toolCallId: toolCallId,
        toolName: toolName,
        input: input,
        errorText: errorText,
        providerExecuted: providerExecuted,
        isDynamic: isDynamic,
        title: title,
        providerMetadata: providerMetadata,
      ),
    provider.ToolCallEvent(:final toolCall, :final providerMetadata) =>
      ToolCallEvent(
        toolCall: toolCall,
        providerMetadata: providerMetadata,
      ),
    provider.ToolResultEvent(:final toolResult, :final providerMetadata) =>
      ToolResultEvent(
        toolResult: toolResult,
        providerMetadata: providerMetadata,
      ),
    provider.ToolApprovalRequestEvent(
      :final approvalId,
      :final toolCallId,
      :final providerMetadata,
    ) =>
      ToolApprovalRequestEvent(
        approvalId: approvalId,
        toolCallId: toolCallId,
        providerMetadata: providerMetadata,
      ),
    provider.SourceEvent(:final source) => SourceEvent(source),
    provider.FileEvent(:final file, :final providerMetadata) =>
      FileEvent(file, providerMetadata: providerMetadata),
    provider.FinishEvent(
      :final finishReason,
      :final rawFinishReason,
      :final usage,
      :final providerMetadata,
    ) =>
      FinishEvent(
        finishReason: finishReason,
        rawFinishReason: rawFinishReason,
        usage: usage,
        providerMetadata: providerMetadata,
      ),
    provider.CustomEvent(:final kind, :final data, :final providerMetadata) =>
      CustomEvent(
        kind: kind,
        data: data,
        providerMetadata: providerMetadata,
      ),
    provider.RawChunkEvent(:final raw) => RawChunkEvent(raw),
    provider.ErrorEvent(:final error) => ErrorEvent(error),
  };
}

provider.LanguageModelStreamEvent textStreamEventToProvider(
  TextStreamEvent event,
) {
  return switch (event) {
    StartEvent(:final warnings) => provider.StartEvent(warnings: warnings),
    ResponseMetadataEvent(
      :final responseId,
      :final timestamp,
      :final modelId,
      :final providerMetadata,
    ) =>
      provider.ResponseMetadataEvent(
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
    ToolOutputDeniedEvent() ||
    StepStartEvent() ||
    StepFinishEvent() ||
    AbortEvent() =>
      _throwRuntimeOnlyAiEvent(event),
  };
}

TextStreamEvent languageModelStreamEventToTextStreamEvent(
  provider.LanguageModelStreamEvent event, {
  String context = 'LanguageModelStreamEvent',
}) {
  provider.validateLanguageModelStreamEvent(event, context: context);
  return textStreamEventFromProvider(event);
}

Never _throwRuntimeOnlyAiEvent(TextStreamEvent event) {
  throw StateError(
    'AI runtime-only event ${event.runtimeType} cannot be converted to a '
    'provider language model stream event.',
  );
}
