import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_options.dart';

GoogleEmbeddingModelSettings resolveGoogleEmbeddingModelSettings(
  ProviderModelOptions settings,
) {
  return resolveProviderModelOptions<GoogleEmbeddingModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'GoogleEmbeddingModelSettings',
    usageContext: 'Google embedding models',
  );
}

GoogleEmbedOptions? resolveGoogleEmbeddingProviderOptions(
  CallOptions callOptions,
) {
  return resolveProviderInvocationOptions<GoogleEmbedOptions>(
    callOptions.providerOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'GoogleEmbedOptions',
    usageContext: 'Google embedding models',
  );
}

Object buildGoogleEmbeddingRequestBody({
  required String modelId,
  required EmbedRequest request,
  required GoogleEmbedOptions? options,
}) {
  if (request.values.length == 1) {
    return buildGoogleSingleEmbeddingRequestBody(
      request.values.single,
      dimensions: request.dimensions,
      options: options,
    );
  }

  return buildGoogleBatchEmbeddingRequestBody(
    modelId: modelId,
    values: request.values,
    dimensions: request.dimensions,
    options: options,
  );
}

Map<String, Object?> buildGoogleSingleEmbeddingRequestBody(
  String value, {
  required int? dimensions,
  required GoogleEmbedOptions? options,
}) {
  return {
    'content': {
      'parts': [
        {'text': value},
      ],
    },
    if (options?.taskType case final taskType?) 'taskType': taskType,
    if (options?.title case final title?) 'title': title,
    if (dimensions != null) 'outputDimensionality': dimensions,
  };
}

Map<String, Object?> buildGoogleBatchEmbeddingRequestBody({
  required String modelId,
  required List<String> values,
  required int? dimensions,
  required GoogleEmbedOptions? options,
}) {
  return {
    'requests': values
        .map(
          (value) => <String, Object?>{
            'model': 'models/$modelId',
            'content': {
              'parts': [
                {'text': value},
              ],
            },
            if (options?.taskType case final taskType?) 'taskType': taskType,
            if (options?.title case final title?) 'title': title,
            if (dimensions != null) 'outputDimensionality': dimensions,
          },
        )
        .toList(),
  };
}
