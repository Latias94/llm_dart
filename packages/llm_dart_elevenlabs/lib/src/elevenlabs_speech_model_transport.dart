import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_options.dart';

TransportRequest buildElevenLabsSpeechTransportRequest({
  required String baseUrl,
  required String voiceId,
  required String outputFormat,
  required CallOptions callOptions,
  required Object? body,
  required String apiKey,
  required ElevenLabsSpeechModelSettings settings,
  required ElevenLabsSpeechOptions? options,
}) {
  return TransportRequest(
    uri: resolveElevenLabsSpeechUri(
      baseUrl: baseUrl,
      voiceId: voiceId,
      queryParameters: {
        'output_format': outputFormat,
        if (options?.enableLogging case final enableLogging?)
          'enable_logging': '$enableLogging',
        if (options?.optimizeStreamingLatency case final latency?)
          'optimize_streaming_latency': '$latency',
      },
    ),
    method: TransportMethod.post,
    headers: buildElevenLabsSpeechRequestHeaders(
      apiKey: apiKey,
      settings: settings,
      extraHeaders: callOptions.headers,
    ),
    body: body,
    timeout: callOptions.timeout,
    maxRetries: callOptions.maxRetries,
    cancellation: callOptions.cancellation,
    responseType: TransportResponseType.bytes,
  );
}

Map<String, String> buildElevenLabsSpeechDefaultHeaders({
  required String apiKey,
  required ElevenLabsSpeechModelSettings settings,
}) {
  return {
    'xi-api-key': apiKey,
    ...settings.headers,
  };
}

Map<String, String> buildElevenLabsSpeechRequestHeaders({
  required String apiKey,
  required ElevenLabsSpeechModelSettings settings,
  Map<String, String>? extraHeaders,
}) {
  return {
    ...buildElevenLabsSpeechDefaultHeaders(
      apiKey: apiKey,
      settings: settings,
    ),
    'content-type': 'application/json',
    'accept': 'application/octet-stream',
    if (extraHeaders != null) ...extraHeaders,
  };
}

Uri resolveElevenLabsSpeechUri({
  required String baseUrl,
  required String voiceId,
  required Map<String, String> queryParameters,
}) {
  final uri = Uri.parse('$baseUrl/text-to-speech/$voiceId');
  return queryParameters.isEmpty
      ? uri
      : uri.replace(queryParameters: queryParameters);
}
