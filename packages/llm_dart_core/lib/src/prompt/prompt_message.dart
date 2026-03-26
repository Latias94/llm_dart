enum PromptRole {
  system,
  user,
  assistant,
  tool,
}

sealed class PromptPart {
  const PromptPart();
}

final class TextPromptPart extends PromptPart {
  final String text;

  const TextPromptPart(this.text);
}

final class FilePromptPart extends PromptPart {
  final String mediaType;
  final String? filename;
  final Uri? uri;
  final List<int>? bytes;

  const FilePromptPart({
    required this.mediaType,
    this.filename,
    this.uri,
    this.bytes,
  });
}

final class ImagePromptPart extends PromptPart {
  final String mediaType;
  final Uri? uri;
  final List<int>? bytes;

  const ImagePromptPart({
    required this.mediaType,
    this.uri,
    this.bytes,
  });
}

final class ToolCallPromptPart extends PromptPart {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;

  const ToolCallPromptPart({
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.title,
  });
}

final class ToolApprovalRequestPromptPart extends PromptPart {
  final String approvalId;
  final String toolCallId;

  const ToolApprovalRequestPromptPart({
    required this.approvalId,
    required this.toolCallId,
  });
}

final class ToolResultPromptPart extends PromptPart {
  final String toolCallId;
  final String toolName;
  final Object? output;
  final bool isError;

  const ToolResultPromptPart({
    required this.toolCallId,
    required this.toolName,
    this.output,
    this.isError = false,
  });
}

final class ToolApprovalResponsePromptPart extends PromptPart {
  final String approvalId;
  final String toolCallId;
  final bool approved;

  const ToolApprovalResponsePromptPart({
    required this.approvalId,
    required this.toolCallId,
    required this.approved,
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
