import '../stream/text_stream_event.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

typedef JsonOutputDecoder<T> = T Function(Object? json);
typedef JsonObjectDecoder<T> = T Function(Map<String, Object?> json);
typedef JsonArrayElementDecoder<T> = T Function(Object? json);

final class StructuredOutputContext {
  final String? responseId;
  final DateTime? responseTimestamp;
  final String? responseModelId;
  final FinishReason finishReason;
  final String? rawFinishReason;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;

  const StructuredOutputContext({
    this.responseId,
    this.responseTimestamp,
    this.responseModelId,
    required this.finishReason,
    this.rawFinishReason,
    this.usage,
    this.providerMetadata,
  });
}

final class GenerateOutputResult<T> {
  final GenerateTextResult result;
  final T output;

  const GenerateOutputResult({
    required this.result,
    required this.output,
  });

  String get text => result.text;

  String? get reasoningText => result.reasoningText;

  FinishReason get finishReason => result.finishReason;

  String? get rawFinishReason => result.rawFinishReason;

  String? get responseId => result.responseId;

  DateTime? get responseTimestamp => result.responseTimestamp;

  String? get responseModelId => result.responseModelId;

  UsageStats? get usage => result.usage;

  ProviderMetadata? get providerMetadata => result.providerMetadata;
}

typedef GenerateObjectResult<T> = GenerateOutputResult<T>;

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

final class OutputResultEvent<T> extends OutputStreamEvent<T> {
  final GenerateOutputResult<T> result;

  const OutputResultEvent(this.result);
}
