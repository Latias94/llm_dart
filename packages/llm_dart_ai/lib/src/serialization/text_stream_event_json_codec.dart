import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

import '../stream/text_stream_event.dart';
import '../stream/text_stream_event_provider_bridge.dart';

/// JSON codec for AI runtime full-stream events.
///
/// This is an ownership shim while full-stream event classes are being moved
/// out of provider contracts. The wire shape remains compatible with the
/// legacy provider codec, but app-facing imports should resolve this name from
/// `llm_dart_ai`.
final class TextStreamEventJsonCodec {
  static const envelopeKind = provider.TextStreamEventJsonCodec.envelopeKind;

  static const _legacyCodec = provider.TextStreamEventJsonCodec();

  const TextStreamEventJsonCodec();

  provider.JsonMap encodeEvents(List<TextStreamEvent> events) {
    return _legacyCodec.encodeEvents(
      events.map(textStreamEventToProvider).toList(growable: false),
    );
  }

  List<TextStreamEvent> decodeEvents(Object? envelope) {
    return _legacyCodec
        .decodeEvents(envelope)
        .map(textStreamEventFromProvider)
        .toList(growable: false);
  }

  provider.JsonMap encodeEvent(TextStreamEvent event) {
    return _legacyCodec.encodeEvent(textStreamEventToProvider(event));
  }

  TextStreamEvent decodeEvent(
    Object? value, {
    String path = r'$',
  }) {
    return textStreamEventFromProvider(
      _legacyCodec.decodeEvent(value, path: path),
    );
  }
}
