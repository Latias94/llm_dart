import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../stream/text_stream_event.dart';
import '../ui/chat_ui_message.dart';
import '../ui/chat_ui_stream_chunk.dart';
import '../ui/chat_ui_stream_projection.dart';
import 'generate_text_run_result.dart';
import 'generate_text_step_result.dart';
import 'stream_result_foundation.dart';

final class StreamTextRunResult extends StreamView<TextStreamEvent> {
  final StreamResultHandle<TextStreamEvent, GenerateTextRunResult> _foundation;
  final Stream<GenerateTextStepResult> stepStream;

  StreamTextRunResult._({
    required StreamResultHandle<TextStreamEvent, GenerateTextRunResult>
        foundation,
    required this.stepStream,
  })  : _foundation = foundation,
        super(foundation.eventStream);

  Stream<TextStreamEvent> get eventStream => this;

  Stream<TextStreamEvent> get textStream => eventStream;

  Future<GenerateTextRunResult> get result => _foundation.result;

  Stream<ChatUiStreamChunk> chatUiStream({
    String? messageId,
    Map<String, Object?> messageMetadata = const {},
    Iterable<DataUiPart<Object?>> leadingDataParts = const [],
    Map<String, Object?> finalMessageMetadata = const {},
  }) {
    return projectTextStreamEventStream(
      eventStream,
      messageId: messageId,
      messageMetadata: messageMetadata,
      leadingDataParts: leadingDataParts,
      finalMessageMetadata: finalMessageMetadata,
    );
  }

  Future<List<GenerateTextStepResult>> get steps => result.then(
        (value) => value.steps,
      );

  Future<GenerateTextStepResult> get lastStep => result.then(
        (value) => value.lastStep,
      );

  Future<UsageStats?> get totalUsage => result.then(
        (value) => value.totalUsage,
      );

  Future<UsageStats?> get usage => totalUsage;

  Future<List<ContentPart>> get content => result.then(
        (value) => value.content,
      );

  Future<String> get text => result.then(
        (value) => value.text,
      );

  Future<String?> get reasoningText => result.then(
        (value) => value.reasoningText,
      );

  Future<FinishReason> get finishReason => result.then(
        (value) => value.finishReason,
      );

  Future<String?> get rawFinishReason => result.then(
        (value) => value.rawFinishReason,
      );

  Future<List<SourceReference>> get sources => result.then(
        (value) => value.sources,
      );

  Future<List<GeneratedFile>> get files => result.then(
        (value) => value.files,
      );

  Future<List<ToolCallContent>> get toolCalls => result.then(
        (value) => value.toolCalls,
      );

  Future<List<ToolCallContent>> get staticToolCalls => result.then(
        (value) => value.staticToolCalls,
      );

  Future<List<ToolCallContent>> get dynamicToolCalls => result.then(
        (value) => value.dynamicToolCalls,
      );

  Future<List<ToolResultContent>> get toolResults => result.then(
        (value) => value.toolResults,
      );

  Future<List<ToolResultContent>> get staticToolResults => result.then(
        (value) => value.staticToolResults,
      );

  Future<List<ToolResultContent>> get dynamicToolResults => result.then(
        (value) => value.dynamicToolResults,
      );

  Future<List<ToolApprovalRequestContent>> get toolApprovalRequests =>
      result.then(
        (value) => value.toolApprovalRequests,
      );

  Future<ModelResponseMetadata?> get responseMetadata => result.then(
        (value) => value.responseMetadata,
      );

  Future<String?> get responseId => result.then(
        (value) => value.responseId,
      );

  Future<DateTime?> get responseTimestamp => result.then(
        (value) => value.responseTimestamp,
      );

  Future<String?> get responseModelId => result.then(
        (value) => value.responseModelId,
      );

  Future<ProviderMetadata?> get providerMetadata => result.then(
        (value) => value.providerMetadata,
      );

  Future<List<ModelWarning>> get warnings => result.then(
        (value) => value.warnings,
      );
}

StreamTextRunResult createStreamTextRunResult({
  required StreamResultHandle<TextStreamEvent, GenerateTextRunResult>
      foundation,
  required Stream<GenerateTextStepResult> stepStream,
}) {
  return StreamTextRunResult._(
    foundation: foundation,
    stepStream: stepStream,
  );
}
