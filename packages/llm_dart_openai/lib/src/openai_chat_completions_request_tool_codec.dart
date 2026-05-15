import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_tool_output_encoding.dart';

final class OpenAIChatCompletionsRequestToolCodec {
  const OpenAIChatCompletionsRequestToolCodec();

  List<Map<String, Object?>> encodeTools(
    List<FunctionToolDefinition> tools,
  ) {
    return [
      for (final tool in tools)
        {
          'type': 'function',
          'function': {
            'name': tool.name,
            if (tool.description != null) 'description': tool.description,
            'parameters': tool.inputSchema.toJson(),
            if (tool.strict != null) 'strict': tool.strict,
          },
        },
    ];
  }

  Object? encodeToolChoice(
    ToolChoice? toolChoice, {
    required bool hasFunctionTools,
  }) {
    if (!hasFunctionTools || toolChoice == null) {
      return null;
    }

    return switch (toolChoice) {
      AutoToolChoice() => 'auto',
      RequiredToolChoice() => 'required',
      NoneToolChoice() => 'none',
      SpecificToolChoice(toolName: final toolName) => {
          'type': 'function',
          'function': {
            'name': toolName,
          },
        },
    };
  }

  String encodeToolOutput(ToolOutput output) {
    return encodeOpenAIToolOutputAsText(output);
  }
}
