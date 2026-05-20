import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../tools/openai_native_tools.dart';
import '../tools/openai_tool_options.dart';

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
    final options = resolveProviderToolOptions<OpenAIToolOptions>(
      tool.providerOptions,
      parameterName: 'tool.providerOptions',
      expectedTypeName: 'OpenAIToolOptions',
      usageContext: 'OpenAI Responses function tool "${tool.name}"',
    );
    final strict = options?.strict ?? tool.strict;
    final deferLoading = options?.deferLoading;

    return {
      'type': 'function',
      'name': tool.name,
      if (tool.description != null) 'description': tool.description,
      'parameters': tool.inputSchema.toJson(),
      if (strict != null) 'strict': strict,
      if (deferLoading != null) 'defer_loading': deferLoading,
    };
  }
}
