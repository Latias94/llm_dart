import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../reasoning_utils.dart';
import 'client.dart';
import 'openai_responses_response.dart';
import 'openai_responses_models.dart';
import 'responses_request_builder.dart';

/// Provider-local support for non-streaming OpenAI Responses API operations.
///
/// This keeps lifecycle, background, and stateful-conversation orchestration
/// out of the main `OpenAIResponses` shell so that shell can stay focused on
/// chat facade behavior and streaming.
class OpenAIResponsesSupport {
  final OpenAIClient client;
  final OpenAIResponsesRequestBuilder requestBuilder;

  OpenAIResponsesSupport({
    required this.client,
    required this.requestBuilder,
  });

  Future<ChatResponse> createResponse(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    required bool background,
    TransportCancellation? cancelToken,
  }) async {
    final requestBody = requestBuilder.buildRequestBody(
      messages,
      tools,
      stream: false,
      background: background,
    );
    final responseData = await client.postJson(
      requestBuilder.responsesEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
    return parseResponse(responseData);
  }

  Future<ChatResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) async {
    final endpoint = requestBuilder.buildGetResponseEndpoint(
      responseId,
      include: include,
      startingAfter: startingAfter,
      stream: stream,
    );
    final responseData = await client.get(endpoint);
    return parseResponse(responseData);
  }

  Future<bool> deleteResponse(String responseId) async {
    try {
      final endpoint = requestBuilder.buildDeleteResponseEndpoint(responseId);
      final responseData = await client.delete(endpoint);
      return responseData['deleted'] == true;
    } on LLMError {
      rethrow;
    } catch (error) {
      client.logger.warning('Failed to delete response $responseId: $error');
      throw OpenAIResponsesError(
        'Failed to delete response: $error',
        responseId: responseId,
        errorType: 'deletion_failed',
      );
    }
  }

  Future<ChatResponse> cancelResponse(String responseId) async {
    final endpoint = requestBuilder.buildCancelResponseEndpoint(responseId);
    final responseData = await client.postJson(endpoint, {});
    return parseResponse(responseData);
  }

  Future<ResponseInputItemsList> listInputItems(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) async {
    final endpoint = requestBuilder.buildListInputItemsEndpoint(
      responseId,
      after: after,
      before: before,
      include: include,
      limit: limit,
      order: order,
    );
    final responseData = await client.get(endpoint);
    return ResponseInputItemsList.fromJson(responseData);
  }

  Future<ChatResponse> continueConversation(
    String previousResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) async {
    final continuationBuilder =
        requestBuilder.forPreviousResponseId(previousResponseId);
    final requestBody = continuationBuilder.buildRequestBody(
      newMessages,
      tools,
      stream: false,
      background: background,
    );
    final responseData = await client.postJson(
      continuationBuilder.responsesEndpoint,
      requestBody,
    );
    return parseResponse(responseData);
  }

  Future<ChatResponse> forkConversation(
    String fromResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) {
    return continueConversation(
      fromResponseId,
      newMessages,
      tools: tools,
      background: background,
    );
  }

  String buildSummaryPrompt(List<ChatMessage> messages) {
    return 'Summarize in 2-3 sentences:\n'
        '${messages.map((message) => '${message.role.name}: ${message.content}').join('\n')}';
  }

  String extractSummaryText(ChatResponse response) {
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }

    return CompatReasoningUtils.filterThinkingContent(text);
  }

  ChatResponse parseResponse(Map<String, dynamic> responseData) {
    return OpenAIResponsesResponse.fromResponseData(responseData);
  }
}
