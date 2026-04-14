import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';
import 'google_chat_message_codec.dart';

/// Request-shaping support for the Google compatibility chat shell.
class GoogleChatRequestBuilder {
  final GoogleClient client;
  final GoogleConfig config;
  late final GoogleChatMessageCodec _messageCodec;

  GoogleChatRequestBuilder({
    required this.client,
    required this.config,
  }) {
    _messageCodec = GoogleChatMessageCodec(
      client: client,
      config: config,
    );
  }

  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final contents = <Map<String, dynamic>>[];

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
      contents.add(_messageCodec.convertMessage(message));
    }

    return _buildBodyWithConfig(contents, tools, stream: stream);
  }

  Map<String, dynamic> _buildBodyWithConfig(
    List<Map<String, dynamic>> contents,
    List<Tool>? tools, {
    required bool stream,
  }) {
    final body = <String, dynamic>{'contents': contents};
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

    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    final effectiveSafetySettings =
        config.safetySettings ?? GoogleConfig.defaultSafetySettings;
    if (effectiveSafetySettings.isNotEmpty) {
      body['safetySettings'] =
          effectiveSafetySettings.map((setting) => setting.toJson()).toList();
    }

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = [
        {
          'functionDeclarations': effectiveTools
              .map((tool) => _messageCodec.convertTool(tool))
              .toList(),
        },
      ];

      final effectiveToolChoice = config.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_config'] = _messageCodec.convertToolChoice(
          effectiveToolChoice,
          effectiveTools,
        );
      }
    }

    if (config.getExtension<bool>('webSearchEnabled') == true) {
      body['tools'] ??= [];
      body['tools'].add({'google_search': {}});
    }

    return body;
  }
}
