part of 'chat_ui_accumulator.dart';

extension _ChatUiAccumulatorOutputSupport on ChatUiAccumulator {
  void _applyReasoningFileEvent(ReasoningFileEvent event) {
    _appendPart(
      ReasoningFileUiPart(
        event.file,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void _applySourceEvent(SourceEvent event) {
    _appendPart(SourceUiPart(event.source));
  }

  void _applyFileEvent(FileEvent event) {
    _appendPart(
      FileUiPart(
        event.file,
        providerMetadata: event.providerMetadata,
      ),
    );
  }

  void _applyCustomEvent(CustomEvent event) {
    _appendPart(
      CustomUiPart(
        kind: event.kind,
        data: event.data,
        providerMetadata: event.providerMetadata,
      ),
    );
  }
}
