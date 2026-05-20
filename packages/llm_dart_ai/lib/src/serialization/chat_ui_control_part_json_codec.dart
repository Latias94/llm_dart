import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../ui/chat_ui_message.dart';

final class ChatUiControlPartJsonCodec {
  static const Set<String> partTypes = {
    'step-boundary',
    'data',
  };

  const ChatUiControlPartJsonCodec();

  bool canDecode(String type) => partTypes.contains(type);

  JsonMap encode(ChatUiPart part) {
    return switch (part) {
      StepBoundaryUiPart(:final stepId) => {
          'type': 'step-boundary',
          'stepId': stepId,
        },
      DataUiPart(:final id, :final key, :final data) => {
          'type': 'data',
          if (id != null) 'id': id,
          'key': key,
          'data': ensureJsonValue(data, path: r'$.dataPart.data'),
        },
      _ => throw ArgumentError.value(
          part,
          'part',
          'Expected a step boundary or data chat UI part.',
        ),
    };
  }

  ChatUiPart decode(
    JsonMap map, {
    required String type,
    required String path,
  }) {
    return switch (type) {
      'step-boundary' => StepBoundaryUiPart(
          asJsonString(map['stepId'], path: '$path.stepId'),
        ),
      'data' => DataUiPart<Object?>(
          id: asNullableJsonString(map['id'], path: '$path.id'),
          key: asJsonString(map['key'], path: '$path.key'),
          data: map['data'],
        ),
      _ => throw FormatException(
          'Unsupported control chat UI part type "$type" at $path.',
        ),
    };
  }
}
