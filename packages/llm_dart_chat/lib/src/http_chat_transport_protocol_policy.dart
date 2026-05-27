import 'http_chat_transport_stream_protocol.dart';

/// Release-frozen HTTP chat transport protocol policy.
///
/// This Module owns version posture only. Chunk projection, replay mutation,
/// SSE framing, and stream error handling stay in their existing transport
/// Modules.
final class HttpChatTransportProtocolPolicy {
  static const defaultStreamProtocol =
      HttpChatTransportStreamProtocol.uiMessageStreamV2;

  static const legacyRequestFallbackStreamProtocol =
      HttpChatTransportStreamProtocol.eventStreamV1;

  static const supportedStreamProtocols = [
    HttpChatTransportStreamProtocol.eventStreamV1,
    HttpChatTransportStreamProtocol.uiMessageStreamV2,
  ];

  const HttpChatTransportProtocolPolicy._();
}
