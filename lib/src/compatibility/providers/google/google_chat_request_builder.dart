import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';
import 'google_chat_message_codec.dart';

/// Request-shaping support for the Google compatibility chat shell.
class GoogleChatRequestBuilder {
  final GoogleClient client;
  final GoogleConfig config;

  GoogleChatRequestBuilder({
    required this.client,
    required this.config,
  });

  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final contents = _buildContents(messages);
    final body = <String, dynamic>{'contents': contents};
    final generationConfig = _buildGenerationConfig(stream: stream);
    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    _applySafetySettings(body);
    _applyTools(body, tools);
    _applyWebSearch(body, config.webSearchEnabled);

    return body;
  }

  List<Map<String, dynamic>> _buildContents(List<ChatMessage> messages) {
    final contents = <Map<String, dynamic>>[];
    final messageCodec = GoogleChatMessageCodec(
      client: client,
      config: config,
    );

    if (config.systemPrompt != null) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': config.systemPrompt},
        ],
      });
    }

    for (final message in messages) {
      if (message.role == ChatRole.system) continue;
      contents.add(messageCodec.convertMessage(message));
    }

    return contents;
  }

  Map<String, dynamic> _buildGenerationConfig({required bool stream}) {
    final generationConfig = <String, dynamic>{};

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

    if (config.jsonSchema != null && config.jsonSchema!.schema != null) {
      generationConfig['responseMimeType'] = 'application/json';

      final schema = Map<String, dynamic>.from(config.jsonSchema!.schema!);
      schema.remove('additionalProperties');
      generationConfig['responseSchema'] = schema;
    }

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

    if (config.enableImageGeneration == true) {
      if (config.responseModalities != null) {
        generationConfig['responseModalities'] = config.responseModalities;
      } else {
        generationConfig['responseModalities'] = ['TEXT', 'IMAGE'];
      }
      generationConfig['responseMimeType'] = 'text/plain';
    }

    return generationConfig;
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
    final messageCodec = GoogleChatMessageCodec(
      client: client,
      config: config,
    );
    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = <Map<String, dynamic>>[
        <String, dynamic>{
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

  void _applyWebSearch(
    Map<String, dynamic> body,
    bool enabled,
  ) {
    if (!enabled) {
      return;
    }

    final tools = body['tools'];
    if (tools is List) {
      tools.add(
        <String, dynamic>{
          'google_search': <String, Object?>{},
        },
      );
    } else {
      body['tools'] = [
        <String, dynamic>{
          'google_search': <String, Object?>{},
        },
      ];
    }
  }
}
