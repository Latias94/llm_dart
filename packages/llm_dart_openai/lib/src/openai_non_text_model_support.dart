import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_family_profile.dart';

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
  if (settings is T) {
    return settings;
  }

  throw ArgumentError.value(
    settings,
    parameterName,
    'Expected $expectedTypeName.',
  );
}

T? resolveOpenAIProviderOptions<T extends ProviderInvocationOptions>(
  CallOptions callOptions, {
  required String parameterName,
  required String expectedTypeName,
}) {
  final providerOptions = callOptions.providerOptions;
  if (providerOptions != null && providerOptions is! T) {
    throw ArgumentError.value(
      providerOptions,
      parameterName,
      'Expected $expectedTypeName.',
    );
  }

  return providerOptions as T?;
}

Map<String, Object?> decodeOpenAIJsonObject(
  Object? body, {
  required String responseName,
}) {
  if (body is Map<String, Object?>) {
    return body;
  }

  if (body is Map) {
    return Map<String, Object?>.from(body);
  }

  if (body is String) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  }

  throw StateError(
    'Expected an OpenAI $responseName JSON object but received ${body.runtimeType}.',
  );
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
