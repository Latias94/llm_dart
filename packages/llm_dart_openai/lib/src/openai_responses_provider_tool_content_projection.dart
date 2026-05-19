import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_code_interpreter_projection.dart';
import 'openai_responses_computer_use_projection.dart';
import 'openai_responses_content_part_support.dart';
import 'openai_responses_file_search_projection.dart';
import 'openai_responses_image_generation_projection.dart';
import 'openai_responses_web_search_projection.dart';

List<ContentPart> decodeOpenAIResponsesCodeInterpreterCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesCodeInterpreterCall(item);
  if (projection == null) {
    return const [];
  }

  return openAIResponsesToolCallAndResultContentParts(
    toolCall: projection.toToolCall(),
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

List<ContentPart> decodeOpenAIResponsesImageGenerationCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesImageGenerationCall(item);
  if (projection == null) {
    return const [];
  }

  return openAIResponsesToolCallAndResultContentParts(
    toolCall: projection.toToolCall(),
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

List<ContentPart> decodeOpenAIResponsesFileSearchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesFileSearchCall(item);
  if (projection == null) {
    return const [];
  }

  return openAIResponsesToolCallAndResultContentParts(
    toolCall: projection.toToolCall(),
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

List<ContentPart> decodeOpenAIResponsesWebSearchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesWebSearchCall(item);
  if (projection == null) {
    return const [];
  }

  return openAIResponsesToolCallAndResultContentParts(
    toolCall: projection.toToolCall(),
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

List<ContentPart> decodeOpenAIResponsesComputerUseCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesComputerUseCall(item);
  if (projection == null) {
    return const [];
  }

  return openAIResponsesToolCallAndResultContentParts(
    toolCall: projection.toToolCall(),
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}
