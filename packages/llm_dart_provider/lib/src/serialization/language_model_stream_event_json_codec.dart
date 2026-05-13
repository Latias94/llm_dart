import '../common/json_codec_common.dart';
import '../stream/language_model_stream_event.dart';
import 'text_stream_event_json_codec.dart';

/// JSON codec for provider-owned language model stream events.
///
/// The wire shape intentionally stays compatible with
/// [TextStreamEventJsonCodec] while provider/runtime event ownership is being
/// split. This codec is stricter: it rejects runtime-only events so provider
/// contracts cannot accidentally serialize tool-loop orchestration state.
final class LanguageModelStreamEventJsonCodec {
  static const envelopeKind = TextStreamEventJsonCodec.envelopeKind;

  static const _textStreamCodec = TextStreamEventJsonCodec();

  const LanguageModelStreamEventJsonCodec();

  JsonMap encodeEvents(List<LanguageModelStreamEvent> events) {
    _validateEvents(
      events,
      operation: 'LanguageModelStreamEventJsonCodec.encodeEvents',
    );
    return _textStreamCodec.encodeEvents(events);
  }

  List<LanguageModelStreamEvent> decodeEvents(Object? envelope) {
    final events = _textStreamCodec.decodeEvents(envelope);
    _validateEvents(
      events,
      operation: 'LanguageModelStreamEventJsonCodec.decodeEvents',
    );
    return events;
  }

  JsonMap encodeEvent(LanguageModelStreamEvent event) {
    validateLanguageModelStreamEvent(
      event,
      context: 'LanguageModelStreamEventJsonCodec.encodeEvent',
    );
    return _textStreamCodec.encodeEvent(event);
  }

  LanguageModelStreamEvent decodeEvent(
    Object? value, {
    String path = r'$',
  }) {
    final event = _textStreamCodec.decodeEvent(value, path: path);
    validateLanguageModelStreamEvent(
      event,
      context: 'LanguageModelStreamEventJsonCodec.decodeEvent($path)',
    );
    return event;
  }

  void _validateEvents(
    Iterable<LanguageModelStreamEvent> events, {
    required String operation,
  }) {
    var index = 0;
    for (final event in events) {
      validateLanguageModelStreamEvent(
        event,
        context: '$operation event[$index]',
      );
      index += 1;
    }
  }
}
