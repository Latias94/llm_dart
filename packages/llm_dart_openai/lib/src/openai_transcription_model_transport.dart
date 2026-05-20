import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_model_settings.dart';
import 'openai_non_text_model_support.dart';
import 'openai_transcription_options.dart';

Uri resolveOpenAITranscriptionUri({
  required String baseUrl,
}) {
  return Uri.parse('$baseUrl/audio/transcriptions');
}

Map<String, String> buildOpenAITranscriptionDefaultHeaders({
  required OpenAIFamilyProfile profile,
  required String apiKey,
  required OpenAITranscriptionModelSettings settings,
}) {
  return buildOpenAIFamilyDefaultHeaders(
    profile: profile,
    apiKey: apiKey,
    organization: settings.organization,
    project: settings.project,
    headers: settings.headers,
  );
}

TransportRequest buildOpenAITranscriptionTransportRequest({
  required String baseUrl,
  required CallOptions callOptions,
  required TransportMultipartBody multipart,
  required Map<String, String> defaultHeaders,
  required OpenAITranscriptionResponseFormat responseFormat,
}) {
  return TransportRequest(
    uri: resolveOpenAITranscriptionUri(baseUrl: baseUrl),
    method: TransportMethod.post,
    headers: {
      ...defaultHeaders,
      'content-type': multipart.contentType,
      'accept': acceptForOpenAITranscriptionResponseFormat(responseFormat),
      if (callOptions.headers case final headers?) ...headers,
    },
    body: multipart.bytes,
    timeout: callOptions.timeout,
    maxRetries: callOptions.maxRetries,
    cancellation: bindProviderCancellationToTransport(
      callOptions.cancellation,
    ),
    responseType: responseTypeForOpenAITranscriptionResponseFormat(
      responseFormat,
    ),
  );
}

String acceptForOpenAITranscriptionResponseFormat(
  OpenAITranscriptionResponseFormat responseFormat,
) {
  return switch (responseFormat) {
    OpenAITranscriptionResponseFormat.json ||
    OpenAITranscriptionResponseFormat.verboseJson =>
      'application/json',
    OpenAITranscriptionResponseFormat.srt => 'text/plain',
    OpenAITranscriptionResponseFormat.text => 'text/plain',
    OpenAITranscriptionResponseFormat.vtt => 'text/vtt',
  };
}

TransportResponseType responseTypeForOpenAITranscriptionResponseFormat(
  OpenAITranscriptionResponseFormat responseFormat,
) {
  return switch (responseFormat) {
    OpenAITranscriptionResponseFormat.json ||
    OpenAITranscriptionResponseFormat.verboseJson =>
      TransportResponseType.json,
    _ => TransportResponseType.plainText,
  };
}
