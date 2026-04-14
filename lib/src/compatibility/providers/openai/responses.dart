import 'dart:async';

import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/responses_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../utils/reasoning_utils.dart';
import 'client.dart';
import '../../../../providers/openai/config.dart';
import 'openai_responses_response.dart';
import 'responses_capability.dart';
import 'responses_request_builder.dart';
import 'responses_stream_parser.dart';

export 'openai_responses_response.dart' show OpenAIResponsesResponse;

/// OpenAI Responses API capability implementation
///
/// This module handles the new Responses API which combines the simplicity
/// of Chat Completions with the tool-use capabilities of the Assistants API.
/// It supports built-in tools like web search, file search, and computer use.
class OpenAIResponses implements ChatCapability, OpenAIResponsesCapability {
  final OpenAIClient client;
  final OpenAIConfig config;
  late final OpenAIResponsesRequestBuilder _requestBuilder;
  late final OpenAIResponsesStreamParser _streamParser;

  OpenAIResponses(this.client, this.config) {
    _requestBuilder = OpenAIResponsesRequestBuilder(
      client: client,
      config: config,
    );
    _streamParser = OpenAIResponsesStreamParser(client);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    final requestBody = _requestBuilder.buildRequestBody(
      messages,
      tools,
      stream: false,
      background: false,
    );
    final responseData = await client.postJson(
      _requestBuilder.responsesEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
    return _parseResponse(responseData);
  }

  /// Create a response with background processing
  ///
  /// When background=true, the response will be processed asynchronously.
  /// You can retrieve the result later using getResponse() or cancel it with cancelResponse().
  @override
  Future<ChatResponse> chatWithToolsBackground(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) async {
    final requestBody = _requestBuilder.buildRequestBody(
      messages,
      tools,
      stream: false,
      background: true,
    );
    final responseData =
        await client.postJson(_requestBuilder.responsesEndpoint, requestBody);
    return _parseResponse(responseData);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    final effectiveTools = tools ?? config.tools;
    final requestBody = _requestBuilder.buildRequestBody(
      messages,
      effectiveTools,
      stream: true,
      background: false,
    );

    _streamParser.reset();

    try {
      final stream = client.postStreamRaw(
        _requestBuilder.responsesEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );

      await for (final chunk in stream) {
        try {
          final events = _streamParser.parseChunk(chunk);
          for (final event in events) {
            yield event;
          }
        } catch (e) {
          // Log parsing errors but continue processing
          client.logger.warning('Failed to parse stream chunk: $e');
        }
      }
    } catch (e) {
      // Handle stream creation or connection errors
      if (e is LLMError) {
        rethrow;
      } else {
        throw GenericError('Stream error: $e');
      }
    }
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final request = [ChatMessage.user(prompt)];
    final response = await chat(request);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }

    // Filter out thinking content for reasoning models
    return ReasoningUtils.filterThinkingContent(text);
  }

  // ========== Responses API CRUD Operations ==========

  /// Retrieve a model response by ID
  ///
  /// This allows you to fetch a previously created response using its ID.
  /// Useful for stateful conversations and response chaining.
  @override
  Future<ChatResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) async {
    final endpoint = _requestBuilder.buildGetResponseEndpoint(
      responseId,
      include: include,
      startingAfter: startingAfter,
      stream: stream,
    );
    final responseData = await client.get(endpoint);
    return _parseResponse(responseData);
  }

  /// Delete a model response by ID
  ///
  /// Permanently removes a stored response from OpenAI's servers.
  /// Returns true if deletion was successful.
  @override
  Future<bool> deleteResponse(String responseId) async {
    try {
      final endpoint = _requestBuilder.buildDeleteResponseEndpoint(responseId);
      final responseData = await client.delete(endpoint);
      return responseData['deleted'] == true;
    } on LLMError {
      rethrow;
    } catch (e) {
      client.logger.warning('Failed to delete response $responseId: $e');
      throw OpenAIResponsesError(
        'Failed to delete response: $e',
        responseId: responseId,
        errorType: 'deletion_failed',
      );
    }
  }

  /// Cancel a background response by ID
  ///
  /// Only responses created with background=true can be cancelled.
  /// Returns the cancelled response object.
  @override
  Future<ChatResponse> cancelResponse(String responseId) async {
    final endpoint = _requestBuilder.buildCancelResponseEndpoint(responseId);
    final responseData = await client.postJson(endpoint, {});
    return _parseResponse(responseData);
  }

  /// List input items for a response
  ///
  /// Returns the input items that were used to generate a specific response.
  /// Useful for debugging and understanding response context.
  @override
  Future<ResponseInputItemsList> listInputItems(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) async {
    final endpoint = _requestBuilder.buildListInputItemsEndpoint(
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

  // ========== Conversation State Management ==========

  /// Create a new response that continues from a previous response
  ///
  /// This enables stateful conversations where the provider maintains
  /// the conversation history automatically.
  @override
  Future<ChatResponse> continueConversation(
    String previousResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) async {
    final requestBuilder =
        _requestBuilder.forPreviousResponseId(previousResponseId);
    final requestBody = requestBuilder.buildRequestBody(
      newMessages,
      tools,
      stream: false,
      background: background,
    );
    final responseData =
        await client.postJson(requestBuilder.responsesEndpoint, requestBody);
    return _parseResponse(responseData);
  }

  /// Fork a conversation from a specific response
  ///
  /// Creates a new conversation branch starting from the specified response.
  /// Useful for exploring different conversation paths.
  @override
  Future<ChatResponse> forkConversation(
    String fromResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) async {
    // Fork is the same as continue for OpenAI Responses API
    return continueConversation(fromResponseId, newMessages,
        tools: tools, background: background);
  }

  /// Parse non-streaming response
  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    return OpenAIResponsesResponse.fromResponseData(responseData);
  }
}
