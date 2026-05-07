import 'package:llm_dart_transport/dio.dart';

import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';
import 'google_chat_file_support.dart';
import 'google_chat_request_builder.dart';
import 'google_chat_response.dart';
import 'google_chat_stream_parser.dart';

export 'google_chat_file_support.dart' show GoogleFile;
export 'google_chat_response.dart' show GoogleChatResponse;

part 'google_chat_error_support.dart';

/// Google Chat capability implementation.
///
/// This compatibility shell keeps the public legacy surface stable while
/// delegating request shaping, file upload support, and streamed parsing to
/// narrower local helpers.
class GoogleChat implements ChatCapability {
  final GoogleClient client;
  final GoogleConfig config;
  final _GoogleChatErrorSupport _errorSupport = const _GoogleChatErrorSupport();
  late final GoogleChatFileSupport _fileSupport;
  late final GoogleChatRequestBuilder _requestBuilder;
  late final GoogleChatStreamParser _streamParser;

  GoogleChat(this.client, this.config) {
    _fileSupport = GoogleChatFileSupport(
      client: client,
      config: config,
      errorMapper: _errorSupport.handleDioError,
    );
    _requestBuilder = GoogleChatRequestBuilder(
      client: client,
      config: config,
    );
    _streamParser = GoogleChatStreamParser(client: client);
  }

  String get generateContentEndpoint =>
      'models/${config.model}:generateContent';

  String get streamGenerateContentEndpoint =>
      'models/${config.model}:streamGenerateContent';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    final requestBody =
        _requestBuilder.buildRequestBody(messages, tools, false);
    final responseData = await client.postJson(
      generateContentEndpoint,
      requestBody,
      cancelToken: cancelToken,
    );
    return _errorSupport.parseResponse(responseData);
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
      streamGenerateContentEndpoint,
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

  /// Upload a file to Google AI Files API.
  Future<GoogleFile> uploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) {
    return _fileSupport.uploadFile(
      data: data,
      mimeType: mimeType,
      displayName: displayName,
    );
  }

  /// Get or upload a file, using cache when possible.
  Future<GoogleFile?> getOrUploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) {
    return _fileSupport.getOrUploadFile(
      data: data,
      mimeType: mimeType,
      displayName: displayName,
    );
  }
}
