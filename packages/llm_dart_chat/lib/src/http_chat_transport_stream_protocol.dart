enum HttpChatTransportStreamProtocol {
  eventStreamV1('event-stream-v1'),
  uiMessageStreamV2('ui-message-stream-v2');

  final String wireValue;

  const HttpChatTransportStreamProtocol(this.wireValue);

  static HttpChatTransportStreamProtocol decode(
    String value, {
    required String path,
  }) {
    for (final protocol in values) {
      if (protocol.wireValue == value) {
        return protocol;
      }
    }

    throw FormatException(
      'Unsupported HTTP chat transport stream protocol "$value" at $path.',
    );
  }
}
