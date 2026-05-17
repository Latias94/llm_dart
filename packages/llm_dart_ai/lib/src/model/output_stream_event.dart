import '../stream/text_stream_event.dart';
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

final class OutputResultEvent<T> extends OutputStreamEvent<T> {
  final GenerateOutputResult<T> result;

  const OutputResultEvent(this.result);
}
