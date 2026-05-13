import 'dart:async';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import '../stream/text_stream_event.dart';
import '../ui/chat_ui_message.dart';
import '../ui/chat_ui_stream_chunk.dart';
import '../ui/chat_ui_stream_projection.dart';
import 'generate_text_result_accumulator.dart';
import 'language_model.dart';
import 'output_spec.dart';
import 'stream_result_foundation.dart';

final class GenerateTextCallResult<T> {
  final GenerateTextResult result;
  final bool hasOutput;
  final T? _output;

  const GenerateTextCallResult._({
    required this.result,
    required this.hasOutput,
    T? output,
  }) : _output = output;

  List<ContentPart> get content => result.content;

  String get text => result.text;

  String? get reasoningText => result.reasoningText;

  FinishReason get finishReason => result.finishReason;

  String? get rawFinishReason => result.rawFinishReason;

  String? get responseId => result.responseId;

  DateTime? get responseTimestamp => result.responseTimestamp;

  String? get responseModelId => result.responseModelId;

  UsageStats? get usage => result.usage;

  ProviderMetadata? get providerMetadata => result.providerMetadata;

  List<ModelWarning> get warnings => result.warnings;

  T get output {
    if (!hasOutput) {
      throw StateError(
        'GenerateTextCallResult does not contain parsed output. '
        'Provide outputSpec to generateTextCall(...).',
      );
    }

    return _output as T;
  }

  T? get outputOrNull => hasOutput ? _output : null;
}

final class StreamTextCallResult<T> extends StreamView<TextStreamEvent> {
  final StreamResultHandle<TextStreamEvent, GenerateTextResult> _foundation;
  final bool hasOutput;
  final Stream<Object?> partialOutputStream;
  final Stream<Object?> _elementStream;
  final Future<T>? _output;

  StreamTextCallResult._({
    required StreamResultHandle<TextStreamEvent, GenerateTextResult> foundation,
    required this.hasOutput,
    required this.partialOutputStream,
    required Stream<Object?> elementStream,
    required Future<T>? output,
  })  : _elementStream = elementStream,
        _output = output,
        _foundation = foundation,
        super(foundation.eventStream);

  factory StreamTextCallResult.raw(
    Stream<TextStreamEvent> source,
  ) {
    final streamResult =
        StreamResultController<TextStreamEvent, GenerateTextResult>();
    final partialOutputChannel = streamResult.createSideChannel<Object?>();
    final elementChannel = streamResult.createSideChannel<Object?>();
    final accumulator = GenerateTextResultAccumulator();

    source.listen(
      (event) {
        accumulator.apply(event);
        streamResult.addEvent(event);
      },
      onError: (Object error, StackTrace stackTrace) {
        streamResult.fail(error, stackTrace);
      },
      onDone: () {
        try {
          final result = accumulator.build();
          streamResult.completeResult(result);
          streamResult.close();
        } catch (error, stackTrace) {
          streamResult.fail(error, stackTrace);
        }
      },
      cancelOnError: true,
    );

    return StreamTextCallResult._(
      foundation: streamResult.handle,
      hasOutput: false,
      partialOutputStream: partialOutputChannel.stream,
      elementStream: elementChannel.stream,
      output: null,
    );
  }

  factory StreamTextCallResult.structured(
    StreamOutputResult<T> outputResult,
  ) {
    return StreamTextCallResult._(
      foundation: StreamResultHandle<TextStreamEvent, GenerateTextResult>(
        eventStream: outputResult.textStream,
        result: outputResult.result.then((value) => value.result),
      ),
      hasOutput: true,
      partialOutputStream: outputResult.partialOutputStream,
      elementStream: outputResult.elementStream<Object?>(),
      output: outputResult.output,
    );
  }

  Stream<TextStreamEvent> get eventStream => this;

  Stream<TextStreamEvent> get textStream => eventStream;

  Future<GenerateTextResult> get result => _foundation.result;

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

  Stream<TElement> elementStream<TElement>() => _elementStream.cast<TElement>();

  Future<List<ContentPart>> get content =>
      result.then((value) => value.content);

  Future<String> get text => result.then((value) => value.text);

  Future<String?> get reasoningText =>
      result.then((value) => value.reasoningText);

  Future<FinishReason> get finishReason =>
      result.then((value) => value.finishReason);

  Future<String?> get rawFinishReason =>
      result.then((value) => value.rawFinishReason);

  Future<String?> get responseId => result.then((value) => value.responseId);

  Future<DateTime?> get responseTimestamp =>
      result.then((value) => value.responseTimestamp);

  Future<String?> get responseModelId =>
      result.then((value) => value.responseModelId);

  Future<UsageStats?> get usage => result.then((value) => value.usage);

  Future<ProviderMetadata?> get providerMetadata =>
      result.then((value) => value.providerMetadata);

  Future<List<ModelWarning>> get warnings =>
      result.then((value) => value.warnings);

  Future<T> get output {
    if (_output case final output?) {
      return output;
    }

    return Future<T>.error(
      StateError(
        'StreamTextCallResult does not contain parsed output. '
        'Provide outputSpec to streamTextCall(...).',
      ),
    );
  }
}

Future<GenerateTextCallResult<T>> generateTextCall<T>({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  OutputSpec<T>? outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) async {
  if (outputSpec case final spec?) {
    final outputResult = await generateOutput(
      model: model,
      prompt: prompt,
      messages: messages,
      outputSpec: spec,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
    );
    return GenerateTextCallResult<T>._(
      result: outputResult.result,
      hasOutput: true,
      output: outputResult.output,
    );
  }

  final result = await generateText(
    model: model,
    prompt: prompt,
    messages: messages,
    tools: tools,
    toolChoice: toolChoice,
    options: options,
    callOptions: callOptions,
  );

  return GenerateTextCallResult<T>._(
    result: result,
    hasOutput: false,
  );
}

StreamTextCallResult<T> streamTextCall<T>({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  OutputSpec<T>? outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) {
  if (outputSpec case final spec?) {
    return StreamTextCallResult<T>.structured(
      streamOutputResult(
        model: model,
        prompt: prompt,
        messages: messages,
        outputSpec: spec,
        tools: tools,
        toolChoice: toolChoice,
        options: options,
        callOptions: callOptions,
      ),
    );
  }

  return StreamTextCallResult<T>.raw(
    streamText(
      model: model,
      prompt: prompt,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
    ),
  );
}
