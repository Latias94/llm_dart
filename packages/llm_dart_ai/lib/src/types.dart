import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'content_part.dart';
import 'ai_errors.dart';

/// Settings for controlling what data is retained in results.
///
/// This is aligned with AI SDK's `experimental_include` concept. It can help
/// reduce memory usage when processing large payloads like images.
class IncludeOptions {
  /// Whether to retain the request body in results/steps.
  final bool requestBody;

  /// Whether to retain the response body in results/steps.
  final bool responseBody;

  const IncludeOptions({
    this.requestBody = true,
    this.responseBody = true,
  });
}

/// Result for a non-streaming text generation call.
class GenerateTextResult {
  final List<ContentPart>? _contentParts;

  final String? text;
  final String? thinking;
  final List<ToolCall>? toolCalls;
  final List<ToolResult> toolResults;
  final UsageInfo? usage;
  final UsageInfo? totalUsage;
  final LLMFinishReason? finishReason;
  final List<ToolLoopStep> steps;
  final List<LLMStreamPart> sources;
  final List<LLMFilePart> files;

  /// Best-effort request metadata for this generation (provider-dependent).
  ///
  /// When available, this includes the (sanitized) HTTP request body that was
  /// sent to the provider.
  final LLMRequestMetadataPart? requestMetadata;

  /// Best-effort response metadata for this generation (provider-dependent).
  ///
  /// When available, this includes HTTP response headers (for HTTP providers)
  /// and stable response identifiers/timestamps.
  final LLMResponseMetadataPart? responseMetadata;

  /// Best-effort response messages for this generation.
  ///
  /// This is intended to align with AI SDK's `result.response.messages` concept.
  /// Providers that can expose an exact assistant message should implement
  /// [ChatResponseWithAssistantMessage]. Otherwise, we derive a best-effort
  /// message from `text` and/or `toolCalls`.
  final List<ChatMessage> responseMessages;

  /// Best-effort response prompt messages for this generation (Vercel-style IR).
  ///
  /// This is a closer semantic match to AI SDK `ResponseMessage` types because
  /// it can represent tool-role messages via [PromptRole.tool].
  final List<PromptMessage> responsePromptMessages;

  /// The raw provider response object for advanced use cases.
  final ChatResponse rawResponse;

  const GenerateTextResult({
    required this.rawResponse,
    List<ContentPart>? content,
    this.text,
    this.thinking,
    this.toolCalls,
    this.toolResults = const <ToolResult>[],
    this.usage,
    this.totalUsage,
    this.finishReason,
    this.requestMetadata,
    this.responseMetadata,
    this.responseMessages = const <ChatMessage>[],
    this.responsePromptMessages = const <PromptMessage>[],
    this.steps = const <ToolLoopStep>[],
    this.sources = const <LLMStreamPart>[],
    this.files = const <LLMFilePart>[],
  }) : _contentParts = content;

  /// Text output (AI SDK-style).
  ///
  /// Throws [NoOutputGeneratedError] when no text was produced.
  String get output => text ?? (throw const NoOutputGeneratedError());

  /// AI SDK-inspired content parts for the last step.
  ///
  /// If [content] was provided in the constructor, it is returned as-is.
  /// Otherwise, this is derived best-effort from [text], [thinking],
  /// [toolCalls], [toolResults], [sources], and [files].
  List<ContentPart> get content => _contentParts ?? _deriveContentParts();

