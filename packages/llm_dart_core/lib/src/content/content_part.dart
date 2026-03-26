import '../common/provider_metadata.dart';

final class SourceReference {
  final String sourceId;
  final Uri? uri;
  final String? title;
  final String? mediaType;
  final ProviderMetadata? providerMetadata;

  const SourceReference({
    required this.sourceId,
    this.uri,
    this.title,
    this.mediaType,
    this.providerMetadata,
  });
}

final class GeneratedFile {
  final String mediaType;
  final String? filename;
  final Uri? uri;
  final List<int>? bytes;

  const GeneratedFile({
    required this.mediaType,
    this.filename,
    this.uri,
    this.bytes,
  });
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
  final Object? output;
  final bool isError;
  final bool preliminary;
  final bool isDynamic;

  const ToolResultContent({
    required this.toolCallId,
    required this.toolName,
    this.output,
    this.isError = false,
    this.preliminary = false,
    this.isDynamic = false,
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
