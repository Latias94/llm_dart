import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/anthropic/config.dart';
import 'anthropic_chat_response.dart';
import 'anthropic_chat_stream_parser.dart';
import 'client.dart';
import 'request_builder.dart';

export 'anthropic_chat_response.dart' show AnthropicChatResponse;

/// Anthropic Chat capability implementation.
///
/// This compatibility shell keeps the public legacy surface stable while
/// delegating request shaping and streamed event parsing to focused helpers.
class AnthropicChat implements ChatCapability {
  final AnthropicClient client;
  final AnthropicConfig config;
  late final AnthropicRequestBuilder _requestBuilder;
  late final AnthropicChatStreamParser _streamParser;

  AnthropicChat(this.client, this.config) {
    _requestBuilder = AnthropicRequestBuilder(config);
    _streamParser = AnthropicChatStreamParser(client: client);
  }

  String get chatEndpoint => 'messages';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    final requestBody =
        _requestBuilder.buildRequestBody(messages, tools, false);
    final responseData = await client.postJson(
      chatEndpoint,
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
    _streamParser.reset();

    final effectiveTools = tools ?? config.tools;
    final requestBody =
        _requestBuilder.buildRequestBody(messages, effectiveTools, true);

    final stream = client.postStreamRaw(
      chatEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );

    await for (final chunk in stream) {
      final events = _streamParser.parseChunk(chunk);
      for (final event in events) {
        yield event;
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
    return text;
  }

  /// Count tokens in messages using Anthropic's token counting API.
  Future<int> countTokens(
    List<ChatMessage> messages, {
    List<Tool>? tools,
  }) async {
    final requestBody = _requestBuilder.buildTokenCountRequestBody(
      messages,
      tools,
    );

    try {
      final responseData =
          await client.postJson('messages/count_tokens', requestBody);
      return responseData['input_tokens'] as int? ?? 0;
    } catch (e) {
      client.logger.warning('Failed to count tokens: $e');
      final totalChars = messages
          .map((message) => message.content.length)
          .fold(0, (a, b) => a + b);
      return (totalChars / 4).ceil();
    }
  }

  ChatResponse _parseResponse(Map<String, dynamic> responseData) {
    return AnthropicChatResponse(responseData);
  }
}
