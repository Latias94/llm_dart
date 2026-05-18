import 'dart:async';

import '../stream/text_stream_event.dart';
import '../ui/chat_ui_message.dart';
import '../ui/chat_ui_stream_chunk.dart';
import '../ui/chat_ui_stream_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_foundation.dart';
import 'stream_result_foundation.dart';

final class StreamOutputResult<T> {
  final StreamResultController<OutputStreamEvent<T>, GenerateOutputResult<T>>
      _foundation =
      StreamResultController<OutputStreamEvent<T>, GenerateOutputResult<T>>();
  final Completer<GenerateTextResult> _textResultCompleter =
      Completer<GenerateTextResult>();
  late final StreamSideChannel<Object?> _partialOutputChannel;
  late final StreamSideChannel<Object?> _elementChannel;
  var _hasFinishEvent = false;

  StreamOutputResult._(Stream<OutputStreamEvent<T>> source) {
    _partialOutputChannel = _foundation.createSideChannel<Object?>();
    _elementChannel = _foundation.createSideChannel<Object?>();
    _foundation.result.ignore();
    _textResultCompleter.future.ignore();
    source.listen(
      _handleEvent,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: true,
    );
  }

  Stream<OutputStreamEvent<T>> get eventStream => _foundation.eventStream;

  Stream<TextStreamEvent> get textStream =>
      eventStream.transform<TextStreamEvent>(
        StreamTransformer<OutputStreamEvent<T>, TextStreamEvent>.fromHandlers(
          handleData: (event, sink) {
            if (event case OutputTextStreamEvent<T>(:final streamEvent)) {
              sink.add(streamEvent);
            }
          },
        ),
      );

  Stream<Object?> get partialOutputStream => _partialOutputChannel.stream;

  Stream<TElement> elementStream<TElement>() =>
      _elementChannel.stream.cast<TElement>();

  Stream<ChatUiStreamChunk> chatUiStream({
    String? messageId,
    Map<String, Object?> messageMetadata = const {},
    Iterable<DataUiPart<Object?>> leadingDataParts = const [],
    Map<String, Object?> finalMessageMetadata = const {},
  }) {
    return projectTextStreamEventStream(
      textStream,
      messageId: messageId,
      messageMetadata: messageMetadata,
      leadingDataParts: leadingDataParts,
      finalMessageMetadata: finalMessageMetadata,
    );
  }

  Future<GenerateOutputResult<T>> get result => _foundation.result;

  Future<GenerateTextResult> get textResult => _textResultCompleter.future;

  Future<T> get output => result.then((value) => value.output);

  Future<String> get text => textResult.then((value) => value.text);

  Future<String?> get reasoningText =>
      textResult.then((value) => value.reasoningText);

  Future<FinishReason> get finishReason =>
      textResult.then((value) => value.finishReason);

  Future<String?> get rawFinishReason =>
      textResult.then((value) => value.rawFinishReason);

  Future<ModelResponseMetadata?> get responseMetadata =>
      textResult.then((value) => value.responseMetadata);

  Future<String?> get responseId =>
      textResult.then((value) => value.responseId);

  Future<DateTime?> get responseTimestamp =>
      textResult.then((value) => value.responseTimestamp);

  Future<String?> get responseModelId =>
      textResult.then((value) => value.responseModelId);

  Future<UsageStats?> get usage => textResult.then((value) => value.usage);

  Future<ProviderMetadata?> get providerMetadata =>
      textResult.then((value) => value.providerMetadata);

  Future<List<ModelWarning>> get warnings =>
      textResult.then((value) => value.warnings);

  void _handleEvent(OutputStreamEvent<T> event) {
    _foundation.addEvent(event);

    switch (event) {
      case OutputTextStreamEvent<T>():
        break;
      case OutputPartialEvent<T>(:final partialOutput):
        _partialOutputChannel.add(partialOutput);
      case OutputElementEvent(:final element):
        _elementChannel.add(element);
      case OutputFinishEvent<T>(:final result):
        _hasFinishEvent = true;
        if (!_textResultCompleter.isCompleted) {
          _textResultCompleter.complete(result);
        }
      case OutputResultEvent<T>(:final result):
        _foundation.completeResult(result);
      case OutputErrorEvent<T>(:final error, :final stackTrace):
        _foundation.completeError(error, stackTrace ?? StackTrace.current);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (!_textResultCompleter.isCompleted) {
      _textResultCompleter.completeError(error, stackTrace);
    }
    _foundation.fail(error, stackTrace);
  }

  void _handleDone() {
    if (!_hasFinishEvent) {
      _handleError(
        StateError(
          'streamOutputResult completed without emitting an OutputFinishEvent.',
        ),
        StackTrace.current,
      );
      return;
    }

    if (!_foundation.isResultCompleted) {
      _foundation.completeError(
        StateError(
          'streamOutputResult completed without emitting an OutputResultEvent '
          'or OutputErrorEvent.',
        ),
        StackTrace.current,
      );
    }

    _foundation.close();
  }
}

typedef StreamObjectResult<T> = StreamOutputResult<T>;

StreamOutputResult<T> createStreamOutputResult<T>(
  Stream<OutputStreamEvent<T>> source,
) {
  return StreamOutputResult<T>._(source);
}
