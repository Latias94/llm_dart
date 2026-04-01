import 'openai_image_types.dart';

enum OpenAIBuiltInToolType {
  webSearch,
  fileSearch,
  computerUse,
  imageGeneration,
  mcp,
  codeInterpreter,
}

abstract interface class OpenAIBuiltInTool {
  OpenAIBuiltInToolType get type;

  Map<String, Object?> toJson();
}

final class OpenAIWebSearchTool implements OpenAIBuiltInTool {
  const OpenAIWebSearchTool();

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.webSearch;

  @override
  Map<String, Object?> toJson() {
    return const {
      'type': 'web_search_preview',
    };
  }
}

final class OpenAIFileSearchTool implements OpenAIBuiltInTool {
  final List<String>? vectorStoreIds;
  final Map<String, Object?>? parameters;

  const OpenAIFileSearchTool({
    this.vectorStoreIds,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.fileSearch;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'file_search',
      if (vectorStoreIds != null && vectorStoreIds!.isNotEmpty)
        'vector_store_ids': List<String>.unmodifiable(vectorStoreIds!),
      if (parameters != null) ...parameters!,
    };
  }
}

final class OpenAIComputerUseTool implements OpenAIBuiltInTool {
  final int displayWidth;
  final int displayHeight;
  final String environment;
  final Map<String, Object?>? parameters;

  const OpenAIComputerUseTool({
    required this.displayWidth,
    required this.displayHeight,
    required this.environment,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.computerUse;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'computer_use_preview',
      'display_width': displayWidth,
      'display_height': displayHeight,
      'environment': environment,
      if (parameters != null) ...parameters!,
    };
  }
}

enum OpenAIImageGenerationInputFidelity {
  low('low'),
  high('high');

  const OpenAIImageGenerationInputFidelity(this.value);

  final String value;
}

enum OpenAIImageGenerationModeration {
  auto('auto');

  const OpenAIImageGenerationModeration(this.value);

  final String value;
}

enum OpenAIImageGenerationSize {
  auto('auto'),
  square1024('1024x1024'),
  portrait1024x1536('1024x1536'),
  landscape1536x1024('1536x1024');

  const OpenAIImageGenerationSize(this.value);

  final String value;
}

final class OpenAIImageMask {
  final String? fileId;
  final Uri? imageUrl;

  const OpenAIImageMask({
    this.fileId,
    this.imageUrl,
  }) : assert(
          fileId != null || imageUrl != null,
          'OpenAIImageMask needs either a fileId or an imageUrl.',
        );

  Map<String, Object?> toJson() {
    return {
      if (fileId != null) 'file_id': fileId,
      if (imageUrl != null) 'image_url': imageUrl.toString(),
    };
  }
}

final class OpenAIImageGenerationTool implements OpenAIBuiltInTool {
  final OpenAIImageBackground? background;
  final OpenAIImageGenerationInputFidelity? inputFidelity;
  final OpenAIImageMask? inputImageMask;
  final String? model;
  final OpenAIImageGenerationModeration? moderation;
  final int? partialImages;
  final OpenAIImageQuality? quality;
  final int? outputCompression;
  final OpenAIImageOutputFormat? outputFormat;
  final OpenAIImageGenerationSize? size;
  final Map<String, Object?>? parameters;

  const OpenAIImageGenerationTool({
    this.background,
    this.inputFidelity,
    this.inputImageMask,
    this.model,
    this.moderation,
    this.partialImages,
    this.quality,
    this.outputCompression,
    this.outputFormat,
    this.size,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.imageGeneration;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'image_generation',
      if (background != null) 'background': background!.value,
      if (inputFidelity != null) 'input_fidelity': inputFidelity!.value,
      if (inputImageMask != null) 'input_image_mask': inputImageMask!.toJson(),
      if (model != null) 'model': model,
      if (moderation != null) 'moderation': moderation!.value,
      if (partialImages != null) 'partial_images': partialImages,
      if (quality != null) 'quality': quality!.value,
      if (outputCompression != null) 'output_compression': outputCompression,
      if (outputFormat != null) 'output_format': outputFormat!.value,
      if (size != null) 'size': size!.value,
      if (parameters != null) ...parameters!,
    };
  }
}

sealed class OpenAICodeInterpreterContainer {
  const OpenAICodeInterpreterContainer();

  Object toJson();
}

final class OpenAICodeInterpreterAutoContainer
    extends OpenAICodeInterpreterContainer {
  final List<String>? fileIds;

  const OpenAICodeInterpreterAutoContainer({
    this.fileIds,
  });

  @override
  Object toJson() {
    return {
      'type': 'auto',
      if (fileIds != null) 'file_ids': List<String>.unmodifiable(fileIds!),
    };
  }
}

