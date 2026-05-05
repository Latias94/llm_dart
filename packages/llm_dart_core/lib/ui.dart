/// Shared UI message, chunk, projection, and accumulator APIs.
///
/// This entrypoint is self-contained for CLI, server-rendered UI, chat runtime,
/// and Flutter adapter layers that need provider-neutral UI projection.
library;

export 'foundation.dart';

export 'src/model/finish_reason.dart' show FinishReason;
export 'src/stream/text_stream_event.dart';
export 'src/ui/chat_message_mapper.dart';
export 'src/ui/chat_ui_accumulator.dart';
export 'src/ui/chat_ui_message.dart';
export 'src/ui/chat_ui_stream_accumulator.dart';
export 'src/ui/chat_ui_stream_chunk.dart';
export 'src/ui/chat_ui_stream_projection.dart';
