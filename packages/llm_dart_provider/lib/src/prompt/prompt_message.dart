import '../common/provider_metadata.dart';
import '../common/provider_reference.dart';
import '../content/file_data.dart';
import '../tool/tool_output.dart';

enum PromptRole {
  system,
  user,
  assistant,
  tool,
}

sealed class PromptPart {
  const PromptPart();

  ProviderMetadata? get providerMetadata => null;
}

final class TextPromptPart extends PromptPart {
  final String text;
  @override
  final ProviderMetadata? providerMetadata;

  const TextPromptPart(
    this.text, {
    this.providerMetadata,
  });
}

final class FilePromptPart extends PromptPart {
  final String mediaType;
  final String? filename;
  final FileData data;
  @override
  final ProviderMetadata? providerMetadata;

  const FilePromptPart({
    required this.mediaType,
    this.filename,
    required this.data,
    this.providerMetadata,
  });

  Uri? get uri => data.uri;

  List<int>? get bytes => data.bytes;

  String? get text => data.text;

  ProviderReference? get providerReference => data.providerReference;
}

final class ImagePromptPart extends PromptPart {
  final String mediaType;
  final FileData data;
  @override
  final ProviderMetadata? providerMetadata;

  const ImagePromptPart({
    required this.mediaType,
    required this.data,
    this.providerMetadata,
  });

  Uri? get uri => data.uri;

  List<int>? get bytes => data.bytes;

  String? get text => data.text;

  ProviderReference? get providerReference => data.providerReference;
}

final class ReasoningPromptPart extends PromptPart {
  final String text;
  @override
  final ProviderMetadata? providerMetadata;

  const ReasoningPromptPart(
    this.text, {
    this.providerMetadata,
  });
}

final class ReasoningFilePromptPart extends PromptPart {
  final String mediaType;
  final String? filename;
  final FileData data;
  @override
  final ProviderMetadata? providerMetadata;

  const ReasoningFilePromptPart({
    required this.mediaType,
    this.filename,
    required this.data,
    this.providerMetadata,
  });

  Uri? get uri => data.uri;

  List<int>? get bytes => data.bytes;

  String? get text => data.text;

  ProviderReference? get providerReference => data.providerReference;
}

final class CustomPromptPart extends PromptPart {
  final String kind;
  final Object? data;
  @override
  final ProviderMetadata? providerMetadata;

  const CustomPromptPart({
    required this.kind,
    this.data,
    this.providerMetadata,
  });
}

final class ToolCallPromptPart extends PromptPart {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  @override
  final ProviderMetadata? providerMetadata;

  const ToolCallPromptPart({
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.title,
    this.providerMetadata,
  });
}

final class ToolApprovalRequestPromptPart extends PromptPart {
  final String approvalId;
  final String toolCallId;
  @override
  final ProviderMetadata? providerMetadata;

  const ToolApprovalRequestPromptPart({
    required this.approvalId,
    required this.toolCallId,
    this.providerMetadata,
  });
}

final class ToolResultPromptPart extends PromptPart {
  final String toolCallId;
  final String toolName;
  final ToolOutput toolOutput;
  @override
  final ProviderMetadata? providerMetadata;

  ToolResultPromptPart({
    required this.toolCallId,
    required this.toolName,
    Object? output,
    ToolOutput? toolOutput,
    bool isError = false,
    this.providerMetadata,
  }) : toolOutput =
            toolOutput ?? ToolOutput.fromValue(output, isError: isError);

  Object? get output => toolOutput.value;

  bool get isError => toolOutput.isError;
}

final class ToolApprovalResponsePromptPart extends PromptPart {
  final String approvalId;
  final String toolCallId;
  final bool approved;
  final String? reason;
  @override
  final ProviderMetadata? providerMetadata;

  const ToolApprovalResponsePromptPart({
    required this.approvalId,
    required this.toolCallId,
    required this.approved,
    this.reason,
    this.providerMetadata,
  });
}

sealed class PromptMessage {
  const PromptMessage();

  PromptRole get role;

  List<PromptPart> get parts;
}

final class SystemPromptMessage extends PromptMessage {
  @override
  final List<PromptPart> parts;

  SystemPromptMessage({
    required List<PromptPart> parts,
  }) : parts = List.unmodifiable(parts);

  SystemPromptMessage.text(String text)
      : parts = List.unmodifiable([TextPromptPart(text)]);

  @override
  PromptRole get role => PromptRole.system;
}

final class UserPromptMessage extends PromptMessage {
  @override
  final List<PromptPart> parts;

  UserPromptMessage({
    required List<PromptPart> parts,
  }) : parts = List.unmodifiable(parts);

  UserPromptMessage.text(String text)
      : parts = List.unmodifiable([TextPromptPart(text)]);

  @override
  PromptRole get role => PromptRole.user;
}

final class AssistantPromptMessage extends PromptMessage {
  @override
  final List<PromptPart> parts;

  AssistantPromptMessage({
    required List<PromptPart> parts,
  }) : parts = List.unmodifiable(parts);

  AssistantPromptMessage.text(String text)
      : parts = List.unmodifiable([TextPromptPart(text)]);

  @override
  PromptRole get role => PromptRole.assistant;
}

final class ToolPromptMessage extends PromptMessage {
  final String toolName;

  @override
  final List<PromptPart> parts;

  ToolPromptMessage({
    required this.toolName,
    required List<PromptPart> parts,
  }) : parts = List.unmodifiable(parts);

  @override
  PromptRole get role => PromptRole.tool;
}
