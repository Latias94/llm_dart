import 'package:llm_dart_core/llm_dart_core.dart';

/// Result for a non-streaming text generation call.
class GenerateTextResult {
  final String? text;
  final String? thinking;
  final List<ToolCall>? toolCalls;
  final UsageInfo? usage;

  /// The raw provider response object for advanced use cases.
  final ChatResponse rawResponse;

  const GenerateTextResult({
    required this.rawResponse,
    this.text,
    this.thinking,
    this.toolCalls,
    this.usage,
  });

  Map<String, dynamic>? get providerMetadata => rawResponse.providerMetadata;
}

/// Stream parts for text generation (a stable, provider-agnostic surface).
sealed class TextStreamPart {
  const TextStreamPart();
}

class TextDeltaPart extends TextStreamPart {
  final String delta;
  const TextDeltaPart(this.delta);
}

class ThinkingDeltaPart extends TextStreamPart {
  final String delta;
  const ThinkingDeltaPart(this.delta);
}

class ToolCallDeltaPart extends TextStreamPart {
  final ToolCall toolCall;
  const ToolCallDeltaPart(this.toolCall);
}

class FinishPart extends TextStreamPart {
  final GenerateTextResult result;
  const FinishPart(this.result);
}

class ErrorPart extends TextStreamPart {
  final LLMError error;
  const ErrorPart(this.error);
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

  const ToolLoopStep({
    required this.index,
    required this.result,
    required this.toolCalls,
    required this.toolResults,
  });
}

/// Result for a non-streaming tool loop run.
class ToolLoopResult {
  final GenerateTextResult finalResult;
  final List<ToolLoopStep> steps;
  final List<ChatMessage> messages;

  const ToolLoopResult({
    required this.finalResult,
    required this.steps,
    required this.messages,
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

  const ToolLoopBlockedState({
    required this.stepIndex,
    required this.stepResult,
    required this.toolCalls,
    required this.toolCallsNeedingApproval,
    required this.steps,
    required this.messages,
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
