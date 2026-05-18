import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_metadata_support.dart';

FinishReason mapAnthropicResultFinishReason(String? rawReason) {
  return mapAnthropicStopReason(rawReason);
}

UsageStats? decodeAnthropicResultUsage(Map<String, Object?>? usage) {
  return decodeAnthropicUsage(usage);
}

Map<String, Object?>? decodeAnthropicResultContainer(
  Map<String, Object?>? container,
) {
  return decodeAnthropicContainerMetadata(container);
}
