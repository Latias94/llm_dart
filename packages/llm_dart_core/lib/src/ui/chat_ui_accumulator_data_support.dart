part of 'chat_ui_accumulator.dart';

extension _ChatUiAccumulatorDataSupport on ChatUiAccumulator {
  ChatUiMessage _applyDataPart<T>(DataUiPart<T> part) {
    final dataPartId = part.id;
    if (dataPartId == null) {
      _appendPart(part);
      return message;
    }

    final identity = _dataPartIdentity(part.key, dataPartId);
    final index = _dataPartIndexes[identity];
    if (index == null) {
      _dataPartIndexes[identity] = _appendPart(part);
    } else {
      _parts[index] = part;
    }

    return message;
  }

  void _hydrateDataPartIndex(String key, String id, int index) {
    _dataPartIndexes[_dataPartIdentity(key, id)] = index;
  }
}

String _dataPartIdentity(String key, String id) => '$key\u0000$id';
