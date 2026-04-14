import 'dart:convert';

import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/ollama/client.dart';
import '../../../../providers/ollama/config.dart';

class OllamaChatRequestBuilder {
  final OllamaClient client;
  final OllamaConfig config;

  OllamaChatRequestBuilder({
    required this.client,
    required this.config,
  });

  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final chatMessages = <Map<String, dynamic>>[];

    if (config.systemPrompt != null) {
      chatMessages.add({'role': 'system', 'content': config.systemPrompt});
    }

    for (final message in messages) {
      chatMessages.add(_convertMessage(message));
    }

    final body = <String, dynamic>{
      'model': config.model,
      'messages': chatMessages,
      'stream': stream,
      'keep_alive': config.keepAlive ?? '5m',
    };

    final options = <String, dynamic>{};
    if (config.temperature != null) options['temperature'] = config.temperature;
    if (config.topP != null) options['top_p'] = config.topP;
    if (config.topK != null) options['top_k'] = config.topK;
    if (config.maxTokens != null) options['num_predict'] = config.maxTokens;
    if (config.numCtx != null) options['num_ctx'] = config.numCtx;
    if (config.numGpu != null) options['num_gpu'] = config.numGpu;
    if (config.numThread != null) options['num_thread'] = config.numThread;
    if (config.numa != null) options['numa'] = config.numa;
    if (config.numBatch != null) options['num_batch'] = config.numBatch;
    if (options.isNotEmpty) {
      body['options'] = options;
    }

    if (config.raw == true) {
      body['raw'] = true;
    }

    if (config.jsonSchema?.schema != null) {
      body['format'] = config.jsonSchema!.schema;
    }

    final effectiveTools = tools ?? config.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map(_convertTool).toList();
    }

    if (config.reasoning != null) {
      body['think'] = config.reasoning;
    }

    return body;
  }

  Map<String, dynamic> _convertMessage(ChatMessage message) {
    final result = <String, dynamic>{
      'role': message.role.name,
    };

    if (message.name != null) {
      result['name'] = message.name;
    }

    switch (message.messageType) {
      case TextMessage():
        result['content'] = message.content;
        break;
      case ImageMessage(mime: final _, data: final data):
        result['content'] = message.content;
        result['images'] = [base64Encode(data)];
        break;
      case ImageUrlMessage(url: final url):
        result['content'] = message.content;
        client.logger
            .warning('Image URLs not directly supported by Ollama: $url');
        break;
      case ToolUseMessage(toolCalls: final toolCalls):
        result['content'] = message.content;
        result['tool_calls'] = toolCalls
            .map((toolCall) => {
                  'function': {
                    'name': toolCall.function.name,
                    'arguments': jsonDecode(toolCall.function.arguments),
                  }
                })
            .toList();
        break;
      case ToolResultMessage():
        result['content'] = message.content;
        break;
      default:
        result['content'] = message.content;
    }

    return result;
  }

  Map<String, dynamic> _convertTool(Tool tool) {
    final propertiesJson = <String, dynamic>{};
    for (final entry in tool.function.parameters.properties.entries) {
      propertiesJson[entry.key] = entry.value.toJson();
    }

    return {
      'type': 'function',
      'function': {
        'name': tool.function.name,
        'description': tool.function.description,
        'parameters': {
          'type': tool.function.parameters.schemaType,
          'properties': propertiesJson,
          'required': tool.function.parameters.required,
        },
      },
    };
  }
}
