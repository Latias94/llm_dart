import '../stream/text_stream_event.dart';
import 'generate_text_run_result.dart';
import 'generate_text_runner_support.dart';
import 'stream_result_foundation.dart';

final class StreamTextEventEmitter {
  final StreamResultController<TextStreamEvent, GenerateTextRunResult>
      streamResult;
  final StreamTextOnChunk? onChunk;

  StreamTextEventEmitter({
    required this.streamResult,
    required this.onChunk,
  });

  Future<void> add(TextStreamEvent event) async {
    streamResult.addEvent(event);
    await onChunk?.call(event);
  }
}
