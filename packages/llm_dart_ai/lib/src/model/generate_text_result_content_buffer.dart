import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GenerateTextResultContentBuffer {
  final List<ContentPart> _content = <ContentPart>[];
  final Map<String, int> _activeTextPartIndexes = <String, int>{};
  final Map<String, int> _activeReasoningPartIndexes = <String, int>{};
  final Map<String, int> _toolCallPartIndexes = <String, int>{};

  List<ContentPart> get content => _content;

  String get text =>
      _content.whereType<TextContentPart>().map((part) => part.text).join();

  void startTextPart({
    required String id,
    required ProviderMetadata? providerMetadata,
  }) {
    _activeTextPartIndexes[id] = _appendPart(
      TextContentPart(
        '',
        providerMetadata: providerMetadata,
      ),
    );
  }

  void appendTextDelta({
    required String id,
    required String delta,
    required ProviderMetadata? providerMetadata,
  }) {
    final index = _requireActivePartIndex(
      _activeTextPartIndexes,
      id,
      eventName: 'text-delta',
      startEventName: 'text-start',
      partName: 'text part',
    );
    final current = _content[index] as TextContentPart;
    _content[index] = TextContentPart(
      current.text + delta,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        providerMetadata,
      ),
    );
  }

  void endTextPart({
    required String id,
    required ProviderMetadata? providerMetadata,
  }) {
    final index = _requireActivePartIndex(
      _activeTextPartIndexes,
      id,
      eventName: 'text-end',
      startEventName: 'text-start',
      partName: 'text part',
    );
    final current = _content[index] as TextContentPart;
    _content[index] = TextContentPart(
      current.text,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        providerMetadata,
      ),
    );
    _activeTextPartIndexes.remove(id);
  }

  void startReasoningPart({
    required String id,
    required ProviderMetadata? providerMetadata,
  }) {
    _activeReasoningPartIndexes[id] = _appendPart(
      ReasoningContentPart(
        '',
        providerMetadata: providerMetadata,
      ),
    );
  }

  void appendReasoningDelta({
    required String id,
    required String delta,
    required ProviderMetadata? providerMetadata,
  }) {
    final index = _requireActivePartIndex(
      _activeReasoningPartIndexes,
      id,
      eventName: 'reasoning-delta',
      startEventName: 'reasoning-start',
      partName: 'reasoning part',
    );
    final current = _content[index] as ReasoningContentPart;
    _content[index] = ReasoningContentPart(
      current.text + delta,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        providerMetadata,
      ),
    );
  }

  void endReasoningPart({
    required String id,
    required ProviderMetadata? providerMetadata,
  }) {
    final index = _requireActivePartIndex(
      _activeReasoningPartIndexes,
      id,
      eventName: 'reasoning-end',
      startEventName: 'reasoning-start',
      partName: 'reasoning part',
    );
    final current = _content[index] as ReasoningContentPart;
    _content[index] = ReasoningContentPart(
      current.text,
      providerMetadata: ProviderMetadata.mergeNullable(
        current.providerMetadata,
        providerMetadata,
      ),
    );
    _activeReasoningPartIndexes.remove(id);
  }

  void appendReasoningFile({
    required GeneratedFile file,
    required ProviderMetadata? providerMetadata,
  }) {
    _appendPart(
      ReasoningFileContentPart(
        file,
        providerMetadata: providerMetadata,
      ),
    );
  }

  void appendToolResultPart(ToolResultContentPart part) {
    _appendPart(part);
  }

  void appendToolApprovalRequestPart(ToolApprovalRequestContentPart part) {
    _appendPart(part);
  }

  ToolCallContentPart? toolCallPart(String toolCallId) {
    final index = _toolCallPartIndexes[toolCallId];
    if (index == null) {
      return null;
    }

    return _content[index] as ToolCallContentPart;
  }

  ToolCallContentPart requireToolCallPart(String toolCallId) {
    final value = toolCallPart(toolCallId);
    if (value != null) {
      return value;
    }

    throw StateError(
      'Received tool-output-denied for missing tool call with ID "$toolCallId". '
      'Ensure a tool-call or completed tool-input event is applied first.',
    );
  }

  void upsertToolCallPart(ToolCallContentPart part) {
    final index = _toolCallPartIndexes[part.toolCall.toolCallId];
    if (index == null) {
      _toolCallPartIndexes[part.toolCall.toolCallId] = _appendPart(part);
      return;
    }

    _content[index] = part;
  }

  void appendSource(SourceReference source) {
    _appendPart(SourceContentPart(source));
  }

  void appendFile({
    required GeneratedFile file,
    required ProviderMetadata? providerMetadata,
  }) {
    _appendPart(
      FileContentPart(
        file,
        providerMetadata: providerMetadata,
      ),
    );
  }

  void appendCustom({
    required String kind,
    required Object? data,
    required ProviderMetadata? providerMetadata,
  }) {
    _appendPart(
      CustomContentPart(
        kind: kind,
        data: data,
        providerMetadata: providerMetadata,
      ),
    );
  }

  int _appendPart(ContentPart part) {
    _content.add(part);
    return _content.length - 1;
  }
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

  throw StateError(
    'Received $eventName for missing $partName with ID "$id". '
    'Ensure a "$startEventName" event is applied first.',
  );
}
