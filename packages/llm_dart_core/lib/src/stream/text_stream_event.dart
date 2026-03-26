import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../content/content_part.dart';
import '../model/language_model.dart';

sealed class TextStreamEvent {
  const TextStreamEvent();
}

final class StartEvent extends TextStreamEvent {
  const StartEvent();
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
  final ProviderMetadata? providerMetadata;

  const ToolInputStartEvent({
    required this.toolCallId,
    required this.toolName,
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

final class FinishEvent extends TextStreamEvent {
  final FinishReason finishReason;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;

  const FinishEvent({
    required this.finishReason,
    this.usage,
    this.providerMetadata,
  });
}

final class ErrorEvent extends TextStreamEvent {
  final Object error;

  const ErrorEvent(this.error);
}
