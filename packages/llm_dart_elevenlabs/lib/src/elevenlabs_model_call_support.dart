import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

typedef ElevenLabsModelResponseDecoder<T> = T Function(
  Object? body,
  Map<String, String> headers,
);

Future<T> sendElevenLabsModelRequest<T>({
  required TransportClient transport,
  required TransportRequest request,
  required ElevenLabsModelResponseDecoder<T> decode,
}) {
  return sendProviderModelRequest(
    transport: transport,
    request: request,
    decode: decode,
  );
}
