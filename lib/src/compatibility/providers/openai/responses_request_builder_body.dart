part of 'responses_request_builder.dart';

final class _OpenAIResponsesRequestBodySupport {
  static const _toolSupport = _OpenAIResponsesToolSupport();
  static const _toolChoiceCodec = OpenAIToolChoiceCodec();

  const _OpenAIResponsesRequestBodySupport();

  Map<String, dynamic> buildRequestBody({
    required OpenAIClient client,
    required OpenAIConfig config,
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    required bool stream,
    required bool background,
  }) {
    final requestConfig = config.requestCompat;
    final responsesConfig = config.responsesCompat;
    final apiMessages = buildOpenAICompatApiMessages(
      client: client,
      requestConfig: requestConfig,
      messages: messages,
    );

    final body = <String, dynamic>{
      'model': requestConfig.model,
      'input': apiMessages,
      'stream': stream,
      'background': background,
    };

    if (responsesConfig.previousResponseId != null) {
      body['previous_response_id'] = responsesConfig.previousResponseId;
    }

    if (requestConfig.reasoningEffort != null) {
      body['reasoning'] = {
        'effort': requestConfig.reasoningEffort!.value,
      };
    }

    applyOpenAICompatCommonRequestFields(
      body: body,
      client: client,
      config: config,
      requestConfig: requestConfig,
    );

    final allTools = <Map<String, dynamic>>[];
    final effectiveTools = tools ?? requestConfig.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      allTools.addAll(
        effectiveTools.map(_toolSupport.convertToolToResponsesFormat),
      );
    }

    if (responsesConfig.builtInTools != null &&
        responsesConfig.builtInTools!.isNotEmpty) {
      allTools.addAll(
        responsesConfig.builtInTools!.map((tool) => tool.toJson()),
      );
    }

    if (allTools.isNotEmpty) {
      body['tools'] = allTools;

      final effectiveToolChoice = requestConfig.toolChoice;
      if (effectiveToolChoice != null &&
          effectiveTools != null &&
          effectiveTools.isNotEmpty) {
        body['tool_choice'] = _toolChoiceCodec.toJson(effectiveToolChoice);
      }
    }

    return body;
  }
}
