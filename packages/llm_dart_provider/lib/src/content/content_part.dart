import '../common/provider_metadata.dart';
import '../common/provider_reference.dart';
import '../tool/tool_output.dart';
import 'file_data.dart';

enum SourceReferenceKind { url, document, other }

final class SourceReference {
  final SourceReferenceKind kind;
  final String sourceId;
  final Uri? uri;
  final String? title;
  final String? filename;
  final String? mediaType;
  final ProviderMetadata? providerMetadata;

  const SourceReference({
    required this.kind,
    required this.sourceId,
    this.uri,
    this.title,
    this.filename,
    this.mediaType,
    this.providerMetadata,
  });
}

final class GeneratedFile {
  final String mediaType;
  final String? filename;
  final FileData data;

  const GeneratedFile({
    required this.mediaType,
    this.filename,
    required this.data,
  });

  Uri? get uri => data.uri;

  List<int>? get bytes => data.bytes;

  String? get text => data.text;

  ProviderReference? get providerReference => data.providerReference;
}

final class ToolCallContent {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;

  const ToolCallContent({
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.title,
  });
}

final class ToolResultContent {
  final String toolCallId;
  final String toolName;
  final ToolOutput toolOutput;
  final bool preliminary;
  final bool isDynamic;

  ToolResultContent({
    required this.toolCallId,
    required this.toolName,
    Object? output,
    ToolOutput? toolOutput,
    bool isError = false,
    this.preliminary = false,
    this.isDynamic = false,
  }) : toolOutput = toolOutput ??
            (isError
                ? (output is String
                    ? ErrorTextToolOutput(output)
                    : ErrorJsonToolOutput(output))
                : (output is String
                    ? TextToolOutput(output)
                    : JsonToolOutput(output)));

  Object? get output => toolOutput.value;

  bool get isError => toolOutput.isError;
}

final class ToolApprovalRequestContent {
  final String approvalId;
  final String toolCallId;

  const ToolApprovalRequestContent({
    required this.approvalId,
    required this.toolCallId,
  });
}

sealed class ContentPart {
  const ContentPart();
}

final class TextContentPart extends ContentPart {
  final String text;
  final ProviderMetadata? providerMetadata;

  const TextContentPart(
    this.text, {
    this.providerMetadata,
  });
}

final class ReasoningContentPart extends ContentPart {
  final String text;
  final ProviderMetadata? providerMetadata;

  const ReasoningContentPart(
    this.text, {
    this.providerMetadata,
  });
}

final class ReasoningFileContentPart extends ContentPart {
  final GeneratedFile file;
  final ProviderMetadata? providerMetadata;

  const ReasoningFileContentPart(
    this.file, {
    this.providerMetadata,
  });
}

final class ToolCallContentPart extends ContentPart {
  final ToolCallContent toolCall;
  final ProviderMetadata? providerMetadata;

  const ToolCallContentPart(
    this.toolCall, {
    this.providerMetadata,
  });
}

final class ToolResultContentPart extends ContentPart {
  final ToolResultContent toolResult;
  final ProviderMetadata? providerMetadata;

  const ToolResultContentPart(
    this.toolResult, {
    this.providerMetadata,
  });
}

final class ToolApprovalRequestContentPart extends ContentPart {
  final ToolApprovalRequestContent approvalRequest;
  final ProviderMetadata? providerMetadata;

  const ToolApprovalRequestContentPart(
    this.approvalRequest, {
    this.providerMetadata,
  });
}

final class SourceContentPart extends ContentPart {
  final SourceReference source;

  const SourceContentPart(this.source);
}

final class FileContentPart extends ContentPart {
  final GeneratedFile file;
  final ProviderMetadata? providerMetadata;

  const FileContentPart(
    this.file, {
    this.providerMetadata,
  });
}

final class CustomContentPart extends ContentPart {
  final String kind;
  final Object? data;
  final ProviderMetadata? providerMetadata;

  const CustomContentPart({
    required this.kind,
    this.data,
    this.providerMetadata,
  });
}
