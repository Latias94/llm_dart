import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_content_projection.dart';
import 'google_generation_config_encoder.dart';
import 'google_options.dart';
import 'google_tool_configuration.dart';

final class GoogleGenerateContentRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  GoogleGenerateContentRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class GoogleGenerateContentCodec {
  const GoogleGenerateContentCodec();

  GoogleGenerateContentRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required GoogleChatModelSettings settings,
    required GoogleGenerateTextOptions providerOptions,
  }) {
    final warnings = <ModelWarning>[];
    const contentProjectionCodec = GoogleContentProjectionCodec();
    final promptProjection = contentProjectionCodec.encodePrompt(
      modelId: modelId,
      prompt: prompt,
    );
    final systemInstructionParts = promptProjection.systemInstructionParts;
    final contents = promptProjection.contents;
    final isGemmaModel = modelId.toLowerCase().startsWith('gemma-');

    final includeServerSideToolInvocations =
        providerOptions.includeServerSideToolInvocations ??
            settings.includeServerSideToolInvocations;
    final promptRequiresServerToolReplay =
        contentProjectionCodec.promptRequiresServerToolReplay(prompt);

    final nativeTools = providerOptions.tools ?? settings.tools;
    final toolConfiguration = const GoogleToolConfigurationCodec().encode(
      modelId: modelId,
      tools: tools,
      toolChoice: toolChoice,
      nativeTools: nativeTools,
      includeServerSideToolInvocations: includeServerSideToolInvocations,
      promptRequiresServerToolReplay: promptRequiresServerToolReplay,
      warnings: warnings,
    );

    final generationConfig = const GoogleGenerationConfigEncoder().encode(
      modelId: modelId,
      options: options,
      providerOptions: providerOptions,
      warnings: warnings,
    );

    final safetySettings =
        providerOptions.safetySettings ?? settings.safetySettings;

    final body = <String, Object?>{
      'contents': contents,
      if (systemInstructionParts.isNotEmpty && !isGemmaModel)
        'systemInstruction': {
          'parts': systemInstructionParts,
        },
      if (generationConfig.isNotEmpty) 'generationConfig': generationConfig,
      if (safetySettings.isNotEmpty)
        'safetySettings': [
          for (final setting in safetySettings) setting.toJson(),
        ],
      if (providerOptions.cachedContent != null)
        'cachedContent': providerOptions.cachedContent,
      if (toolConfiguration.tools != null) 'tools': toolConfiguration.tools,
      if (toolConfiguration.toolConfig != null)
        'toolConfig': toolConfiguration.toolConfig,
    };

    return GoogleGenerateContentRequest(
      body: body,
      warnings: warnings,
    );
  }
}
