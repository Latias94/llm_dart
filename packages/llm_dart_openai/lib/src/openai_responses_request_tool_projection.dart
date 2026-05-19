import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_native_tools.dart';

final class OpenAIResponsesRequestToolProjection {
  const OpenAIResponsesRequestToolProjection();

  List<Map<String, Object?>> encode({
    required List<FunctionToolDefinition> tools,
    required List<OpenAIBuiltInTool>? builtInTools,
  }) {
    final encoded = <Map<String, Object?>>[
      for (final tool in tools) _encodeFunctionTool(tool),
    ];

    if (builtInTools != null) {
      encoded.addAll(
        builtInTools.map((tool) => tool.toJson()),
      );
    }

    return encoded;
  }

  Map<String, Object?> _encodeFunctionTool(FunctionToolDefinition tool) {
    return {
      'type': 'function',
      'name': tool.name,
      if (tool.description != null) 'description': tool.description,
      'parameters': tool.inputSchema.toJson(),
      if (tool.strict != null) 'strict': tool.strict,
    };
  }
}
