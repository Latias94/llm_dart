import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_tool_options.dart';
import 'openai_tool_output_encoding.dart';

final class OpenAIChatCompletionsRequestToolCodec {
  final String providerNamespace;

  const OpenAIChatCompletionsRequestToolCodec({
    this.providerNamespace = 'openai',
  });

  List<Map<String, Object?>> encodeTools(
    List<FunctionToolDefinition> tools,
  ) {
    return [
      for (final tool in tools) _encodeFunctionTool(tool),
    ];
  }

  Map<String, Object?> _encodeFunctionTool(FunctionToolDefinition tool) {
    final options = _resolveOpenAIToolOptions(tool);
    final strict = options?.strict ?? tool.strict;

    return {
      'type': 'function',
      'function': {
        'name': tool.name,
        if (tool.description != null) 'description': tool.description,
        'parameters': tool.inputSchema.toJson(),
        if (strict != null) 'strict': strict,
      },
    };
  }

  OpenAIToolOptions? _resolveOpenAIToolOptions(FunctionToolDefinition tool) {
    if (tool.providerOptions == null) {
      return null;
    }

    if (providerNamespace != 'openai') {
      throw ArgumentError.value(
        tool.providerOptions,
        'tool.providerOptions',
        'Provider-specific OpenAI tool options are not supported for '
            '$providerNamespace function tool "${tool.name}".',
      );
    }

    return resolveProviderToolOptions<OpenAIToolOptions>(
      tool.providerOptions,
      parameterName: 'tool.providerOptions',
      expectedTypeName: 'OpenAIToolOptions',
      usageContext: '$providerNamespace function tool "${tool.name}"',
    );
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
