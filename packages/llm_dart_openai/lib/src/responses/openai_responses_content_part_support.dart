import 'package:llm_dart_provider/llm_dart_provider.dart';

ToolCallContentPart openAIResponsesToolCallContentPart(
  ToolCallContent toolCall, {
  required ProviderMetadata? providerMetadata,
}) {
  return ToolCallContentPart(
    toolCall,
    providerMetadata: providerMetadata,
  );
}

ToolResultContentPart openAIResponsesToolResultContentPart(
  ToolResultContent toolResult, {
  required ProviderMetadata? providerMetadata,
}) {
  return ToolResultContentPart(
    toolResult,
    providerMetadata: providerMetadata,
  );
}

List<ContentPart> openAIResponsesToolCallAndResultContentParts({
  required ToolCallContent toolCall,
  required ToolResultContent toolResult,
  required ProviderMetadata? providerMetadata,
}) {
  return [
    openAIResponsesToolCallContentPart(
      toolCall,
      providerMetadata: providerMetadata,
    ),
    openAIResponsesToolResultContentPart(
      toolResult,
      providerMetadata: providerMetadata,
    ),
  ];
}

List<ContentPart> openAIResponsesToolCallAndApprovalContentParts({
  required ToolCallContent toolCall,
  required ToolApprovalRequestContent approvalRequest,
  required ProviderMetadata? providerMetadata,
}) {
  return [
    openAIResponsesToolCallContentPart(
      toolCall,
      providerMetadata: providerMetadata,
    ),
    ToolApprovalRequestContentPart(
      approvalRequest,
      providerMetadata: providerMetadata,
    ),
  ];
}
