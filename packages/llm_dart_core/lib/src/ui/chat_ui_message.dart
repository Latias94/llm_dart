import '../common/provider_metadata.dart';
import '../content/content_part.dart';

enum ChatUiRole {
  system,
  user,
  assistant,
}

enum ToolUiPartState {
  inputStreaming,
  inputAvailable,
  approvalRequested,
  approvalResponded,
  outputAvailable,
  outputError,
  outputDenied,
}

final class ChatUiMetadataKeys {
  static const warnings = 'warnings';
  static const responseId = 'responseId';
  static const responseTimestamp = 'responseTimestamp';
  static const modelId = 'modelId';
  static const responseProviderMetadata = 'responseProviderMetadata';
  static const finishReason = 'finishReason';
  static const usage = 'usage';
  static const finishProviderMetadata = 'finishProviderMetadata';
  static const errors = 'errors';
  static const rawChunks = 'rawChunks';

  const ChatUiMetadataKeys._();
}

sealed class ChatUiPart {
  const ChatUiPart();
}

final class ToolApprovalUiState {
  final String approvalId;
  final bool? approved;

  const ToolApprovalUiState({
    required this.approvalId,
    this.approved,
  });
}

final class TextUiPart extends ChatUiPart {
  final String text;
  final bool isStreaming;
  final ProviderMetadata? providerMetadata;

  const TextUiPart({
    required this.text,
    this.isStreaming = false,
    this.providerMetadata,
  });
}

final class ReasoningUiPart extends ChatUiPart {
  final String text;
  final bool isStreaming;
  final ProviderMetadata? providerMetadata;

  const ReasoningUiPart({
    required this.text,
    this.isStreaming = false,
    this.providerMetadata,
  });
}

final class ToolUiPart extends ChatUiPart {
  final String toolCallId;
  final String toolName;
  final ToolUiPartState state;
  final Object? input;
  final String? inputText;
  final Object? output;
  final String? errorText;
  final bool providerExecuted;
  final bool isDynamic;
  final bool preliminary;
  final String? title;
  final ToolApprovalUiState? approval;
  final ProviderMetadata? callProviderMetadata;
  final ProviderMetadata? resultProviderMetadata;

  const ToolUiPart({
    required this.toolCallId,
    required this.toolName,
    required this.state,
    this.input,
    this.inputText,
    this.output,
    this.errorText,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.preliminary = false,
    this.title,
    this.approval,
    this.callProviderMetadata,
    this.resultProviderMetadata,
  });

  ProviderMetadata? get providerMetadata =>
      resultProviderMetadata ?? callProviderMetadata;
}

final class SourceUiPart extends ChatUiPart {
  final SourceReference source;

  const SourceUiPart(this.source);
}

final class FileUiPart extends ChatUiPart {
  final GeneratedFile file;
  final ProviderMetadata? providerMetadata;

  const FileUiPart(
    this.file, {
    this.providerMetadata,
  });
}

final class CustomUiPart extends ChatUiPart {
  final String kind;
  final Object? data;
  final ProviderMetadata? providerMetadata;

  const CustomUiPart({
    required this.kind,
    this.data,
    this.providerMetadata,
  });
}

final class StepBoundaryUiPart extends ChatUiPart {
  final String stepId;

  const StepBoundaryUiPart(this.stepId);
}

final class DataUiPart<T> extends ChatUiPart {
  final String key;
  final T data;

  const DataUiPart({
    required this.key,
    required this.data,
  });
}

final class ChatUiMessage {
  final String id;
  final ChatUiRole role;
  final List<ChatUiPart> parts;
  final Map<String, Object?> metadata;

  ChatUiMessage({
    required this.id,
    required this.role,
    required List<ChatUiPart> parts,
    Map<String, Object?> metadata = const {},
  })  : parts = List.unmodifiable(parts),
        metadata = Map.unmodifiable(metadata);
}
