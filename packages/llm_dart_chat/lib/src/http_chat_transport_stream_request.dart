import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

TransportRequest buildHttpChatTransportStreamRequest({
  required Uri endpoint,
  required Map<String, String> headers,
  required Duration? requestTimeout,
  required int? maxRetries,
  required ProviderCancellation? cancellation,
  required Map<String, Object?> payload,
}) {
  return TransportRequest(
    uri: endpoint,
    method: TransportMethod.post,
    headers: {
      ...headers,
    },
    body: payload,
    timeout: requestTimeout,
    maxRetries: maxRetries,
    cancellation: bindProviderCancellationToTransport(cancellation),
    responseType: TransportResponseType.plainText,
  );
}