  List<ContentPart> _deriveContentParts() {
    final out = <ContentPart>[];

    final thinkingText = thinking;
    if (thinkingText != null && thinkingText.trim().isNotEmpty) {
      out.add(ReasoningContentPart(thinkingText));
    }

    final textValue = text;
    if (textValue != null && textValue.isNotEmpty) {
      out.add(TextContentPart(textValue));
    }

    for (final part in sources) {
      if (part is LLMSourceUrlPart) {
        out.add(
          SourceUrlContentPart(
            sourceId: part.sourceId,
            url: part.url,
            title: part.title,
            providerMetadata: part.providerMetadata,
          ),
        );
      } else if (part is LLMSourceDocumentPart) {
        out.add(
          SourceDocumentContentPart(
            sourceId: part.sourceId,
            mediaType: part.mediaType,
            title: part.title,
            filename: part.filename,
            providerMetadata: part.providerMetadata,
          ),
        );
      }
    }

    for (final f in files) {
      out.add(FileContentPart(f));
    }

    final calls = toolCalls;
    if (calls != null && calls.isNotEmpty) {
      for (final c in calls) {
        out.add(ToolCallContentPart(c));
      }
    }

    if (toolResults.isNotEmpty) {
      for (final r in toolResults) {
        out.add(r.isError ? ToolErrorContentPart(r) : ToolResultContentPart(r));
      }
    }

    return List<ContentPart>.unmodifiable(out);
  }

  Map<String, dynamic>? get providerMetadata => rawResponse.providerMetadata;
}

typedef GenerateTextOnStepFinishCallback = FutureOr<void> Function(
  ToolLoopStep step,
);

class GenerateTextFinishEvent {
  final GenerateTextResult result;
  final List<ToolLoopStep> steps;
  final UsageInfo? totalUsage;

  const GenerateTextFinishEvent({
    required this.result,
    required this.steps,
    required this.totalUsage,
  });
}

typedef GenerateTextOnFinishCallback = FutureOr<void> Function(
  GenerateTextFinishEvent event,
);

/// Result for a single embedding call (AI SDK-style).
class EmbedResult {
  /// The value that was embedded.
  final String value;

  /// The embedding vector.
  final List<double> embedding;

  /// Token usage for the call.
  final EmbeddingUsage usage;

  /// Warnings for the call, e.g. unsupported settings.
  final List<LLMWarning> warnings;

  /// Optional provider-specific metadata.
  final Map<String, dynamic>? providerMetadata;

  /// Optional response information for debugging purposes.
  final EmbeddingCallResponse? response;

  const EmbedResult({
    required this.value,
    required this.embedding,
    required this.usage,
    this.warnings = const <LLMWarning>[],
    this.providerMetadata,
    this.response,
  });
}

/// Result for an embedMany call (AI SDK-style).
class EmbedManyResult {
  /// The values that were embedded.
  final List<String> values;

  /// The embeddings. They are in the same order as the values.
  final List<List<double>> embeddings;

  /// Token usage for the call. (Aggregated across underlying calls when split.)
  final EmbeddingUsage usage;

  /// Warnings for the call, e.g. unsupported settings.
  final List<LLMWarning> warnings;

  /// Optional provider-specific metadata.
  final Map<String, dynamic>? providerMetadata;

  /// Optional response information for debugging purposes.
  ///
  /// This is a list because embedMany may split into multiple calls when
  /// providers impose batch limits.
  final List<EmbeddingCallResponse?> responses;

  const EmbedManyResult({
    required this.values,
    required this.embeddings,
    required this.usage,
    this.warnings = const <LLMWarning>[],
    this.providerMetadata,
    this.responses = const <EmbeddingCallResponse?>[],
  });
}

/// Result for an image generation call.
class GenerateImageResult {
  /// The raw (standard) image generation response.
  final ImageGenerationResponse rawResponse;

  const GenerateImageResult({required this.rawResponse});

  List<GeneratedImage> get images => rawResponse.images;
  String? get model => rawResponse.model;
  String? get revisedPrompt => rawResponse.revisedPrompt;
  UsageInfo? get usage => rawResponse.usage;
}

/// Experimental result for a video generation call.
///
/// Aligned with Vercel AI SDK's `experimental_generateVideo`.
class ExperimentalGenerateVideoResult {
  final ExperimentalVideoGenerationResponse rawResponse;

  const ExperimentalGenerateVideoResult({required this.rawResponse});

