import '../stream/text_stream_event.dart';
import 'output_spec_foundation.dart';
import 'output_spec_json.dart';
import 'output_spec_strategy.dart';

final class OutputStreamProjection<T> {
  final OutputSpec<T> outputSpec;

  Object? _lastPartialOutput;
  var _hasPartialOutput = false;

  OutputStreamProjection({
    required this.outputSpec,
  });

  Future<List<OutputStreamEvent<T>>> project(
    TextStreamEvent event, {
    required String text,
  }) async {
    if (event is! TextDeltaEvent && event is! TextEndEvent) {
      return const [];
    }

    final partialOutput = await tryParsePartialOutput(
      outputSpec: outputSpec,
      text: text,
    );

    if (partialOutput == null ||
        (_hasPartialOutput &&
            structuredOutputValueEquals(
              _lastPartialOutput,
              partialOutput,
            ))) {
      return const [];
    }

    final previousPartialOutput = _lastPartialOutput;
    _hasPartialOutput = true;
    _lastPartialOutput = partialOutput;

    return [
      OutputPartialEvent<T>(partialOutput),
      ...outputSpec.createElementEvents(
        partialOutput: partialOutput,
        previousPartialOutput: previousPartialOutput,
      ),
    ];
  }
}

Future<Object?> tryParsePartialOutput<T>({
  required OutputSpec<T> outputSpec,
  required String text,
}) async {
  try {
    return await outputSpec.parsePartial(text: text);
  } catch (_) {
    return null;
  }
}
