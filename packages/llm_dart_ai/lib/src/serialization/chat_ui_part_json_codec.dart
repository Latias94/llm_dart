import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../ui/chat_ui_message.dart';
import 'chat_ui_artifact_part_json_codec.dart';
import 'chat_ui_control_part_json_codec.dart';
import 'chat_ui_text_part_json_codec.dart';
import 'chat_ui_tool_part_json_codec.dart';

final class ChatUiPartJsonCodec {
  const ChatUiPartJsonCodec();

  JsonMap encode(ChatUiPart part) {
    return switch (part) {
      TextUiPart() ||
      ReasoningUiPart() =>
        const ChatUiTextPartJsonCodec().encode(part),
      ToolUiPart() => const ChatUiToolPartJsonCodec().encode(part),
      SourceUiPart() ||
      FileUiPart() ||
      ReasoningFileUiPart() ||
      CustomUiPart() =>
        const ChatUiArtifactPartJsonCodec().encode(part),
      StepBoundaryUiPart() ||
      DataUiPart() =>
        const ChatUiControlPartJsonCodec().encode(part),
    };
  }

  ChatUiPart decode(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final type = asJsonString(map['type'], path: '$path.type');

    const textPartCodec = ChatUiTextPartJsonCodec();
    if (textPartCodec.canDecode(type)) {
      return textPartCodec.decode(map, type: type, path: path);
    }

    if (type == 'tool') {
      return const ChatUiToolPartJsonCodec().decode(map, path: path);
    }

    const artifactPartCodec = ChatUiArtifactPartJsonCodec();
    if (artifactPartCodec.canDecode(type)) {
      return artifactPartCodec.decode(map, type: type, path: path);
    }

    const controlPartCodec = ChatUiControlPartJsonCodec();
    if (controlPartCodec.canDecode(type)) {
      return controlPartCodec.decode(map, type: type, path: path);
    }

    throw FormatException('Unsupported chat UI part type "$type" at $path.');
  }
}
