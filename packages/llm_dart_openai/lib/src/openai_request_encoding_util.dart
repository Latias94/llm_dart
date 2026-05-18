import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_options.dart';

String encodeOpenAIJsonString(Object? value) {
  if (value == null) {
    return '{}';
  }

  if (value is String) {
    return value;
  }

  return jsonEncode(value);
}

String normalizeOpenAIImageMediaTypeForDataUrl(String mediaType) {
  if (mediaType == 'image/*') {
    return 'image/jpeg';
  }

  return mediaType;
}

String? resolveOpenAIImageDetail(
  ProviderPromptPartOptions? providerOptions, {
  required String path,
}) {
  final options = resolveProviderPromptPartOptions<OpenAIPromptPartOptions>(
    providerOptions,
    parameterName: path,
    expectedTypeName: 'OpenAIPromptPartOptions',
    usageContext: 'OpenAI-family image prompt parts',
  );
  return options?.imageDetail;
}

String? resolveOpenAIFileId({
  required FileData data,
  required String providerNamespace,
  required String context,
}) {
  return data.providerReference?.requireProvider(
    providerNamespace,
    context: context,
  );
}

ProviderMetadata? openAIPromptPartProviderMetadata(PromptPart part) {
  return providerReplayMetadataFromOptions(part.providerOptions);
}

Map<String, Object?>? openAIRequestAsMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

String? openAIRequestAsString(Object? value) {
  return value is String ? value : null;
}

void removeOpenAIRequestBodyFieldWithWarning(
  Map<String, Object?> body,
  String key,
  List<ModelWarning> warnings, {
  required ModelWarning warning,
}) {
  if (!body.containsKey(key)) {
    return;
  }

  body.remove(key);
  warnings.add(warning);
}
