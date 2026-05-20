import 'package:llm_dart_transport/llm_dart_transport.dart';

typedef AnthropicModelResponseDecoder<T> = T Function(
  Object? body,
  Map<String, String> headers,
);

Future<T> sendAnthropicModelRequest<T>({
  required TransportClient transport,
  required TransportRequest request,
  required AnthropicModelResponseDecoder<T> decode,
}) async {
  final response = await transport.send(request);
  return decode(response.body, response.headers);
}
