import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_messages_codec.dart';
import 'anthropic_model_describer.dart';
import 'anthropic_options.dart';
import 'anthropic_result_codec.dart';
import 'anthropic_stream_codec.dart';
import 'anthropic_token_count.dart';

final class AnthropicLanguageModel
    implements LanguageModel, CapabilityDescribedModel {
  static const AnthropicMessagesCodec _messagesCodec = AnthropicMessagesCodec();
  static const AnthropicMessagesResultCodec _resultCodec =
      AnthropicMessagesResultCodec();
  static const AnthropicStreamCodec _streamCodec = AnthropicStreamCodec();
  static const SseJsonChunkParser _streamChunkParser = SseJsonChunkParser();
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

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeAnthropicChatModel(
      modelId,
      settings: settings,
    );
  }

  Uri get messagesUri => resolveAnthropicUri(baseUrl, 'messages');

  Uri get countTokensUri =>
      resolveAnthropicUri(baseUrl, 'messages/count_tokens');

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
        cancellation: request.callOptions.cancellation,
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
          cancellation: request.callOptions.cancellation,
        ),
      );

      final state = AnthropicMessagesStreamState();
      await for (final chunk in _streamChunkParser.parse(response.stream)) {
        for (final event in _streamCodec.decodeChunk(
          chunk,
          state,
        )) {
          yield event;
        }
      }
    } catch (error) {
      yield ErrorEvent(transportErrorToModelError(error));
    }
  }

  Future<AnthropicTokenCountResult> countTokens(
    AnthropicTokenCountRequest request,
  ) async {
    final providerOptions = _resolveProviderOptions(
      request.callOptions.providerOptions,
    );
    final preparedRequest = _messagesCodec.encodeTokenCountRequest(
      modelId: modelId,
      prompt: request.prompt,
      tools: request.tools,
      toolChoice: request.toolChoice,
      settings: settings,
      providerOptions: providerOptions,
    );

    final response = await transport.send(
      TransportRequest(
        uri: countTokensUri,
        method: TransportMethod.post,
        headers: _buildRequestHeaders(
          stream: false,
          requestBetas: preparedRequest.betaFeatures,
          extraHeaders: request.callOptions.headers,
        ),
        body: preparedRequest.body,
        timeout: request.callOptions.timeout,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    final json = decodeAnthropicJsonObject(response.body);
    return AnthropicTokenCountResult(
      inputTokens: _requiredInputTokens(json['input_tokens']),
      warnings: preparedRequest.warnings,
    );
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

  int _requiredInputTokens(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    throw StateError(
      'Expected Anthropic input_tokens to be an int but received ${value.runtimeType}.',
    );
  }
}
