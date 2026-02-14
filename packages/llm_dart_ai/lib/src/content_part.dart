import 'package:llm_dart_core/llm_dart_core.dart';

/// AI SDK-inspired "content part" union for non-streaming and streaming results.
///
/// This stays Dart-flavored (sealed classes) while keeping the same high-level
/// semantics as Vercel AI SDK v3 `ContentPart`.
sealed class ContentPart {
  const ContentPart();

  /// Discriminator aligned with AI SDK v3 (`text`, `reasoning`, `source`, ...).
  String get type;

  /// Optional provider metadata for this part.
  ///
  /// When present, it follows the same shape as [ChatResponse.providerMetadata]:
  /// `{ providerId: { ... } }`.
  Map<String, dynamic>? get providerMetadata => null;
}

final class TextContentPart extends ContentPart {
  final String text;

  @override
  final Map<String, dynamic>? providerMetadata;

  const TextContentPart(this.text, {this.providerMetadata});

  @override
  String get type => 'text';
}

final class ReasoningContentPart extends ContentPart {
  final String text;

  @override
  final Map<String, dynamic>? providerMetadata;

  const ReasoningContentPart(this.text, {this.providerMetadata});

  @override
  String get type => 'reasoning';
}

sealed class SourceContentPart extends ContentPart {
  const SourceContentPart();

  String get sourceId;
}

final class SourceUrlContentPart extends SourceContentPart {
  @override
  final String sourceId;
  final String url;
  final String? title;

  @override
  final Map<String, dynamic>? providerMetadata;

  const SourceUrlContentPart({
    required this.sourceId,
    required this.url,
    this.title,
    this.providerMetadata,
  });

  @override
  String get type => 'source';
}

final class SourceDocumentContentPart extends SourceContentPart {
  @override
  final String sourceId;
  final String mediaType;
  final String title;
  final String? filename;

  @override
  final Map<String, dynamic>? providerMetadata;

  const SourceDocumentContentPart({
    required this.sourceId,
    required this.mediaType,
    required this.title,
    this.filename,
    this.providerMetadata,
  });

  @override
  String get type => 'source';
}

final class FileContentPart extends ContentPart {
  final LLMFilePart file;

  const FileContentPart(this.file);

  @override
  String get type => 'file';

  @override
  Map<String, dynamic>? get providerMetadata => file.providerMetadata;
}

final class ToolCallContentPart extends ContentPart {
  final ToolCall toolCall;

  const ToolCallContentPart(this.toolCall);

  @override
  String get type => 'tool-call';
}

/// Provider-executed tool call (server-side).
///
/// Mirrors AI SDK v3 `tool-call` with `providerExecuted=true`, but is distinct
/// from [ToolCallContentPart] to avoid conflating it with local function tools.
final class ProviderToolCallContentPart extends ContentPart {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final bool? providerExecuted;
  final bool? isDynamic;

  @override
  final Map<String, dynamic>? providerMetadata;

  const ProviderToolCallContentPart({
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.providerExecuted,
    this.isDynamic,
    this.providerMetadata,
  });

  @override
  String get type => 'tool-call';
}

/// Provider-executed tool progress/status update (server-side).
///
/// This is a Dart-only extension that mirrors [LLMProviderToolDeltaPart].
final class ProviderToolDeltaContentPart extends ContentPart {
  final String toolCallId;
  final String toolName;
  final String status;
  final Object? data;

  @override
  final Map<String, dynamic>? providerMetadata;

  const ProviderToolDeltaContentPart({
    required this.toolCallId,
    required this.toolName,
    required this.status,
    this.data,
    this.providerMetadata,
  });

  @override
  String get type => 'provider-tool-delta';
}

final class ToolResultContentPart extends ContentPart {
  final ToolResult toolResult;

  const ToolResultContentPart(this.toolResult);

  @override
  String get type => 'tool-result';
}

/// Provider-executed tool result (server-side).
final class ProviderToolResultContentPart extends ContentPart {
  final String toolCallId;
  final String toolName;
  final Object? result;
  final bool? preliminary;
  final bool? isDynamic;

  @override
  final Map<String, dynamic>? providerMetadata;

  const ProviderToolResultContentPart({
    required this.toolCallId,
    required this.toolName,
    this.result,
    this.preliminary,
    this.isDynamic,
    this.providerMetadata,
  });

  @override
  String get type => 'tool-result';
}

final class ToolErrorContentPart extends ContentPart {
  final ToolResult toolResult;

  ToolErrorContentPart(this.toolResult) {
    assert(toolResult.isError, 'ToolErrorContentPart requires isError=true');
  }

  @override
  String get type => 'tool-error';
}

/// Provider-executed tool error result (server-side).
final class ProviderToolErrorContentPart extends ContentPart {
  final String toolCallId;
  final String toolName;
  final Object? error;
  final bool? preliminary;
  final bool? isDynamic;

  @override
  final Map<String, dynamic>? providerMetadata;

  const ProviderToolErrorContentPart({
    required this.toolCallId,
    required this.toolName,
    this.error,
    this.preliminary,
    this.isDynamic,
    this.providerMetadata,
  });

  @override
  String get type => 'tool-error';
}

/// Provider-emitted tool approval request (server-side).
///
/// Mirrors AI SDK v3 `type: 'tool-approval-request'` semantics, but uses the
/// provider tool identifiers from [LLMProviderToolApprovalRequestPart].
final class ProviderToolApprovalRequestContentPart extends ContentPart {
  final String approvalId;
  final String toolCallId;
  final String toolName;
  final Object? input;

  @override
  final Map<String, dynamic>? providerMetadata;

  const ProviderToolApprovalRequestContentPart({
    required this.approvalId,
    required this.toolCallId,
    required this.toolName,
    this.input,
    this.providerMetadata,
  });

  @override
  String get type => 'tool-approval-request';
}

/// Tool approval request for a locally executable tool call.
///
/// Mirrors AI SDK `ToolApprovalRequestOutput` where the request references the
/// full tool call.
final class ToolApprovalRequestContentPart extends ContentPart {
  final String approvalId;
  final ToolCall toolCall;

  const ToolApprovalRequestContentPart({
    required this.approvalId,
    required this.toolCall,
  });

  @override
  String get type => 'tool-approval-request';
}
