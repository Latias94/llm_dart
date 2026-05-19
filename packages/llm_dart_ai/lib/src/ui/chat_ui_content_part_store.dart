import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide
        ReasoningDeltaEvent,
        ReasoningEndEvent,
        ReasoningStartEvent,
        TextDeltaEvent,
        TextEndEvent,
        TextStartEvent;

import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_error.dart';

final class ChatUiContentPartStore {
  final List<ChatUiPart> _parts;
  final Map<String, int> _activeTextPartIndexes = {};
  final Map<String, int> _activeReasoningPartIndexes = {};

  ChatUiContentPartStore(this._parts);

  void applyTextStart(TextStartEvent event) {
    _activeTextPartIndexes[event.id] = _appendPart(
      TextUiPart(
        text: '',
        isStreaming: true,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void applyTextDelta(TextDeltaEvent event) {
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

  void applyTextEnd(TextEndEvent event) {
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

  void applyReasoningStart(ReasoningStartEvent event) {
    _activeReasoningPartIndexes[event.id] = _appendPart(
      ReasoningUiPart(
        text: '',
        isStreaming: true,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void applyReasoningDelta(ReasoningDeltaEvent event) {
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

  void applyReasoningEnd(ReasoningEndEvent event) {
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

  void clearStreamingParts() {
    _activeTextPartIndexes.clear();
    _activeReasoningPartIndexes.clear();
  }

  int _appendPart(ChatUiPart part) {
    _parts.add(part);
    return _parts.length - 1;
  }

  int _requireActivePartIndex(
    Map<String, int> activeParts,
    String id, {
    required String eventName,
    required String startEventName,
    required String partName,
  }) {
    final index = activeParts[id];
    if (index != null) {
      return index;
    }

    throw ChatUiStreamError(
      chunkType: eventName,
      chunkId: id,
      message: 'Received $eventName for missing $partName with ID "$id". '
          'Ensure a "$startEventName" event is applied first.',
    );
  }
}
