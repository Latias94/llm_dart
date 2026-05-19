import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';
import 'text_stream_tool_input_event_json_codec.dart';
import 'text_stream_tool_lifecycle_event_json_codec.dart';

final class TextStreamToolEventJsonCodec {
  static const Set<String> eventTypes = {
    ...TextStreamToolInputEventJsonCodec.eventTypes,
    ...TextStreamToolLifecycleEventJsonCodec.eventTypes,
  };

  const TextStreamToolEventJsonCodec();

  bool canDecode(String type) => eventTypes.contains(type);

  provider.JsonMap encode(TextStreamEvent event) {
    return switch (event) {
      ToolInputStartEvent() ||
      ToolInputDeltaEvent() ||
      ToolInputEndEvent() ||
      ToolInputErrorEvent() =>
        const TextStreamToolInputEventJsonCodec().encode(event),
      ToolCallEvent() ||
      ToolResultEvent() ||
      ToolApprovalRequestEvent() ||
      ToolOutputDeniedEvent() =>
        const TextStreamToolLifecycleEventJsonCodec().encode(event),
      _ => throw ArgumentError.value(
          event,
          'event',
          'Expected a tool text stream event.',
        ),
    };
  }

  TextStreamEvent decode(
    provider.JsonMap map, {
    required String type,
    required String path,
  }) {
    const inputCodec = TextStreamToolInputEventJsonCodec();
    if (inputCodec.canDecode(type)) {
      return inputCodec.decode(map, type: type, path: path);
    }
    const lifecycleCodec = TextStreamToolLifecycleEventJsonCodec();
    if (lifecycleCodec.canDecode(type)) {
      return lifecycleCodec.decode(map, type: type, path: path);
    }

    throw FormatException(
      'Unsupported tool text stream event type "$type" at $path.',
    );
  }
}
