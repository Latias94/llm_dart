import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_model_settings.dart';
import 'elevenlabs_transcription_options.dart';

TransportRequest buildElevenLabsTranscriptionTransportRequest({
  required String baseUrl,
  required CallOptions callOptions,
  required TransportMultipartBody multipart,
  required String apiKey,
  required ElevenLabsTranscriptionModelSettings settings,
  required ElevenLabsTranscriptionOptions? options,
}) {
  return TransportRequest(
    uri: resolveElevenLabsTranscriptionUri(
      baseUrl: baseUrl,
      queryParameters: {
        if (options?.enableLogging case final enableLogging?)
          'enable_logging': '$enableLogging',
      },
    ),
    method: TransportMethod.post,
    headers: buildElevenLabsTranscriptionRequestHeaders(
      apiKey: apiKey,
      settings: settings,
      contentType: multipart.contentType,
      extraHeaders: callOptions.headers,
    ),
    body: multipart.bytes,
    timeout: callOptions.timeout,
    maxRetries: callOptions.maxRetries,
    cancellation: callOptions.cancellation,
    responseType: TransportResponseType.json,
  );
}

Map<String, String> buildElevenLabsTranscriptionDefaultHeaders({
  required String apiKey,
  required ElevenLabsTranscriptionModelSettings settings,
}) {
  return {
    'xi-api-key': apiKey,
    ...settings.headers,
  };
}

Map<String, String> buildElevenLabsTranscriptionRequestHeaders({
  required String apiKey,
  required ElevenLabsTranscriptionModelSettings settings,
  required String contentType,
  Map<String, String>? extraHeaders,
}) {
  return {
    ...buildElevenLabsTranscriptionDefaultHeaders(
      apiKey: apiKey,
      settings: settings,
    ),
    'content-type': contentType,
    'accept': 'application/json',
    if (extraHeaders != null) ...extraHeaders,
  };
}

Uri resolveElevenLabsTranscriptionUri({
  required String baseUrl,
  required Map<String, String> queryParameters,
}) {
  final uri = Uri.parse('$baseUrl/speech-to-text');
  return queryParameters.isEmpty
      ? uri
      : uri.replace(queryParameters: queryParameters);
}
