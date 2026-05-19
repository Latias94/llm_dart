import '../common/json_codec_common.dart';
import '../stream/language_model_stream_event.dart';
import 'language_model_stream_tool_input_event_json_codec.dart';
import 'language_model_stream_tool_lifecycle_event_json_codec.dart';

final class LanguageModelStreamToolEventJsonCodec {
  static const Set<String> eventTypes = {
    ...LanguageModelStreamToolInputEventJsonCodec.eventTypes,
    ...LanguageModelStreamToolLifecycleEventJsonCodec.eventTypes,
  };

  const LanguageModelStreamToolEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  JsonMap encode(LanguageModelStreamEvent event) {
    return switch (event) {
      ToolInputStartEvent() ||
      ToolInputDeltaEvent() ||
      ToolInputEndEvent() ||
      ToolInputErrorEvent() =>
        const LanguageModelStreamToolInputEventJsonCodec().encode(event),
      ToolCallEvent() ||
      ToolResultEvent() ||
      ToolApprovalRequestEvent() =>
        const LanguageModelStreamToolLifecycleEventJsonCodec().encode(event),
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a provider tool stream event.',
        ),
    };
  }

  LanguageModelStreamEvent decode(
    JsonMap map, {
    required String type,
    required String path,
  }) {
    const inputCodec = LanguageModelStreamToolInputEventJsonCodec();
    if (inputCodec.canDecode(type)) {
      return inputCodec.decode(map, type: type, path: path);
    }
    const lifecycleCodec = LanguageModelStreamToolLifecycleEventJsonCodec();
    if (lifecycleCodec.canDecode(type)) {
      return lifecycleCodec.decode(map, type: type, path: path);
    }

    throw FormatException(
      'Unsupported provider tool stream event type "$type" at $path.',
    );
  }
}
