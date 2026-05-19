import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_native_tools.dart';

final class OpenAIResponsesToolChoiceProjection {
  const OpenAIResponsesToolChoiceProjection();

  Object? encode(
    ToolChoice? toolChoice, {
    required bool hasFunctionTools,
    List<OpenAIBuiltInTool>? builtInTools,
  }) {
    if (toolChoice == null) {
      return null;
    }

    return switch (toolChoice) {
      AutoToolChoice() => 'auto',
      RequiredToolChoice() => 'required',
      NoneToolChoice() => 'none',
      SpecificToolChoice(:final toolName) => _encodeSpecificToolChoice(
          toolName,
          hasFunctionTools: hasFunctionTools,
          builtInTools: builtInTools,
        ),
    };
  }

  Object? _encodeSpecificToolChoice(
    String toolName, {
    required bool hasFunctionTools,
    required List<OpenAIBuiltInTool>? builtInTools,
  }) {
    if (_findBuiltInTool(toolName, builtInTools) case final tool?) {
      return switch (tool) {
        OpenAIFileSearchTool() => const {'type': 'file_search'},
        OpenAIWebSearchTool(:final api) => {'type': api.value},
        OpenAICodeInterpreterTool() => const {'type': 'code_interpreter'},
        OpenAIImageGenerationTool() => const {'type': 'image_generation'},
        OpenAIMcpTool() => const {'type': 'mcp'},
        OpenAIApplyPatchTool() => const {'type': 'apply_patch'},
        OpenAICustomTool(:final name) => {
            'type': 'custom',
            'name': name,
          },
        OpenAIComputerUseTool() ||
        OpenAILocalShellTool() ||
        OpenAIShellTool() ||
        OpenAIToolSearchTool() =>
          null,
        _ => null,
      };
    }

    if (!hasFunctionTools) {
      return null;
    }

    return {
      'type': 'function',
      'name': toolName,
    };
  }

  OpenAIBuiltInTool? _findBuiltInTool(
    String toolName,
    List<OpenAIBuiltInTool>? builtInTools,
  ) {
    if (builtInTools == null || builtInTools.isEmpty) {
      return null;
    }

    for (final tool in builtInTools) {
      if (_builtInToolChoiceName(tool) == toolName) {
        return tool;
      }
    }

    return null;
  }

  String? _builtInToolChoiceName(OpenAIBuiltInTool tool) {
    return switch (tool) {
      OpenAIFileSearchTool() => 'file_search',
      OpenAIWebSearchTool(:final api) => api.value,
      OpenAICodeInterpreterTool() => 'code_interpreter',
      OpenAIImageGenerationTool() => 'image_generation',
      OpenAIMcpTool() => 'mcp',
      OpenAIApplyPatchTool() => 'apply_patch',
      OpenAICustomTool(:final name) => name,
      OpenAIComputerUseTool() ||
      OpenAILocalShellTool() ||
      OpenAIShellTool() ||
      OpenAIToolSearchTool() =>
        null,
      _ => null,
    };
  }
}