final class OpenAICodeInterpreterContainerReference
    extends OpenAICodeInterpreterContainer {
  final String containerId;

  const OpenAICodeInterpreterContainerReference(this.containerId);

  @override
  Object toJson() => containerId;
}

final class OpenAICodeInterpreterTool implements OpenAIBuiltInTool {
  final OpenAICodeInterpreterContainer? container;
  final Map<String, Object?>? parameters;

  const OpenAICodeInterpreterTool({
    this.container,
    this.parameters,
  });

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.codeInterpreter;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'code_interpreter',
      'container':
          (container ?? const OpenAICodeInterpreterAutoContainer()).toJson(),
      if (parameters != null) ...parameters!,
    };
  }
}

enum OpenAIMcpAllowedToolsType {
  names,
  filter,
}

final class OpenAIMcpAllowedTools {
  final OpenAIMcpAllowedToolsType type;
  final List<String>? toolNames;
  final bool? readOnly;

  const OpenAIMcpAllowedTools.names(this.toolNames)
      : type = OpenAIMcpAllowedToolsType.names,
        readOnly = null;

  const OpenAIMcpAllowedTools.filter({
    this.readOnly,
    this.toolNames,
  })  : type = OpenAIMcpAllowedToolsType.filter,
        assert(
          readOnly != null || toolNames != null,
          'OpenAIMcpAllowedTools.filter requires readOnly or toolNames.',
        );

  Object toJson() {
    return switch (type) {
      OpenAIMcpAllowedToolsType.names =>
        List<String>.unmodifiable(toolNames ?? const []),
      OpenAIMcpAllowedToolsType.filter => {
          if (readOnly != null) 'read_only': readOnly,
          if (toolNames != null && toolNames!.isNotEmpty)
            'tool_names': List<String>.unmodifiable(toolNames!),
        },
    };
  }
}

enum OpenAIMcpApprovalPolicyType {
  always,
  never,
  neverForTools,
}

final class OpenAIMcpApprovalPolicy {
  final OpenAIMcpApprovalPolicyType type;
  final List<String>? toolNames;

  const OpenAIMcpApprovalPolicy.always()
      : type = OpenAIMcpApprovalPolicyType.always,
        toolNames = null;

  const OpenAIMcpApprovalPolicy.never()
      : type = OpenAIMcpApprovalPolicyType.never,
        toolNames = null;

  const OpenAIMcpApprovalPolicy.neverForTools(this.toolNames)
      : type = OpenAIMcpApprovalPolicyType.neverForTools,
        assert(
          toolNames != null,
          'OpenAIMcpApprovalPolicy.neverForTools requires tool names.',
        );

  Object toJson() {
    return switch (type) {
      OpenAIMcpApprovalPolicyType.always => 'always',
      OpenAIMcpApprovalPolicyType.never => 'never',
      OpenAIMcpApprovalPolicyType.neverForTools => {
          'never': {
            'tool_names': List<String>.unmodifiable(toolNames!),
          },
        },
    };
  }
}

final class OpenAIMcpTool implements OpenAIBuiltInTool {
  final String serverLabel;
  final OpenAIMcpAllowedTools? allowedTools;
  final String? authorization;
  final String? connectorId;
  final Map<String, String>? headers;
  final OpenAIMcpApprovalPolicy? requireApproval;
  final String? serverDescription;
  final Uri? serverUrl;
  final Map<String, Object?>? parameters;

  const OpenAIMcpTool({
    required this.serverLabel,
    this.allowedTools,
    this.authorization,
    this.connectorId,
    this.headers,
    this.requireApproval,
    this.serverDescription,
    this.serverUrl,
    this.parameters,
  }) : assert(
          connectorId != null || serverUrl != null,
          'OpenAIMcpTool requires either a connectorId or a serverUrl.',
        );

  @override
  OpenAIBuiltInToolType get type => OpenAIBuiltInToolType.mcp;

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'mcp',
      'server_label': serverLabel,
      if (allowedTools != null) 'allowed_tools': allowedTools!.toJson(),
      if (authorization != null) 'authorization': authorization,
      if (connectorId != null) 'connector_id': connectorId,
      if (headers != null && headers!.isNotEmpty)
        'headers': Map<String, String>.unmodifiable(headers!),
      'require_approval': requireApproval?.toJson() ?? 'never',
      if (serverDescription != null) 'server_description': serverDescription,
      if (serverUrl != null) 'server_url': serverUrl.toString(),
      if (parameters != null) ...parameters!,
    };
  }
}

final class OpenAIBuiltInTools {
  static OpenAIWebSearchTool webSearch() => const OpenAIWebSearchTool();

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
}
