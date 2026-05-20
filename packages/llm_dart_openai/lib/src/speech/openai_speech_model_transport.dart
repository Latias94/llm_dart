import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../provider/openai_family_profile.dart';
import '../provider/openai_model_settings.dart';
import '../common/openai_non_text_model_support.dart';

Uri resolveOpenAISpeechUri({
  required String baseUrl,
}) {
  return Uri.parse('$baseUrl/audio/speech');
}

Map<String, String> buildOpenAISpeechDefaultHeaders({
  required OpenAIFamilyProfile profile,
  required String apiKey,
  required OpenAISpeechModelSettings settings,
}) {
  return buildOpenAIFamilyDefaultHeaders(
    profile: profile,
    apiKey: apiKey,
    organization: settings.organization,
    project: settings.project,
    headers: settings.headers,
  );
}

TransportRequest buildOpenAISpeechTransportRequest({
  required String baseUrl,
  required CallOptions callOptions,
  required Map<String, Object?> body,
  required Map<String, String> defaultHeaders,
}) {
  return TransportRequest(
    uri: resolveOpenAISpeechUri(baseUrl: baseUrl),
    method: TransportMethod.post,
    headers: {
      ...defaultHeaders,
      'content-type': 'application/json',
      'accept': 'application/octet-stream',
      if (callOptions.headers case final headers?) ...headers,
    },
    body: body,
    timeout: callOptions.timeout,
    maxRetries: callOptions.maxRetries,
    cancellation: bindProviderCancellationToTransport(
      callOptions.cancellation,
    ),
    responseType: TransportResponseType.bytes,
  );
}
