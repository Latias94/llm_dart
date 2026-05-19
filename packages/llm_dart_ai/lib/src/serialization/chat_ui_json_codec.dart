import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../ui/chat_ui_message.dart';
import 'chat_ui_metadata_json_codec.dart';
import 'chat_ui_part_json_codec.dart';

final class ChatUiJsonCodec {
  static const envelopeKind = 'chat-ui-messages';

  const ChatUiJsonCodec();

  JsonMap encodeMessages(List<ChatUiMessage> messages) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'messages': messages.map(encodeMessage).toList(growable: false),
      },
    };
  }

  List<ChatUiMessage> decodeMessages(Object? envelope) {
    final root = asJsonMap(envelope, path: r'$');
    final kind = asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = asJsonMap(root['data'], path: r'$.data');
    return asJsonList(data['messages'], path: r'$.data.messages')
        .asMap()
        .entries
        .map(
          (entry) => decodeMessage(
            entry.value,
            path: '\$.data.messages[${entry.key}]',
          ),
        )
        .toList(growable: false);
  }

  JsonMap encodeMessage(ChatUiMessage message) {
    return {
      'id': message.id,
      'role': message.role.name,
      'parts': message.parts.map(encodePart).toList(growable: false),
      'metadata': const ChatUiMetadataJsonCodec().encode(message.metadata),
    };
  }

  ChatUiMessage decodeMessage(
    Object? value, {
    String path = r'$',
  }) {
    final map = asJsonMap(value, path: path);
    final role = ChatUiRole.values.byName(
      asJsonString(map['role'], path: '$path.role'),
    );
    final parts = asJsonList(map['parts'], path: '$path.parts')
        .asMap()
        .entries
        .map((entry) =>
            decodePart(entry.value, path: '$path.parts[${entry.key}]'))
        .toList(growable: false);

    return ChatUiMessage(
      id: asJsonString(map['id'], path: '$path.id'),
      role: role,
      parts: parts,
      metadata: const ChatUiMetadataJsonCodec().decode(
        map['metadata'],
        path: '$path.metadata',
      ),
    );
  }

  JsonMap encodePart(ChatUiPart part) {
    return const ChatUiPartJsonCodec().encode(part);
  }

  ChatUiPart decodePart(
    Object? value, {
    String path = r'$',
  }) {
    return const ChatUiPartJsonCodec().decode(value, path: path);
  }
}
