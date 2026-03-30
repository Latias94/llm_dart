import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_messages_codec.dart';
import 'anthropic_options.dart';
import 'anthropic_result_codec.dart';
import 'anthropic_stream_codec.dart';

final class AnthropicLanguageModel implements LanguageModel {
  static const AnthropicMessagesCodec _messagesCodec = AnthropicMessagesCodec();
  static const AnthropicMessagesResultCodec _resultCodec =
      AnthropicMessagesResultCodec();
  static const AnthropicStreamCodec _streamCodec = AnthropicStreamCodec();
  static const String _providerId = 'anthropic';

  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final AnthropicChatModelSettings settings;

  @override
  final String modelId;

  AnthropicLanguageModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    this.settings = const AnthropicChatModelSettings(),
  }) : baseUrl = baseUrl ?? anthropicDefaultBaseUrl;

  @override
  String get providerId => _providerId;

  Uri get messagesUri => resolveAnthropicUri(baseUrl, 'messages');

  @override
  Future<GenerateTextResult> generate(GenerateTextRequest request) async {
    final providerOptions = _resolveProviderOptions(
      request.callOptions.providerOptions,
    );
    final preparedRequest = _messagesCodec.encodeRequest(
      modelId: modelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      settings: settings,
      providerOptions: providerOptions,
      stream: false,
    );

    final response = await transport.send(
      TransportRequest(
        uri: messagesUri,
        method: TransportMethod.post,
        headers: _buildRequestHeaders(
          stream: false,
          requestBetas: preparedRequest.betaFeatures,
          extraHeaders: request.callOptions.headers,
        ),
        body: preparedRequest.body,
        timeout: request.callOptions.timeout,
        responseType: TransportResponseType.json,
      ),
    );

    return _resultCodec.decodeResponse(
      decodeAnthropicJsonObject(response.body),
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<TextStreamEvent> stream(GenerateTextRequest request) async* {
    final providerOptions = _resolveProviderOptions(
      request.callOptions.providerOptions,
    );
    final preparedRequest = _messagesCodec.encodeRequest(
      modelId: modelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      settings: settings,
      providerOptions: providerOptions,
      stream: true,
    );

    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        TransportRequest(
          uri: messagesUri,
          method: TransportMethod.post,
          headers: _buildRequestHeaders(
            stream: true,
            requestBetas: preparedRequest.betaFeatures,
            extraHeaders: request.callOptions.headers,
          ),
          body: preparedRequest.body,
          timeout: request.callOptions.timeout,
        ),
      );

      final state = AnthropicMessagesStreamState();
      final decoder = const DefaultSseDecoder();
      final chunks = utf8.decoder.bind(response.stream);

      await for (final frame in decoder.decode(chunks)) {
        if (frame.data.isEmpty || frame.data == '[DONE]') {
          continue;
        }

        for (final event in _streamCodec.decodeChunk(
          decodeAnthropicJsonObject(frame.data),
          state,
        )) {
          yield event;
        }
      }
    } catch (error) {
      yield ErrorEvent(error);
    }
  }

  AnthropicGenerateTextOptions _resolveProviderOptions(
    ProviderInvocationOptions? options,
  ) {
    if (options == null) {
      return const AnthropicGenerateTextOptions();
    }

    if (options is AnthropicGenerateTextOptions) {
      return options;
    }

    throw ArgumentError.value(
      options,
      'providerOptions',
      'Expected AnthropicGenerateTextOptions for Anthropic language models.',
    );
  }

  Map<String, String> _buildRequestHeaders({
    required bool stream,
    required List<String> requestBetas,
    Map<String, String>? extraHeaders,
  }) {
    return buildAnthropicHeaders(
      apiKey: apiKey,
      anthropicVersion: settings.anthropicVersion,
      defaultHeaders: settings.headers,
      extraHeaders: extraHeaders,
      betaFeatures: [
        ...settings.betaFeatures,
        ...requestBetas,
      ],
      accept: stream ? 'text/event-stream' : 'application/json',
      includeJsonContentType: true,
    );
  }
}
