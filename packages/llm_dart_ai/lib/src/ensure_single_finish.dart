import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Ensures there is at most one [LLMFinishPart] and that it is the last part.
///
/// Some providers (or adapters) may emit finish-like metadata multiple times.
/// AI SDK v3 treats `finish` as "metadata available after the stream is
/// finished", i.e. it should be terminal.
///
/// Behavior:
/// - Any upstream [LLMFinishPart] is buffered (not emitted immediately).
/// - The last seen finish part (if any) is emitted once, after upstream ends.
Stream<LLMStreamPart> ensureSingleFinishPart(
  Stream<LLMStreamPart> upstream,
) async* {
  LLMFinishPart? buffered;

  final iterator = StreamIterator(upstream);
  try {
    while (await iterator.moveNext()) {
      final part = iterator.current;
      if (part is LLMFinishPart) {
        buffered = part;
      } else {
        yield part;
      }
    }
  } finally {
    await iterator.cancel();
  }

  if (buffered != null) {
    yield buffered;
  }
}
