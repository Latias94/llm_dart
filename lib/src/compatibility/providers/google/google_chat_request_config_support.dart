part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestConfigSupport {
  final GoogleConfig config;
  final GoogleChatMessageCodec messageCodec;

  _GoogleChatRequestConfigSupport({
    required this.config,
    required this.messageCodec,
  });

  Map<String, dynamic> buildBodyWithConfig(
    List<Map<String, dynamic>> contents,
    List<Tool>? tools, {
    required bool stream,
  }) {
    final body = <String, dynamic>{'contents': contents};
    final generationConfig = <String, dynamic>{};

    _applySamplingConfig(generationConfig);
    _applySchemaConfig(generationConfig);
    _applyThinkingConfig(generationConfig, stream: stream);
    _applyImageConfig(generationConfig);

    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    _applySafetySettings(body);
    _applyTools(body, tools);
    _applyWebSearch(body);

    return body;
  }

  void _applySamplingConfig(Map<String, dynamic> generationConfig) {
    if (config.candidateCount != null) {
      generationConfig['candidateCount'] = config.candidateCount;
    }
    if (config.stopSequences != null && config.stopSequences!.isNotEmpty) {
      generationConfig['stopSequences'] = config.stopSequences;
    }
    if (config.maxTokens != null) {
      generationConfig['maxOutputTokens'] = config.maxTokens;
    }
    if (config.temperature != null) {
      generationConfig['temperature'] = config.temperature;
    }
    if (config.topP != null) {
      generationConfig['topP'] = config.topP;
    }
    if (config.topK != null) {
      generationConfig['topK'] = config.topK;
    }
  }

  void _applySchemaConfig(Map<String, dynamic> generationConfig) {
    if (config.jsonSchema != null && config.jsonSchema!.schema != null) {
      generationConfig['responseMimeType'] = 'application/json';

      final schema = Map<String, dynamic>.from(config.jsonSchema!.schema!);
      schema.remove('additionalProperties');
      generationConfig['responseSchema'] = schema;
    }
  }

  void _applyThinkingConfig(
    Map<String, dynamic> generationConfig, {
    required bool stream,
  }) {
    if (config.reasoningEffort != null ||
        config.thinkingBudgetTokens != null ||
        config.includeThoughts != null) {
      final thinkingConfig = <String, dynamic>{};

      if (config.includeThoughts != null) {
        thinkingConfig['includeThoughts'] = config.includeThoughts;
      } else if (stream) {
        thinkingConfig['includeThoughts'] = true;
      }

      if (config.thinkingBudgetTokens != null) {
        thinkingConfig['thinkingBudget'] = config.thinkingBudgetTokens;
      }

      if (thinkingConfig.isNotEmpty) {
        generationConfig['thinkingConfig'] = thinkingConfig;
      }
    } else if (stream) {
      generationConfig['thinkingConfig'] = {
        'includeThoughts': true,
      };
    }
  }

  void _applyImageConfig(Map<String, dynamic> generationConfig) {
    if (config.enableImageGeneration == true) {
      if (config.responseModalities != null) {
        generationConfig['responseModalities'] = config.responseModalities;
      } else {
        generationConfig['responseModalities'] = ['TEXT', 'IMAGE'];
      }
      generationConfig['responseMimeType'] = 'text/plain';
    }
  }

  void _applySafetySettings(Map<String, dynamic> body) {
    final effectiveSafetySettings =
        config.safetySettings ?? GoogleConfig.defaultSafetySettings;
    if (effectiveSafetySettings.isNotEmpty) {
      body['safetySettings'] =
          effectiveSafetySettings.map((setting) => setting.toJson()).toList();
    }
  }

  void _applyTools(
    Map<String, dynamic> body,
    List<Tool>? tools,
  ) {
    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = [
        {
          'functionDeclarations': effectiveTools
              .map((tool) => messageCodec.convertTool(tool))
              .toList(),
        },
      ];

      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_config'] = messageCodec.convertToolChoice(
          effectiveToolChoice,
          effectiveTools,
        );
      }
    }
  }

  void _applyWebSearch(Map<String, dynamic> body) {
    if (config.webSearchEnabled) {
      body['tools'] ??= [];
      body['tools'].add({'google_search': {}});
    }
  }
}
