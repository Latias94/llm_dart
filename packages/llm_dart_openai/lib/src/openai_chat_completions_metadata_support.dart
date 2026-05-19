import 'package:llm_dart_provider/llm_dart_provider.dart';

ProviderMetadata? openAIChatCompletionsResponseMetadata({
  required String providerNamespace,
  required Map<String, Object?> response,
  required Map<String, Object?>? choice,
  List<Object?>? logprobs,
}) {
  return openAIChatCompletionsProviderMetadata(
    providerNamespace: providerNamespace,
    values: {
      'serviceTier': _asString(response['service_tier']),
      'systemFingerprint': _asString(response['system_fingerprint']),
      'finishReason': _asString(choice?['finish_reason']),
      if (logprobs != null && logprobs.isNotEmpty)
        'logprobs': List<Object?>.unmodifiable(logprobs),
    },
  );
}

ProviderMetadata? openAIChatCompletionsProviderMetadata({
  required String providerNamespace,
  required Map<String, Object?> values,
}) {
  final scopedValues = <String, Object?>{};
  for (final entry in values.entries) {
    if (entry.value != null) {
      scopedValues[entry.key] = entry.value;
    }
  }

  if (scopedValues.isEmpty) {
    return null;
  }

  return ProviderMetadata.forNamespace(providerNamespace, scopedValues);
}

String? _asString(Object? value) => value is String ? value : null;
