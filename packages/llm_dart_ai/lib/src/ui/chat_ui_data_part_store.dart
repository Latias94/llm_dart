import 'chat_ui_message.dart';

final class ChatUiDataPartStore {
  final List<ChatUiPart> _parts;
  final Map<String, int> _indexes = {};

  ChatUiDataPartStore(this._parts);

  void hydrate(DataUiPart<Object?> part, int index) {
    final id = part.id;
    if (id == null) {
      return;
    }

    _indexes[_identity(part.key, id)] = index;
  }

  void apply<T>(DataUiPart<T> part) {
    final id = part.id;
    if (id == null) {
      _appendPart(part);
      return;
    }

    final identity = _identity(part.key, id);
    final index = _indexes[identity];
    if (index == null) {
      _indexes[identity] = _appendPart(part);
    } else {
      _parts[index] = part;
    }
  }

  int _appendPart(ChatUiPart part) {
    _parts.add(part);
    return _parts.length - 1;
  }

  String _identity(String key, String id) => '$key\u0000$id';
}
