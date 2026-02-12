import 'package:llm_dart_core/llm_dart_core.dart';

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
  final String? text;
  final String? thinking;
  final List<ToolCall>? toolCalls;
  final UsageInfo? usage;
  final LLMFinishReason? finishReason;

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
    this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
    this.finishReason,
    this.requestMetadata,
    this.responseMetadata,
    this.responseMessages = const <ChatMessage>[],
    this.responsePromptMessages = const <PromptMessage>[],
  });

  Map<String, dynamic>? get providerMetadata => rawResponse.providerMetadata;
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
  final List<ToolCall> toolCallsNeedingApproval;
  final List<ToolLoopStep> steps;
  final List<ChatMessage> messages;

  /// Best-effort prompt IR at the point where the loop was blocked.
  final Prompt? prompt;

  const ToolLoopBlockedState({
    required this.stepIndex,
    required this.stepResult,
    required this.toolCalls,
    required this.toolCallsNeedingApproval,
    required this.steps,
    required this.messages,
    this.prompt,
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
