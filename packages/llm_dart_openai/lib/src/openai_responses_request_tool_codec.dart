import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_native_tools.dart';
import 'openai_responses_request_tool_projection.dart';
import 'openai_responses_tool_choice_projection.dart';
import 'openai_responses_tool_output_projection.dart';

final class OpenAIResponsesRequestToolCodec {
  final OpenAIResponsesRequestToolProjection toolProjection;
  final OpenAIResponsesToolChoiceProjection toolChoiceProjection;
  final OpenAIResponsesToolOutputProjection toolOutputProjection;

  const OpenAIResponsesRequestToolCodec({
    this.toolProjection = const OpenAIResponsesRequestToolProjection(),
    this.toolChoiceProjection = const OpenAIResponsesToolChoiceProjection(),
    this.toolOutputProjection = const OpenAIResponsesToolOutputProjection(),
  });

  List<Map<String, Object?>> encodeTools({
    required List<FunctionToolDefinition> tools,
    required List<OpenAIBuiltInTool>? builtInTools,
  }) {
    return toolProjection.encode(
      tools: tools,
      builtInTools: builtInTools,
    );
  }

  Map<String, Object?>? encodeToolChoice(
    ToolChoice? toolChoice, {
    required bool hasFunctionTools,
  }) {
    return toolChoiceProjection.encode(
      toolChoice,
      hasFunctionTools: hasFunctionTools,
    );
  }

  Object? encodeToolOutput(ToolOutput output) {
    return toolOutputProjection.encode(output);
  }
}
