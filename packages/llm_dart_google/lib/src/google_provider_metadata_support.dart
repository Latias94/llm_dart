import 'package:llm_dart_core/llm_dart_core.dart';

import 'google_shared.dart';

ProviderMetadata? buildGoogleGenerationMetadata({
  Map<String, Object?>? promptFeedback,
  Map<String, Object?>? groundingMetadata,
  Map<String, Object?>? urlContextMetadata,
  List<Object?>? safetyRatings,
  Map<String, Object?>? usageMetadata,
  String? finishMessage,
}) {
  return googleProviderMetadata({
    'promptFeedback': promptFeedback,
    'groundingMetadata': groundingMetadata,
    'urlContextMetadata': urlContextMetadata,
    'safetyRatings': safetyRatings,
    'usageMetadata': usageMetadata,
    'finishMessage': finishMessage,
  });
}

ProviderMetadata? googleThoughtSignatureMetadata(
  String? thoughtSignature, {
  required bool isThought,
}) {
  if (thoughtSignature == null && !isThought) {
    return null;
  }

  return googleProviderMetadata({
    'thoughtSignature': thoughtSignature,
    if (isThought) 'thought': true,
  });
}

ProviderMetadata? googleFunctionCallIdMetadata(String? functionCallId) {
  if (functionCallId == null || functionCallId.isEmpty) {
    return null;
  }

  return googleProviderMetadata({
    'functionCallId': functionCallId,
  });
}
