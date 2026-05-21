import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

typedef GoogleModelResponseDecoder<T> = T Function(
  Object? body,
  Map<String, String> headers,
);

Future<T> sendGoogleModelRequest<T>({
  required TransportClient transport,
  required TransportRequest request,
  required GoogleModelResponseDecoder<T> decode,
}) {
  return sendProviderModelRequest(
    transport: transport,
    request: request,
    decode: decode,
  );
}
