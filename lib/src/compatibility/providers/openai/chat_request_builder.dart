import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/openai/config.dart';
import '../../../../utils/reasoning_utils.dart';
import 'client.dart';
import 'config_views.dart';
import 'openai_tool_choice_codec.dart';
import 'request_body_support.dart';

/// Owns Chat Completions request shaping for the OpenAI compatibility shell.
class OpenAIChatRequestBuilder {
  static const _toolChoiceCodec = OpenAIToolChoiceCodec();

  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIChatRequestBuilder({
    required this.client,
    required this.config,
  });

  String get chatEndpoint => 'chat/completions';

  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    required bool stream,
  }) {
    final requestConfig = config.requestCompat;
    final apiMessages = buildOpenAICompatApiMessages(
      client: client,
      requestConfig: requestConfig,
      messages: messages,
    );

    final body = <String, dynamic>{
      'model': requestConfig.model,
      'messages': apiMessages,
      'stream': stream,
    };

    body.addAll(
      ReasoningUtils.getReasoningEffortParams(
        providerId: client.providerId,
        model: requestConfig.model,
        reasoningEffort: requestConfig.reasoningEffort,
        maxTokens: requestConfig.maxTokens,
      ),
    );

    if (client.providerId == 'openrouter' &&
        requestConfig.model.contains('deepseek-r1')) {
      body['include_reasoning'] = true;
    }

    applyOpenAICompatCommonRequestFields(
      body: body,
      client: client,
      config: config,
      requestConfig: requestConfig,
      includeVerbosity: true,
      flattenExtraBody: true,
    );

    final effectiveTools = tools ?? requestConfig.tools;
    if (effectiveTools != null && effectiveTools.isNotEmpty) {
      body['tools'] = effectiveTools.map((tool) => tool.toJson()).toList();

      final effectiveToolChoice = requestConfig.toolChoice;
      if (effectiveToolChoice != null) {
        body['tool_choice'] = _toolChoiceCodec.toJson(effectiveToolChoice);
      }
    }

    return body;
  }
}
