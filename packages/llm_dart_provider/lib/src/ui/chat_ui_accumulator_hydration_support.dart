part of 'chat_ui_accumulator.dart';

extension _ChatUiAccumulatorHydrationSupport on ChatUiAccumulator {
  void _hydrateIndexes() {
    _nextStepIndex = _parts.whereType<StepBoundaryUiPart>().length;

    for (var index = 0; index < _parts.length; index++) {
      final part = _parts[index];
      if (part is ToolUiPart) {
        _hydrateToolPartIndex(part, index);
        continue;
      }

      if (part case DataUiPart(:final id?, :final key)) {
        _hydrateDataPartIndex(key, id, index);
      }
    }
  }

  void _hydrateToolPartIndex(ToolUiPart part, int index) {
    _toolPartIndexes[part.toolCallId] = index;
    if (part.state != ToolUiPartState.inputStreaming) {
      return;
    }

    _partialToolInputs[part.toolCallId] = _PartialToolInput(
      toolName: part.toolName,
      providerExecuted: part.providerExecuted,
      isDynamic: part.isDynamic,
      title: part.title,
      initialText: part.inputText ?? _stringifyValue(part.input) ?? '',
    );
  }
}