  ExperimentalGeneratedVideo get video => rawResponse.video;
  List<ExperimentalGeneratedVideo> get videos => rawResponse.videos;
  List<LLMWarning> get warnings => rawResponse.warnings;

  /// Response metadata for each underlying provider call.
  ///
  /// This is a list because `experimentalGenerateVideo` may split the request
  /// into multiple calls when `n` exceeds the model's `maxVideosPerCall`.
  List<ExperimentalVideoResponseMetadata> get responses =>
      rawResponse.responses;
  Map<String, dynamic>? get providerMetadata => rawResponse.providerMetadata;
}

/// Result for a speech generation (TTS) call.
class GenerateSpeechResult {
  /// The raw (standard) TTS response.
  final TTSResponse rawResponse;

  const GenerateSpeechResult({required this.rawResponse});

  List<int> get audioData => rawResponse.audioData;
  String? get contentType => rawResponse.contentType;
  double? get duration => rawResponse.duration;
  int? get sampleRate => rawResponse.sampleRate;
  String? get voice => rawResponse.voice;
  String? get model => rawResponse.model;
  UsageInfo? get usage => rawResponse.usage;
}

/// Result for a transcription (STT) call.
class TranscribeResult {
  /// The raw (standard) STT response.
  final STTResponse rawResponse;

  const TranscribeResult({required this.rawResponse});

  String get text => rawResponse.text;
  String? get language => rawResponse.language;
  double? get confidence => rawResponse.confidence;
  double? get duration => rawResponse.duration;
  UsageInfo? get usage => rawResponse.usage;
}

/// A single non-streaming step in a tool loop.
class ToolLoopStep {
  final int index;
  final GenerateTextResult result;
  final List<ToolCall> toolCalls;
  final List<ToolResult> toolResults;

  /// Best-effort response metadata for this step.
  ///
  /// When available, this includes HTTP response headers (for HTTP providers)
  /// and stable response identifiers/timestamps.
  final LLMResponseMetadataPart? responseMetadata;

  /// Best-effort request metadata for this step (provider-dependent).
  final LLMRequestMetadataPart? requestMetadata;

  /// Best-effort response prompt messages for this step (AI SDK-style).
  ///
  /// When tool results are available, this can include a `tool` role message
  /// that contains the tool outputs.
  final List<PromptMessage> responsePromptMessages;

  const ToolLoopStep({
    required this.index,
    required this.result,
    required this.toolCalls,
    required this.toolResults,
    this.responseMetadata,
    this.requestMetadata,
    this.responsePromptMessages = const <PromptMessage>[],
  });
}

/// Alias for naming parity with AI SDK (`StepResult`).
typedef StepResult = ToolLoopStep;

/// Result for a non-streaming tool loop run.
class ToolLoopResult {
  final GenerateTextResult finalResult;
  final List<ToolLoopStep> steps;
  final List<ChatMessage> messages;

  /// Best-effort prompt IR for the full tool loop run.
  ///
  /// This preserves `tool` role messages and prompt parts more faithfully than
  /// the legacy [messages] list.
  final Prompt? prompt;

  const ToolLoopResult({
    required this.finalResult,
    required this.steps,
    required this.messages,
    this.prompt,
  });
}

/// Tool loop state returned when tool execution is blocked by an approval check.
class ToolLoopBlockedState {
  final int stepIndex;
  final GenerateTextResult stepResult;
  final List<ToolCall> toolCalls;

  /// Tool approval requests that must be approved/denied to continue.
  ///
  /// Mirrors AI SDK `toolApprovalRequests` / `tool-approval-request` parts.
  final List<ToolApprovalRequest> toolApprovalRequests;
  final List<ToolLoopStep> steps;
  final List<ChatMessage> messages;

  /// Best-effort prompt IR at the point where the loop was blocked.
  final Prompt? prompt;

