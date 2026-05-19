import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_custom_projection.dart';

CustomContentPart? decodeOpenAIResponsesCustomOutput(
  Map<String, Object?> item,
) {
  return projectOpenAIResponsesCustomOutputItem(item)?.toContentPart();
}
