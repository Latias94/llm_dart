import 'openai_code_interpreter_tool.dart';
import 'openai_computer_use_tool.dart';
import 'openai_custom_tool.dart';
import 'openai_file_search_tool.dart';
import 'openai_image_generation_tool.dart';
import 'openai_image_types.dart';
import 'openai_mcp_tool.dart';
import 'openai_shell_tool.dart';
import 'openai_tool_search_tool.dart';
import 'openai_web_search_tool.dart';

final class OpenAIBuiltInTools {
  static OpenAIWebSearchTool webSearch({
    OpenAIWebSearchApi api = OpenAIWebSearchApi.preview,
    OpenAIWebSearchContextSize? searchContextSize,
    OpenAIWebSearchUserLocation? userLocation,
    OpenAIWebSearchFilters? filters,
    bool? externalWebAccess,
  }) {
    return OpenAIWebSearchTool(
      api: api,
      searchContextSize: searchContextSize,
      userLocation: userLocation,
      filters: filters,
      externalWebAccess: externalWebAccess,
    );
  }

  static OpenAIWebSearchTool webSearchPreview({
    OpenAIWebSearchContextSize? searchContextSize,
    OpenAIWebSearchUserLocation? userLocation,
  }) {
    return OpenAIWebSearchTool.preview(
      searchContextSize: searchContextSize,
      userLocation: userLocation,
    );
  }

  static OpenAIWebSearchTool webSearchCurrent({
    OpenAIWebSearchContextSize? searchContextSize,
    OpenAIWebSearchUserLocation? userLocation,
    OpenAIWebSearchFilters? filters,
    bool? externalWebAccess,
  }) {
    return OpenAIWebSearchTool.current(
      searchContextSize: searchContextSize,
      userLocation: userLocation,
      filters: filters,
      externalWebAccess: externalWebAccess,
    );
  }

  static OpenAIFileSearchTool fileSearch({
    List<String>? vectorStoreIds,
    Map<String, Object?>? parameters,
  }) {
    return OpenAIFileSearchTool(
      vectorStoreIds: vectorStoreIds,
      parameters: parameters,
    );
  }

  static OpenAIComputerUseTool computerUse({
    required int displayWidth,
    required int displayHeight,
    required String environment,
    Map<String, Object?>? parameters,
  }) {
    return OpenAIComputerUseTool(
      displayWidth: displayWidth,
      displayHeight: displayHeight,
      environment: environment,
      parameters: parameters,
    );
  }

  static OpenAIImageGenerationTool imageGeneration({
    OpenAIImageBackground? background,
    OpenAIImageGenerationInputFidelity? inputFidelity,
    OpenAIImageMask? inputImageMask,
    String? model,
    OpenAIImageGenerationModeration? moderation,
    int? partialImages,
    OpenAIImageQuality? quality,
    int? outputCompression,
    OpenAIImageOutputFormat? outputFormat,
    OpenAIImageGenerationSize? size,
    Map<String, Object?>? parameters,
  }) {
    return OpenAIImageGenerationTool(
      background: background,
      inputFidelity: inputFidelity,
      inputImageMask: inputImageMask,
      model: model,
      moderation: moderation,
      partialImages: partialImages,
      quality: quality,
      outputCompression: outputCompression,
      outputFormat: outputFormat,
      size: size,
      parameters: parameters,
    );
  }

  static OpenAICodeInterpreterTool codeInterpreter({
    OpenAICodeInterpreterContainer? container,
    Map<String, Object?>? parameters,
  }) {
    return OpenAICodeInterpreterTool(
      container: container,
      parameters: parameters,
    );
  }

  static OpenAIMcpTool mcp({
    required String serverLabel,
    OpenAIMcpAllowedTools? allowedTools,
    String? authorization,
    String? connectorId,
    Map<String, String>? headers,
    OpenAIMcpApprovalPolicy? requireApproval,
    String? serverDescription,
    Uri? serverUrl,
    Map<String, Object?>? parameters,
  }) {
    return OpenAIMcpTool(
      serverLabel: serverLabel,
      allowedTools: allowedTools,
      authorization: authorization,
      connectorId: connectorId,
      headers: headers,
      requireApproval: requireApproval,
      serverDescription: serverDescription,
      serverUrl: serverUrl,
      parameters: parameters,
    );
  }

  static OpenAILocalShellTool localShell() => const OpenAILocalShellTool();

  static OpenAIShellTool shell({
    OpenAIShellEnvironment? environment,
  }) {
    return OpenAIShellTool(environment: environment);
  }

  static OpenAIApplyPatchTool applyPatch() => const OpenAIApplyPatchTool();

  static OpenAIToolSearchTool toolSearch({
    OpenAIToolSearchExecution? execution,
    String? description,
    Map<String, Object?>? parameters,
  }) {
    return OpenAIToolSearchTool(
      execution: execution,
      description: description,
      parameters: parameters,
    );
  }

  static OpenAICustomTool custom({
    required String name,
    String? description,
    OpenAICustomToolFormat? format,
  }) {
    return OpenAICustomTool(
      name: name,
      description: description,
      format: format,
    );
  }
}
