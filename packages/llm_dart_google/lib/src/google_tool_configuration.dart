import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_language_model_policy.dart';
import 'google_tools.dart';

final class GoogleToolConfiguration {
  final List<Object?>? tools;
  final Map<String, Object?>? toolConfig;

  const GoogleToolConfiguration({
    this.tools,
    this.toolConfig,
  });
}

final class GoogleToolConfigurationCodec {
  const GoogleToolConfigurationCodec();

  GoogleToolConfiguration encode({
    required String modelId,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required List<GoogleNativeTool> nativeTools,
    required bool includeServerSideToolInvocations,
    required bool promptRequiresServerToolReplay,
    required List<ModelWarning> warnings,
  }) {
    final policy = GoogleLanguageModelPolicy(modelId);
    _validateServerSideToolInvocations(
      policy: policy,
      includeServerSideToolInvocations: includeServerSideToolInvocations,
    );
    if (promptRequiresServerToolReplay && !includeServerSideToolInvocations) {
      throw UnsupportedError(
        'Google server-side tool replay requires includeServerSideToolInvocations=true for Gemini 3 follow-up requests.',
      );
    }

    final encodedNativeTools = _encodeNativeTools(
      policy: policy,
      tools: nativeTools,
      warnings: warnings,
    );
    final useNativeTools = encodedNativeTools.isNotEmpty;
    final useMixedTools = policy.supportsMixedToolRequests(
      includeServerSideToolInvocations: includeServerSideToolInvocations,
      hasNativeTools: useNativeTools,
      hasFunctionTools: tools.isNotEmpty,
    );

    if (useNativeTools && tools.isNotEmpty && !useMixedTools) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'tools',
          message: policy.isGemini3StyleModel
              ? 'Gemini 3 mixed Google native tools and common function tools require includeServerSideToolInvocations=true. The common function tools have been ignored for this call.'
              : 'Google native tools do not mix cleanly with common function tools yet. The common function tools have been ignored for this call.',
        ),
      );
    }

    if (useNativeTools && toolChoice != null && !useMixedTools) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'toolChoice',
          message: policy.isGemini3StyleModel
              ? 'toolChoice is ignored when Google native tools are enabled unless includeServerSideToolInvocations=true is set for a Gemini 3 mixed-tool request.'
              : 'toolChoice is ignored when Google native tools are enabled for this call.',
        ),
      );
    }

    final encodedFunctionTools = _encodeFunctionTools(tools);
    final shouldIncludeServerSideToolInvocations =
        includeServerSideToolInvocations &&
            (useNativeTools ||
                tools.isNotEmpty ||
                promptRequiresServerToolReplay);
    final encodedToolConfig = _encodeToolConfig(
      tools: useMixedTools || !useNativeTools ? tools : const [],
      toolChoice: useMixedTools || !useNativeTools ? toolChoice : null,
      includeServerSideToolInvocations: shouldIncludeServerSideToolInvocations,
    );

    final encodedTools = useMixedTools
        ? <Object?>[
            ...encodedNativeTools,
            ...?encodedFunctionTools,
          ]
        : encodedNativeTools.isNotEmpty
            ? encodedNativeTools
            : encodedFunctionTools;

    return GoogleToolConfiguration(
      tools: encodedTools,
      toolConfig: encodedToolConfig,
    );
  }

  List<Object?>? _encodeFunctionTools(List<FunctionToolDefinition> tools) {
    if (tools.isEmpty) {
      return null;
    }

    return [
      {
        'functionDeclarations': [
          for (final tool in tools)
            {
              'name': tool.name,
              'description': tool.description ?? '',
              'parameters': tool.inputSchema.toJson(),
            },
        ],
      },
    ];
  }

  List<Object?> _encodeNativeTools({
    required GoogleLanguageModelPolicy policy,
    required List<GoogleNativeTool> tools,
    required List<ModelWarning> warnings,
  }) {
    if (tools.isEmpty) {
      return const [];
    }

    final encoded = <Object?>[];

    for (final tool in tools) {
      if (!policy.supportsNativeTools) {
        warnings.add(
          ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'tools',
            message:
                'Google native tool "${tool.name}" requires Gemini 2.0 or newer compatible models.',
          ),
        );
        continue;
      }

      encoded.add(tool.toJson());
    }

    return encoded;
  }

  Map<String, Object?>? _encodeToolConfig({
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required bool includeServerSideToolInvocations,
  }) {
    if (tools.isEmpty && !includeServerSideToolInvocations) {
      return null;
    }

    Map<String, Object?>? functionCallingConfig;
    if (tools.isNotEmpty) {
      final hasStrictTools = tools.any((tool) => tool.strict == true);
      String? mode;
      List<String>? allowedFunctionNames;

      switch (toolChoice) {
        case null:
          if (hasStrictTools) {
            mode = 'VALIDATED';
          }
        case AutoToolChoice():
          mode = hasStrictTools ? 'VALIDATED' : 'AUTO';
        case NoneToolChoice():
          mode = 'NONE';
        case RequiredToolChoice():
          mode = hasStrictTools ? 'VALIDATED' : 'ANY';
        case SpecificToolChoice(toolName: final toolName):
          mode = hasStrictTools ? 'VALIDATED' : 'ANY';
          allowedFunctionNames = [toolName];
      }

      if (mode != null) {
        functionCallingConfig = {
          'mode': mode,
          if (allowedFunctionNames != null)
            'allowedFunctionNames': allowedFunctionNames,
        };
      }
    }

    return {
      if (includeServerSideToolInvocations)
        'includeServerSideToolInvocations': true,
      if (functionCallingConfig != null)
        'functionCallingConfig': functionCallingConfig,
    };
  }

  void _validateServerSideToolInvocations({
    required GoogleLanguageModelPolicy policy,
    required bool includeServerSideToolInvocations,
  }) {
    if (!includeServerSideToolInvocations) {
      return;
    }

    if (!policy.supportsServerSideToolInvocations) {
      throw UnsupportedError(
        'Google includeServerSideToolInvocations is currently only supported for Gemini 3 models.',
      );
    }
  }
}
