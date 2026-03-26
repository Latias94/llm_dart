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

sealed class ChatUiPart {
  const ChatUiPart();
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
  final Object? output;
  final String? errorText;
  final ProviderMetadata? providerMetadata;

  const ToolUiPart({
    required this.toolCallId,
    required this.toolName,
    required this.state,
    this.input,
    this.output,
    this.errorText,
    this.providerMetadata,
  });
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
