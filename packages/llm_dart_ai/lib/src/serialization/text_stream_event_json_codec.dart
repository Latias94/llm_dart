import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

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

  provider.JsonMap encodeEvents(List<provider.TextStreamEvent> events) {
    return _legacyCodec.encodeEvents(events);
  }

  List<provider.TextStreamEvent> decodeEvents(Object? envelope) {
    return _legacyCodec.decodeEvents(envelope);
  }

  provider.JsonMap encodeEvent(provider.TextStreamEvent event) {
    return _legacyCodec.encodeEvent(event);
  }

  provider.TextStreamEvent decodeEvent(
    Object? value, {
    String path = r'$',
  }) {
    return _legacyCodec.decodeEvent(value, path: path);
  }
}
