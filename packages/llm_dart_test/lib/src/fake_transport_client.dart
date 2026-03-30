import 'package:llm_dart_transport/llm_dart_transport.dart';

/// Shared transport fake for workspace tests.
final class FakeTransportClient implements TransportClient {
  final Future<TransportResponse> Function(TransportRequest request)? onSend;
  final Future<StreamingTransportResponse> Function(TransportRequest request)?
      onSendStream;

  const FakeTransportClient({
    this.onSend,
    this.onSendStream,
  });

  @override
  Future<TransportResponse> send(TransportRequest request) {
    if (onSend == null) {
      throw UnimplementedError('send() was not configured for this test.');
    }

    return onSend!(request);
  }

  @override
  Future<StreamingTransportResponse> sendStream(TransportRequest request) {
    if (onSendStream == null) {
      throw UnimplementedError(
        'sendStream() was not configured for this test.',
      );
    }

    return onSendStream!(request);
  }
}
