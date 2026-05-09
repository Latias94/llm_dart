part of 'chat_ui_accumulator.dart';

extension _ChatUiAccumulatorHydrationSupport on ChatUiAccumulator {
  void _hydrateIndexes() {
    _nextStepIndex = _parts.whereType<StepBoundaryUiPart>().length;

    for (var index = 0; index < _parts.length; index++) {
      final part = _parts[index];
      if (part is ToolUiPart) {
        _toolParts.hydrate(part, index);
        continue;
      }

      if (part case DataUiPart(:final id?, :final key)) {
        _hydrateDataPartIndex(key, id, index);
      }
    }
  }
}
