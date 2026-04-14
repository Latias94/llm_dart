import '../../../../core/capability.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/responses_models.dart';
import '../../../../models/tool_models.dart';
import 'client.dart';
import '../../../../providers/openai/config.dart';
import 'openai_responses_support.dart';
import 'responses_capability.dart';
import 'responses_request_builder.dart';
import 'responses_stream_parser.dart';
import 'stream_facade_support.dart';

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
  late final OpenAIResponsesSupport _support;

  OpenAIResponses(this.client, this.config) {
    _requestBuilder = OpenAIResponsesRequestBuilder(
      client: client,
      config: config,
    );
    _streamParser = OpenAIResponsesStreamParser(client);
    _support = OpenAIResponsesSupport(
      client: client,
      requestBuilder: _requestBuilder,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return _support.createResponse(
      messages,
      tools,
      background: false,
      cancelToken: cancelToken,
    );
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
    return _support.createResponse(
      messages,
      tools,
      background: true,
    );
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

    yield* runOpenAICompatibilityStream(
      client: client,
      endpoint: _requestBuilder.responsesEndpoint,
      requestBody: requestBody,
      resetParser: _streamParser.reset,
      parseChunk: _streamParser.parseChunk,
      cancelToken: cancelToken,
    );
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
    final request = [
      ChatMessage.user(_support.buildSummaryPrompt(messages)),
    ];
    final response = await chat(request);
    return _support.extractSummaryText(response);
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
    return _support.getResponse(
      responseId,
      include: include,
      startingAfter: startingAfter,
      stream: stream,
    );
  }

  /// Delete a model response by ID
  ///
  /// Permanently removes a stored response from OpenAI's servers.
  /// Returns true if deletion was successful.
  @override
  Future<bool> deleteResponse(String responseId) async {
    return _support.deleteResponse(responseId);
  }

  /// Cancel a background response by ID
  ///
  /// Only responses created with background=true can be cancelled.
  /// Returns the cancelled response object.
  @override
  Future<ChatResponse> cancelResponse(String responseId) async {
    return _support.cancelResponse(responseId);
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
    return _support.listInputItems(
      responseId,
      after: after,
      before: before,
      include: include,
      limit: limit,
      order: order,
    );
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
    return _support.continueConversation(
      previousResponseId,
      newMessages,
      tools: tools,
      background: background,
    );
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
    return _support.forkConversation(
      fromResponseId,
      newMessages,
      tools: tools,
      background: background,
    );
  }
}
