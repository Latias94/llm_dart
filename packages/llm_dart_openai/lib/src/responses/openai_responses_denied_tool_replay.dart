import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../common/openai_request_encoding_util.dart';

bool shouldSkipOpenAIResponsesDeniedToolReplay(ToolResultPromptPart part) {
  final output = part.toolOutput;
  if (output is ExecutionDeniedToolOutput) {
    return true;
  }

  if (output is JsonToolOutput || output is ErrorJsonToolOutput) {
    return _isExecutionDeniedJson(output.value);
  }

  return false;
}

bool shouldSkipOpenAIResponsesApprovalDeniedToolReplay(
  ToolResultPromptPart part,
) {
  final output = part.toolOutput;
  if (output is! ExecutionDeniedToolOutput) {
    return false;
  }

  final metadata = output.providerMetadata?.namespace('openai');
  final approvalId = openAIRequestAsString(metadata?['approvalId']);
  return approvalId != null;
}

bool _isExecutionDeniedJson(Object? value) {
  final map = openAIRequestAsMap(value);
  return map?['type'] == 'execution-denied';
}
