import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/openai/config.dart';
import 'client.dart';
import 'config_views.dart';
import 'openai_tool_choice_codec.dart';
import 'request_body_support.dart';

/// Owns Responses-API-specific request and endpoint shaping while keeping the
/// public `OpenAIResponses` capability as a thin orchestration facade.
class OpenAIResponsesRequestBuilder {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIResponsesRequestBuilder({
    required this.client,
    required this.config,
  });

  String get responsesEndpoint => 'responses';

  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools, {
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
      allTools.addAll(effectiveTools.map(convertToolToResponsesFormat));
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
        body['tool_choice'] = const OpenAIToolChoiceCodec().toJson(
          effectiveToolChoice,
        );
      }
    }

    return body;
  }

  OpenAIResponsesRequestBuilder forPreviousResponseId(
    String previousResponseId,
  ) {
    return OpenAIResponsesRequestBuilder(
      client: client,
      config: config.copyWith(previousResponseId: previousResponseId),
    );
  }

  String buildGetResponseEndpoint(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) {
    return _appendQueryParameters(
      'responses/$responseId',
      {
        if (include != null && include.isNotEmpty) 'include': include.join(','),
        if (startingAfter != null) 'starting_after': startingAfter.toString(),
        if (stream) 'stream': stream.toString(),
      },
    );
  }

  String buildDeleteResponseEndpoint(String responseId) {
    return 'responses/$responseId';
  }

  String buildCancelResponseEndpoint(String responseId) {
    return 'responses/$responseId/cancel';
  }

  String buildListInputItemsEndpoint(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) {
    return _appendQueryParameters(
      'responses/$responseId/input_items',
      {
        'limit': limit.toString(),
        'order': order,
        if (after != null) 'after': after,
        if (before != null) 'before': before,
        if (include != null && include.isNotEmpty) 'include': include.join(','),
      },
    );
  }

  Map<String, dynamic> convertToolToResponsesFormat(Tool tool) {
    return {
      'type': 'function',
      'name': tool.function.name,
      'description': tool.function.description,
      'parameters': tool.function.parameters.toJson(),
    };
  }

  String _appendQueryParameters(
    String endpoint,
    Map<String, String> queryParameters,
  ) {
    if (queryParameters.isEmpty) {
      return endpoint;
    }

    final queryString = queryParameters.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');

    return '$endpoint?$queryString';
  }
}
