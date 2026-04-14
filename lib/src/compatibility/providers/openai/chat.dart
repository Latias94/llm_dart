import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../utils/reasoning_utils.dart';
import 'client.dart';
import 'chat_request_builder.dart';
import 'chat_stream_parser.dart';
import 'openai_chat_response.dart';
import '../../../../providers/openai/config.dart';
import 'stream_facade_support.dart';

export 'openai_chat_response.dart' show OpenAIChatResponse;

/// OpenAI Chat capability implementation
///
/// This module handles all chat-related functionality for OpenAI providers,
/// including streaming, tool calling, and reasoning model support.
class OpenAIChat implements ChatCapability {
  final OpenAIClient client;
  final OpenAIConfig config;
  late final OpenAIChatRequestBuilder _requestBuilder;
  late final OpenAIChatStreamParser _streamParser;

  OpenAIChat(this.client, this.config) {
    _requestBuilder = OpenAIChatRequestBuilder(
      client: client,
      config: config,
    );
    _streamParser = OpenAIChatStreamParser(
      client: client,
      model: config.model,
    );
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
    );
    final responseData = await client.postJson(
      _requestBuilder.chatEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
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
    );

    yield* runOpenAICompatibilityStream(
      client: client,
      endpoint: _requestBuilder.chatEndpoint,
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

  /// Parse non-streaming response
  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    return OpenAIChatResponse.fromResponseData(
      responseData,
      model: config.model,
    );
  }
}
