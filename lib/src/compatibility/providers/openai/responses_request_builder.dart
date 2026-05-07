import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/openai/config.dart';
import 'client.dart';
import 'config_views.dart';
import 'request_body_support.dart';

part 'responses_request_builder_body.dart';
part 'responses_request_builder_endpoints.dart';
part 'responses_request_builder_tools.dart';

/// Owns Responses-API-specific request and endpoint shaping while keeping the
/// public `OpenAIResponses` capability as a thin orchestration facade.
class OpenAIResponsesRequestBuilder {
  static const _bodySupport = _OpenAIResponsesRequestBodySupport();
  static const _endpointSupport = _OpenAIResponsesEndpointSupport();

  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIResponsesRequestBuilder({
    required this.client,
    required this.config,
  });

  String get responsesEndpoint => _endpointSupport.responsesEndpoint;

  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    required bool stream,
    required bool background,
  }) {
    return _bodySupport.buildRequestBody(
      client: client,
      config: config,
      messages: messages,
      tools: tools,
      stream: stream,
      background: background,
    );
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
    return _endpointSupport.buildGetResponseEndpoint(
      responseId,
      include: include,
      startingAfter: startingAfter,
      stream: stream,
    );
  }

  String buildDeleteResponseEndpoint(String responseId) {
    return _endpointSupport.buildDeleteResponseEndpoint(responseId);
  }

  String buildCancelResponseEndpoint(String responseId) {
    return _endpointSupport.buildCancelResponseEndpoint(responseId);
  }

  String buildListInputItemsEndpoint(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) {
    return _endpointSupport.buildListInputItemsEndpoint(
      responseId,
      after: after,
      before: before,
      include: include,
      limit: limit,
      order: order,
    );
  }
}
