import 'dart:async';

import '../common/model_error.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../content/content_part.dart';
import '../model/finish_reason.dart';
import '../model/model_response_metadata.dart';

/// Provider-owned event base for one language model call stream.
///
/// Runtime lifecycle events such as step start, step finish, tool-output
/// denial, and abort belong to `llm_dart_ai` full-stream events, not provider
/// model-call contracts.
sealed class LanguageModelStreamEvent {
  const LanguageModelStreamEvent();
}

final class StartEvent extends LanguageModelStreamEvent {
  final List<ModelWarning> warnings;

  StartEvent({
    List<ModelWarning> warnings = const [],
  }) : warnings = List.unmodifiable(warnings);
}

final class ResponseMetadataEvent extends LanguageModelStreamEvent {
  final ModelResponseMetadata? responseMetadata;
  final String? _responseId;
  final DateTime? _timestamp;
  final String? _modelId;
  final ProviderMetadata? providerMetadata;

  const ResponseMetadataEvent({
    this.responseMetadata,
    String? responseId,
    DateTime? timestamp,
    String? modelId,
    this.providerMetadata,
  })  : _responseId = responseId,
        _timestamp = timestamp,
        _modelId = modelId;

  String? get responseId => responseMetadata?.id ?? _responseId;

  DateTime? get timestamp => responseMetadata?.timestamp ?? _timestamp;

  String? get modelId => responseMetadata?.modelId ?? _modelId;
}

final class TextStartEvent extends LanguageModelStreamEvent {
  final String id;
  final ProviderMetadata? providerMetadata;

  const TextStartEvent({
    required this.id,
    this.providerMetadata,
  });
}

final class TextDeltaEvent extends LanguageModelStreamEvent {
  final String id;
  final String delta;
  final ProviderMetadata? providerMetadata;

  const TextDeltaEvent({
    required this.id,
    required this.delta,
    this.providerMetadata,
  });
}

final class TextEndEvent extends LanguageModelStreamEvent {
  final String id;
  final ProviderMetadata? providerMetadata;

  const TextEndEvent({
    required this.id,
    this.providerMetadata,
  });
}

final class ReasoningStartEvent extends LanguageModelStreamEvent {
  final String id;
  final ProviderMetadata? providerMetadata;

  const ReasoningStartEvent({
    required this.id,
    this.providerMetadata,
  });
}

final class ReasoningDeltaEvent extends LanguageModelStreamEvent {
  final String id;
  final String delta;
  final ProviderMetadata? providerMetadata;

  const ReasoningDeltaEvent({
    required this.id,
    required this.delta,
    this.providerMetadata,
  });
}

final class ReasoningEndEvent extends LanguageModelStreamEvent {
  final String id;
  final ProviderMetadata? providerMetadata;

  const ReasoningEndEvent({
    required this.id,
    this.providerMetadata,
  });
}

final class ReasoningFileEvent extends LanguageModelStreamEvent {
  final GeneratedFile file;
  final ProviderMetadata? providerMetadata;

  const ReasoningFileEvent(
    this.file, {
    this.providerMetadata,
  });
}

final class ToolInputStartEvent extends LanguageModelStreamEvent {
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

final class ToolInputDeltaEvent extends LanguageModelStreamEvent {
  final String toolCallId;
  final String delta;
  final ProviderMetadata? providerMetadata;

  const ToolInputDeltaEvent({
    required this.toolCallId,
    required this.delta,
    this.providerMetadata,
  });
}

final class ToolInputEndEvent extends LanguageModelStreamEvent {
  final String toolCallId;
  final ProviderMetadata? providerMetadata;

  const ToolInputEndEvent({
    required this.toolCallId,
    this.providerMetadata,
  });
}

final class ToolInputErrorEvent extends LanguageModelStreamEvent {
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

final class ToolCallEvent extends LanguageModelStreamEvent {
  final ToolCallContent toolCall;
  final ProviderMetadata? providerMetadata;

  const ToolCallEvent({
    required this.toolCall,
    this.providerMetadata,
  });
}

final class ToolResultEvent extends LanguageModelStreamEvent {
  final ToolResultContent toolResult;
  final ProviderMetadata? providerMetadata;

  const ToolResultEvent({
    required this.toolResult,
    this.providerMetadata,
  });
}

final class ToolApprovalRequestEvent extends LanguageModelStreamEvent {
  final String approvalId;
  final String toolCallId;
  final ProviderMetadata? providerMetadata;

  const ToolApprovalRequestEvent({
    required this.approvalId,
    required this.toolCallId,
    this.providerMetadata,
  });
}

final class SourceEvent extends LanguageModelStreamEvent {
  final SourceReference source;

  const SourceEvent(this.source);
}

final class FileEvent extends LanguageModelStreamEvent {
  final GeneratedFile file;
  final ProviderMetadata? providerMetadata;

  const FileEvent(
    this.file, {
    this.providerMetadata,
  });
}

final class FinishEvent extends LanguageModelStreamEvent {
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

final class CustomEvent extends LanguageModelStreamEvent {
  final String kind;
  final Object? data;
  final ProviderMetadata? providerMetadata;

  const CustomEvent({
    required this.kind,
    this.data,
    this.providerMetadata,
  });
}

final class RawChunkEvent extends LanguageModelStreamEvent {
  final Object? raw;

  const RawChunkEvent(this.raw);
}

final class ErrorEvent extends LanguageModelStreamEvent {
  final ModelError error;

  const ErrorEvent(this.error);
}

bool isLanguageModelStreamEvent(LanguageModelStreamEvent event) => true;

void validateLanguageModelStreamEvent(
  LanguageModelStreamEvent event, {
  String context = 'LanguageModelStreamEvent',
}) {}

Stream<LanguageModelStreamEvent> validateLanguageModelStreamEvents(
  Stream<LanguageModelStreamEvent> events, {
  String context = 'LanguageModelStreamEvent',
}) async* {
  await for (final event in events) {
    validateLanguageModelStreamEvent(event, context: context);
    yield event;
  }
}
