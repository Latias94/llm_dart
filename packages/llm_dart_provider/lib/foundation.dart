/// Foundation provider-spec contracts.
///
/// This entrypoint intentionally contains only provider-facing primitives that
/// do not depend on transport, runtime orchestration, chat, Flutter, or
/// concrete provider implementations.
library;

export 'src/common/json_schema.dart';
export 'src/common/json_codec_common.dart';
export 'src/common/call_options.dart';
export 'src/common/model_error.dart';
export 'src/common/model_warning.dart';
export 'src/common/provider_cancellation.dart';
export 'src/common/provider_metadata.dart';
export 'src/common/provider_options.dart';
export 'src/common/provider_reference.dart';
export 'src/common/typed_part_parser.dart';
export 'src/common/usage_stats.dart';
export 'src/content/content_part.dart';
export 'src/content/file_data.dart';
export 'src/model/embedding_model.dart';
export 'src/model/finish_reason.dart';
export 'src/model/image_model.dart';
export 'src/model/language_model.dart';
export 'src/model/model_capability_profile.dart';
export 'src/model/model_registry.dart';
export 'src/model/model_response_metadata.dart';
export 'src/model/response_format.dart';
export 'src/model/speech_model.dart';
export 'src/model/transcription_model.dart';
export 'src/prompt/prompt_message.dart';
export 'src/serialization/prompt_json_codec.dart';
export 'src/serialization/serialization_json_support.dart';
export 'src/serialization/serialization_protocol.dart';
export 'src/serialization/text_stream_event_json_codec.dart';
export 'src/stream/language_model_stream_event.dart';
export 'src/stream/text_stream_event.dart';
export 'src/tool/tool_definition.dart';
export 'src/tool/tool_output.dart';
export 'src/tool/tool_output_projection.dart';
