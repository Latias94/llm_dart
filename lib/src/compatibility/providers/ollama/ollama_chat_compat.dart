import 'package:llm_dart_transport/dio.dart';

import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/ollama/client.dart';
import '../../../../providers/ollama/config.dart';
import '../../http/dio_error_handler.dart';
import 'ollama_chat_request_builder.dart';
import 'ollama_chat_response.dart';
import 'ollama_chat_stream_parser.dart';

export 'ollama_chat_response.dart' show OllamaChatResponse;

/// Compatibility-oriented Ollama chat capability implementation.
///
/// This remains in the root package because it serves the broader legacy shell
/// rather than the package-owned modern Ollama model surface.
class OllamaChat implements ChatCapability {
  final OllamaClient client;
  final OllamaConfig config;
  late final OllamaChatRequestBuilder _requestBuilder;
  late final OllamaChatStreamParser _streamParser;

  OllamaChat(this.client, this.config) {
    _requestBuilder = OllamaChatRequestBuilder(client: client, config: config);
    _streamParser = OllamaChatStreamParser(client: client);
  }

  String get chatEndpoint => '/api/chat';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    if (config.baseUrl.isEmpty) {
      throw const InvalidRequestError('Missing Ollama base URL');
    }

    try {
      final requestBody =
          _requestBuilder.buildRequestBody(messages, tools, false);
      final responseData = await client.postJson(
        chatEndpoint,
        requestBody,
        cancelToken: cancelToken,
      );
      return OllamaChatResponse(responseData);
    } on DioException catch (e) {
      throw await DioErrorHandler.handleDioError(e, 'Ollama');
    } catch (e) {
      throw GenericError('Unexpected error: $e');
    }
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    if (config.baseUrl.isEmpty) {
      yield ErrorEvent(const InvalidRequestError('Missing Ollama base URL'));
      return;
    }

    try {
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
    } catch (e) {
      yield ErrorEvent(GenericError('Unexpected error: $e'));
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
}
