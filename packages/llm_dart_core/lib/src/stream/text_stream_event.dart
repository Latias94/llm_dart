import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../content/content_part.dart';
import '../model/language_model.dart';

sealed class TextStreamEvent {
  const TextStreamEvent();
}

final class StartEvent extends TextStreamEvent {
  final List<ModelWarning> warnings;

  StartEvent({
    List<ModelWarning> warnings = const [],
  }) : warnings = List.unmodifiable(warnings);
}

final class ResponseMetadataEvent extends TextStreamEvent {
  final String? responseId;
  final DateTime? timestamp;
  final String? modelId;
  final ProviderMetadata? providerMetadata;

  const ResponseMetadataEvent({
    this.responseId,
    this.timestamp,
    this.modelId,
    this.providerMetadata,
  });
}

final class TextStartEvent extends TextStreamEvent {
  final String id;
  final ProviderMetadata? providerMetadata;

  const TextStartEvent({
    required this.id,
    this.providerMetadata,
  });
}

final class TextDeltaEvent extends TextStreamEvent {
  final String id;
  final String delta;
  final ProviderMetadata? providerMetadata;

  const TextDeltaEvent({
    required this.id,
    required this.delta,
    this.providerMetadata,
  });
}

final class TextEndEvent extends TextStreamEvent {
  final String id;
  final ProviderMetadata? providerMetadata;

  const TextEndEvent({
    required this.id,
    this.providerMetadata,
  });
}

final class ReasoningStartEvent extends TextStreamEvent {
  final String id;
  final ProviderMetadata? providerMetadata;

  const ReasoningStartEvent({
    required this.id,
    this.providerMetadata,
  });
}

final class ReasoningDeltaEvent extends TextStreamEvent {
  final String id;
  final String delta;
  final ProviderMetadata? providerMetadata;

  const ReasoningDeltaEvent({
    required this.id,
    required this.delta,
    this.providerMetadata,
  });
}

final class ReasoningEndEvent extends TextStreamEvent {
  final String id;
  final ProviderMetadata? providerMetadata;

  const ReasoningEndEvent({
    required this.id,
    this.providerMetadata,
  });
}

final class ToolInputStartEvent extends TextStreamEvent {
  final String toolCallId;
  final String toolName;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  final ProviderMetadata? providerMetadata;

  const ToolInputStartEvent({
    required this.toolCallId,
    required this.toolName,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.title,
    this.providerMetadata,
  });
}

final class ToolInputDeltaEvent extends TextStreamEvent {
  final String toolCallId;
  final String delta;
  final ProviderMetadata? providerMetadata;

  const ToolInputDeltaEvent({
    required this.toolCallId,
    required this.delta,
    this.providerMetadata,
  });
}

final class ToolInputEndEvent extends TextStreamEvent {
  final String toolCallId;
  final ProviderMetadata? providerMetadata;

  const ToolInputEndEvent({
    required this.toolCallId,
    this.providerMetadata,
  });
}

final class ToolInputErrorEvent extends TextStreamEvent {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final String errorText;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  final ProviderMetadata? providerMetadata;

  const ToolInputErrorEvent({
    required this.toolCallId,
    required this.toolName,
    required this.errorText,
    this.input,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.title,
    this.providerMetadata,
  });
}

final class ToolCallEvent extends TextStreamEvent {
  final ToolCallContent toolCall;
  final ProviderMetadata? providerMetadata;

  const ToolCallEvent({
    required this.toolCall,
    this.providerMetadata,
  });
}

final class ToolResultEvent extends TextStreamEvent {
  final ToolResultContent toolResult;
  final ProviderMetadata? providerMetadata;

  const ToolResultEvent({
    required this.toolResult,
    this.providerMetadata,
  });
}

final class ToolApprovalRequestEvent extends TextStreamEvent {
  final String approvalId;
  final String toolCallId;
  final ProviderMetadata? providerMetadata;

  const ToolApprovalRequestEvent({
    required this.approvalId,
    required this.toolCallId,
    this.providerMetadata,
  });
}

final class ToolOutputDeniedEvent extends TextStreamEvent {
  final String toolCallId;
  final ProviderMetadata? providerMetadata;

  const ToolOutputDeniedEvent({
    required this.toolCallId,
    this.providerMetadata,
  });
}

final class SourceEvent extends TextStreamEvent {
  final SourceReference source;

  const SourceEvent(this.source);
}

final class FileEvent extends TextStreamEvent {
  final GeneratedFile file;
  final ProviderMetadata? providerMetadata;

  const FileEvent(
    this.file, {
    this.providerMetadata,
  });
}

final class StepStartEvent extends TextStreamEvent {
  final String? stepId;

  const StepStartEvent({
    this.stepId,
  });
}

final class StepFinishEvent extends TextStreamEvent {
  final String? stepId;

  const StepFinishEvent({
    this.stepId,
  });
}

final class FinishEvent extends TextStreamEvent {
  final FinishReason finishReason;
  final String? rawFinishReason;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;

  const FinishEvent({
    required this.finishReason,
    this.rawFinishReason,
    this.usage,
    this.providerMetadata,
  });
}

final class CustomEvent extends TextStreamEvent {
  final String kind;
  final Object? data;
  final ProviderMetadata? providerMetadata;

  const CustomEvent({
    required this.kind,
    this.data,
    this.providerMetadata,
  });
}

final class RawChunkEvent extends TextStreamEvent {
  final Object? raw;

  const RawChunkEvent(this.raw);
}

final class ErrorEvent extends TextStreamEvent {
  final Object error;

  const ErrorEvent(this.error);
}
