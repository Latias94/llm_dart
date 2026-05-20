import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';

typedef OpenAIFamilyModelResponseDecoder<T> = T Function(
  Object? body,
  Map<String, String> headers,
);

Map<String, String> buildOpenAIFamilyDefaultHeaders({
  required OpenAIFamilyProfile profile,
  required String apiKey,
  String? organization,
  String? project,
  Map<String, String> headers = const {},
}) {
  return profile.buildHeaders(
    apiKey: apiKey,
    extraHeaders: {
      if (organization != null) 'openai-organization': organization,
      if (project != null) 'openai-project': project,
      ...headers,
    },
  );
}

T resolveOpenAIModelSettings<T extends ProviderModelOptions>(
  ProviderModelOptions settings, {
  required String parameterName,
  required String expectedTypeName,
}) {
  return resolveProviderModelOptions<T>(
    settings,
    parameterName: parameterName,
    expectedTypeName: expectedTypeName,
  );
}

T? resolveOpenAIProviderOptions<T extends ProviderInvocationOptions>(
  CallOptions callOptions, {
  required String parameterName,
  required String expectedTypeName,
}) {
  return resolveProviderInvocationOptions<T>(
    callOptions.providerOptions,
    parameterName: parameterName,
    expectedTypeName: expectedTypeName,
  );
}

Future<T> sendOpenAIFamilyModelRequest<T>({
  required TransportClient transport,
  required TransportRequest request,
  required OpenAIFamilyModelResponseDecoder<T> decode,
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

String? openAIStringOrNull(Object? value) {
  return value is String ? value : null;
}

int? openAIIntOrNull(Object? value) {
  return switch (value) {
    int() => value,
    num() => value.toInt(),
    _ => null,
  };
}

double? openAIDoubleOrNull(Object? value) {
  return value is num ? value.toDouble() : null;
}
