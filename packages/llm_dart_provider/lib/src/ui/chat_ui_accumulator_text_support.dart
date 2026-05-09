part of 'chat_ui_accumulator.dart';

extension _ChatUiAccumulatorTextSupport on ChatUiAccumulator {
  void _applyTextStartEvent(TextStartEvent event) {
    _activeTextPartIndexes[event.id] = _appendPart(
      TextUiPart(
        text: '',
        isStreaming: true,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void _applyTextDeltaEvent(TextDeltaEvent event) {
    final index = _requireActivePartIndex(
      _activeTextPartIndexes,
      event.id,
      eventName: 'text-delta',
      startEventName: 'text-start',
      partName: 'text part',
    );
    final current = _parts[index] as TextUiPart;
    _parts[index] = TextUiPart(
      text: current.text + event.delta,
      isStreaming: true,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        event.providerMetadata,
      ),
    );
  }

  void _applyTextEndEvent(TextEndEvent event) {
    final index = _requireActivePartIndex(
      _activeTextPartIndexes,
      event.id,
      eventName: 'text-end',
      startEventName: 'text-start',
      partName: 'text part',
    );
    final current = _parts[index] as TextUiPart;
    _parts[index] = TextUiPart(
      text: current.text,
      isStreaming: false,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        event.providerMetadata,
      ),
    );
    _activeTextPartIndexes.remove(event.id);
  }

  void _applyReasoningStartEvent(ReasoningStartEvent event) {
    _activeReasoningPartIndexes[event.id] = _appendPart(
      ReasoningUiPart(
        text: '',
        isStreaming: true,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void _applyReasoningDeltaEvent(ReasoningDeltaEvent event) {
    final index = _requireActivePartIndex(
      _activeReasoningPartIndexes,
      event.id,
      eventName: 'reasoning-delta',
      startEventName: 'reasoning-start',
      partName: 'reasoning part',
    );
    final current = _parts[index] as ReasoningUiPart;
    _parts[index] = ReasoningUiPart(
      text: current.text + event.delta,
      isStreaming: true,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        event.providerMetadata,
      ),
    );
  }

  void _applyReasoningEndEvent(ReasoningEndEvent event) {
    final index = _requireActivePartIndex(
      _activeReasoningPartIndexes,
      event.id,
      eventName: 'reasoning-end',
      startEventName: 'reasoning-start',
      partName: 'reasoning part',
    );
    final current = _parts[index] as ReasoningUiPart;
    _parts[index] = ReasoningUiPart(
      text: current.text,
      isStreaming: false,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        event.providerMetadata,
      ),
    );
    _activeReasoningPartIndexes.remove(event.id);
  }

  void _applyStepStartEvent(StepStartEvent event) {
    final stepId = event.stepId ?? 'step-$_nextStepIndex';
    _nextStepIndex += 1;
    _appendPart(StepBoundaryUiPart(stepId));
  }

  void _applyStepFinishEvent() {
    _activeTextPartIndexes.clear();
    _activeReasoningPartIndexes.clear();
    _toolParts.clearStreamingInputs();
  }
}
