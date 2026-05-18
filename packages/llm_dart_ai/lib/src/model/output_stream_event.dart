import '../stream/text_stream_event.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_result.dart';

sealed class OutputStreamEvent<T> {
  const OutputStreamEvent();
}

final class OutputTextStreamEvent<T> extends OutputStreamEvent<T> {
  final TextStreamEvent streamEvent;

  const OutputTextStreamEvent(this.streamEvent);
}

final class OutputPartialEvent<T> extends OutputStreamEvent<T> {
  final Object? partialOutput;

  const OutputPartialEvent(this.partialOutput);
}

final class OutputElementEvent<T> extends OutputStreamEvent<List<T>> {
  final T element;

  const OutputElementEvent(this.element);
}

final class OutputFinishEvent<T> extends OutputStreamEvent<T> {
  final GenerateTextResult result;

  const OutputFinishEvent(this.result);

  List<ContentPart> get content => result.content;

  String get text => result.text;

  String? get reasoningText => result.reasoningText;

  FinishReason get finishReason => result.finishReason;

  String? get rawFinishReason => result.rawFinishReason;

  UsageStats? get usage => result.usage;

  ModelResponseMetadata? get responseMetadata => result.responseMetadata;

  String? get responseId => result.responseId;

  DateTime? get responseTimestamp => result.responseTimestamp;

  String? get responseModelId => result.responseModelId;

  ProviderMetadata? get providerMetadata => result.providerMetadata;

  List<ModelWarning> get warnings => result.warnings;
}

final class OutputResultEvent<T> extends OutputStreamEvent<T> {
  final GenerateOutputResult<T> result;

  const OutputResultEvent(this.result);
}

final class OutputErrorEvent<T> extends OutputStreamEvent<T> {
  final ModelError error;
  final StackTrace? stackTrace;

  const OutputErrorEvent(
    this.error, {
    this.stackTrace,
  });
}
