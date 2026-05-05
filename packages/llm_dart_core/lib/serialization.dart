/// Shared JSON serialization codecs for prompt, stream, and UI contracts.
///
/// This entrypoint is self-contained for transport/session protocols that need
/// to encode or decode the shared core data structures.
library;

export 'foundation.dart';

export 'src/model/finish_reason.dart' show FinishReason;
export 'src/model/language_model.dart' show GenerateTextOptions;
export 'src/serialization/chat_ui_json_codec.dart';
export 'src/serialization/prompt_json_codec.dart';
export 'src/serialization/serialization_protocol.dart';
export 'src/serialization/text_stream_event_json_codec.dart';
export 'src/stream/text_stream_event.dart';
export 'src/ui/chat_ui_message.dart';
export 'src/ui/chat_ui_stream_chunk.dart';