  const ToolLoopBlockedState({
    required this.stepIndex,
    required this.stepResult,
    required this.toolCalls,
    required this.toolApprovalRequests,
    required this.steps,
    required this.messages,
    this.prompt,
  });
}

/// Tool approval request (AI SDK-style).
///
/// The user should respond with a [ToolApprovalDecision] referencing [approvalId].
class ToolApprovalRequest {
  final String approvalId;
  final ToolCall toolCall;

  const ToolApprovalRequest({
    required this.approvalId,
    required this.toolCall,
  });
}

/// Outcome of a non-streaming tool loop that can stop when approval is required.
sealed class ToolLoopRunOutcome {
  const ToolLoopRunOutcome();
}

class ToolLoopCompleted extends ToolLoopRunOutcome {
  final ToolLoopResult result;
  const ToolLoopCompleted(this.result);
}

class ToolLoopBlocked extends ToolLoopRunOutcome {
  final ToolLoopBlockedState state;
  const ToolLoopBlocked(this.state);
}

/// A decision for a tool approval request (AI SDK-style).
///
/// In the UI message stream, this maps to the `tool-approval-request` chunk
/// (`approvalId`) and can be resumed by producing a corresponding
/// `tool-approval-response` in prompt IR (best-effort).
class ToolApprovalDecision {
  /// Approval request id.
  final String approvalId;

  /// Whether the tool execution is approved.
  final bool approved;

  /// Optional reason for approving/denying.
  final String? reason;

  const ToolApprovalDecision({
    required this.approvalId,
    required this.approved,
    this.reason,
  });
}

/// Callback for handling provider-emitted tool approval requests.
///
/// When a provider emits [LLMProviderToolApprovalRequestPart] (e.g. MCP tools),
/// this handler can decide whether to approve/deny and return decisions that
/// will be sent back to the model as prompt IR tool-approval responses.
typedef ProviderToolApprovalHandler = Future<List<ToolApprovalDecision>>
    Function(
  List<LLMProviderToolApprovalRequestPart> requests,
);

/// Tool approval blocked state for provider-executed tools.
///
/// This is returned (via [ProviderToolApprovalRequiredError]) when streaming is
/// paused because the provider requested tool approval.
class ProviderToolApprovalBlockedState {
  final int stepIndex;

  /// Prompt IR at the start of the blocked step.
  final Prompt prompt;

  /// Approval requests emitted by the provider.
  final List<LLMProviderToolApprovalRequestPart> approvalRequests;

  /// Best-effort assistant text emitted before the approval request.
  final String assistantText;

  /// Provider-executed tool calls emitted in the blocked step (best-effort).
  final List<LLMProviderToolCallPart> providerToolCalls;

  const ProviderToolApprovalBlockedState({
    required this.stepIndex,
    required this.prompt,
    required this.approvalRequests,
    required this.assistantText,
    required this.providerToolCalls,
  });
}

/// Error thrown/emitted when provider tool approval is required to continue.
class ProviderToolApprovalRequiredError extends LLMError {
  final ProviderToolApprovalBlockedState state;

  const ProviderToolApprovalRequiredError({
    required this.state,
    String message = 'Provider tool approval required',
  }) : super(message);

  @override
  String toString() => 'Provider tool approval required: $message';
}

/// Error thrown/emitted when a tool loop needs user approval to continue.
class ToolApprovalRequiredError extends LLMError {
  final ToolLoopBlockedState state;

  const ToolApprovalRequiredError({
    required this.state,
    String message = 'Tool approval required',
  }) : super(message);

  @override
  String toString() => 'Tool approval required: $message';
}

/// Result for a rerank call.
class RerankResult {
  /// The raw rerank response.
  final RerankResponse rawResponse;

  const RerankResult({required this.rawResponse});

  List<RerankResultItem> get results => rawResponse.results;
  String? get model => rawResponse.model;
  UsageInfo? get usage => rawResponse.usage;
}
