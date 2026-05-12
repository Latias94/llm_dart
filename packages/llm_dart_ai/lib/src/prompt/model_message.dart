import 'package:llm_dart_provider/llm_dart_provider.dart';

enum ModelMessageRole {
  system,
  user,
  assistant,
  tool,
}

sealed class ModelMessage {
  const ModelMessage();

  ModelMessageRole get role;

  ProviderPromptPartOptions? get providerOptions => null;
}

final class SystemModelMessage extends ModelMessage {
  final String content;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const SystemModelMessage(
    this.content, {
    this.providerOptions,
  });

  const SystemModelMessage.text(
    String text, {
    this.providerOptions,
  }) : content = text;

  @override
  ModelMessageRole get role => ModelMessageRole.system;
}

final class UserModelMessage extends ModelMessage {
  final List<ModelPart> parts;
  @override
  final ProviderPromptPartOptions? providerOptions;

  UserModelMessage({
    required List<ModelPart> parts,
    this.providerOptions,
  }) : parts = List.unmodifiable(parts);

  UserModelMessage.text(
    String text, {
    this.providerOptions,
  }) : parts = List.unmodifiable([TextModelPart(text)]);

  @override
  ModelMessageRole get role => ModelMessageRole.user;
}

final class AssistantModelMessage extends ModelMessage {
  final List<ModelPart> parts;
  @override
  final ProviderPromptPartOptions? providerOptions;

  AssistantModelMessage({
    required List<ModelPart> parts,
    this.providerOptions,
  }) : parts = List.unmodifiable(parts);

  AssistantModelMessage.text(
    String text, {
    this.providerOptions,
  }) : parts = List.unmodifiable([TextModelPart(text)]);

  @override
  ModelMessageRole get role => ModelMessageRole.assistant;
}

final class ToolModelMessage extends ModelMessage {
  final List<ModelPart> parts;
  @override
  final ProviderPromptPartOptions? providerOptions;

  ToolModelMessage({
    required List<ModelPart> parts,
    this.providerOptions,
  }) : parts = List.unmodifiable(parts);

  ToolModelMessage.result({
    required String toolCallId,
    required String toolName,
    Object? output,
    ToolOutput? toolOutput,
    bool isError = false,
    ProviderPromptPartOptions? providerOptions,
  })  : parts = List.unmodifiable([
          ToolResultModelPart(
            toolCallId: toolCallId,
            toolName: toolName,
            output: output,
            toolOutput: toolOutput,
            isError: isError,
            providerOptions: providerOptions,
          ),
        ]),
        providerOptions = null;

  @override
  ModelMessageRole get role => ModelMessageRole.tool;
}

sealed class ModelPart {
  const ModelPart();

  ProviderPromptPartOptions? get providerOptions => null;
}

final class TextModelPart extends ModelPart {
  final String text;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const TextModelPart(
    this.text, {
    this.providerOptions,
  });
}

final class FileModelPart extends ModelPart {
  final String mediaType;
  final String? filename;
  final FileData data;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const FileModelPart({
    required this.mediaType,
    this.filename,
    required this.data,
    this.providerOptions,
  });
}

final class ImageModelPart extends ModelPart {
  final String mediaType;
  final FileData data;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const ImageModelPart({
    this.mediaType = 'image/*',
    required this.data,
    this.providerOptions,
  });
}

final class ReasoningModelPart extends ModelPart {
  final String text;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const ReasoningModelPart(
    this.text, {
    this.providerOptions,
  });
}

final class ReasoningFileModelPart extends ModelPart {
  final String mediaType;
  final String? filename;
  final FileData data;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const ReasoningFileModelPart({
    required this.mediaType,
    this.filename,
    required this.data,
    this.providerOptions,
  });
}

final class CustomModelPart extends ModelPart {
  final String kind;
  final Object? data;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const CustomModelPart({
    required this.kind,
    this.data,
    this.providerOptions,
  });
}

final class ToolCallModelPart extends ModelPart {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const ToolCallModelPart({
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.title,
    this.providerOptions,
  });
}

final class ToolApprovalRequestModelPart extends ModelPart {
  final String approvalId;
  final String toolCallId;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const ToolApprovalRequestModelPart({
    required this.approvalId,
    required this.toolCallId,
    this.providerOptions,
  });
}

final class ToolResultModelPart extends ModelPart {
  final String toolCallId;
  final String toolName;
  final ToolOutput toolOutput;
  @override
  final ProviderPromptPartOptions? providerOptions;

  ToolResultModelPart({
    required this.toolCallId,
    required this.toolName,
    Object? output,
    ToolOutput? toolOutput,
    bool isError = false,
    this.providerOptions,
  }) : toolOutput =
            toolOutput ?? ToolOutput.fromValue(output, isError: isError);

  Object? get output => toolOutput.value;

  bool get isError => toolOutput.isError;
}

final class ToolApprovalResponseModelPart extends ModelPart {
  final String approvalId;
  final String toolCallId;
  final String toolName;
  final bool approved;
  final String? reason;
  @override
  final ProviderPromptPartOptions? providerOptions;

  const ToolApprovalResponseModelPart({
    required this.approvalId,
    required this.toolCallId,
    required this.toolName,
    required this.approved,
    this.reason,
    this.providerOptions,
  });
}
