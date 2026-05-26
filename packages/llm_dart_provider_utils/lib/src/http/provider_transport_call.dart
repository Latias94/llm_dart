import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../common/provider_transport_cancellation.dart';
import '../common/transport_model_error.dart';

typedef ProviderModelResponseDecoder<T> = T Function(
  Object? body,
  Map<String, String> headers,
);

typedef ProviderLanguageModelStreamDecoder = Stream<LanguageModelStreamEvent>
    Function({
  required Stream<List<int>> stream,
  required bool includeRawChunks,
});

final class ProviderCallKit {
  final TransportClient transport;

  const ProviderCallKit({
    required this.transport,
  });

  Future<T> sendModelRequest<T>({
    required TransportRequest request,
    required ProviderModelResponseDecoder<T> decode,
  }) {
    return sendProviderModelRequest(
      transport: transport,
      request: request,
      decode: decode,
    );
  }

  Stream<LanguageModelStreamEvent> sendLanguageModelStreamRequest({
    required TransportRequest request,
    required List<ModelWarning> warnings,
    required bool includeRawChunks,
    required ProviderLanguageModelStreamDecoder decode,
  }) {
    return sendProviderLanguageModelStreamRequest(
      transport: transport,
      request: request,
      warnings: warnings,
      includeRawChunks: includeRawChunks,
      decode: decode,
    );
  }
}

Future<T> sendProviderModelRequest<T>({
  required TransportClient transport,
  required TransportRequest request,
  required ProviderModelResponseDecoder<T> decode,
}) async {
  try {
    final response = await transport.send(request);
    return decode(response.body, response.headers);
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(
      normalizeTransportCancellation(error, request.cancellation?.source),
      stackTrace,
    );
  }
}

Stream<LanguageModelStreamEvent> sendProviderLanguageModelStreamRequest({
  required TransportClient transport,
  required TransportRequest request,
  required List<ModelWarning> warnings,
  required bool includeRawChunks,
  required ProviderLanguageModelStreamDecoder decode,
}) async* {
  yield StartEvent(warnings: warnings);

  try {
    final response = await transport.sendStream(request);
    yield* decode(
      stream: response.stream,
      includeRawChunks: includeRawChunks,
    );
  } catch (error) {
    final normalizedError = normalizeTransportCancellation(
      error,
      request.cancellation?.source,
    );
    yield ErrorEvent(transportErrorToModelError(normalizedError));
  }
}
