import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_language_model_request.dart';
import 'anthropic_language_model_response.dart';
import 'anthropic_language_model_stream.dart';
import 'anthropic_language_model_token_count.dart';
import 'anthropic_language_model_transport.dart';
import 'anthropic_model_describer.dart';
import 'anthropic_options.dart';
import 'anthropic_token_count.dart';

final class AnthropicLanguageModel
    implements LanguageModel, CapabilityDescribedModel {
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
  Future<GenerateTextResult> doGenerate(GenerateTextRequest request) async {
    final preparedRequest = encodeAnthropicLanguageModelMessagesRequest(
      modelId: modelId,
      request: request,
      settings: settings,
      stream: false,
    );

    final response = await transport.send(
      buildAnthropicLanguageModelTransportRequest(
        baseUrl: baseUrl,
        route: AnthropicLanguageModelRoute.messages,
        callOptions: request.callOptions,
        stream: false,
        body: preparedRequest.body,
        apiKey: apiKey,
        settings: settings,
        requestBetas: preparedRequest.betaFeatures,
      ),
    );

    return decodeAnthropicLanguageModelGenerateResponse(
      body: response.body,
      warnings: preparedRequest.warnings,
    );
  }

  @override
  Stream<LanguageModelStreamEvent> doStream(
      GenerateTextRequest request) async* {
    final preparedRequest = encodeAnthropicLanguageModelMessagesRequest(
      modelId: modelId,
      request: request,
      settings: settings,
      stream: true,
    );

    yield StartEvent(warnings: preparedRequest.warnings);

    try {
      final response = await transport.sendStream(
        buildAnthropicLanguageModelTransportRequest(
          baseUrl: baseUrl,
          route: AnthropicLanguageModelRoute.messages,
          callOptions: request.callOptions,
          stream: true,
          body: preparedRequest.body,
          apiKey: apiKey,
          settings: settings,
          requestBetas: preparedRequest.betaFeatures,
        ),
      );

      yield* decodeAnthropicLanguageModelStreamEvents(
        stream: response.stream,
        includeRawChunks: request.options.includeRawChunks,
      );
    } catch (error) {
      yield ErrorEvent(transportErrorToModelError(error));
    }
  }

  Future<AnthropicTokenCountResult> countTokens(
    AnthropicTokenCountRequest request,
  ) async {
    final preparedRequest = encodeAnthropicLanguageModelTokenCountRequest(
      modelId: modelId,
      settings: settings,
      request: request,
    );

    final response = await transport.send(
      buildAnthropicLanguageModelTransportRequest(
        baseUrl: baseUrl,
        route: AnthropicLanguageModelRoute.countTokens,
        callOptions: request.callOptions,
        stream: false,
        body: preparedRequest.body,
        apiKey: apiKey,
        settings: settings,
        requestBetas: preparedRequest.betaFeatures,
      ),
    );

    return decodeAnthropicLanguageModelTokenCountResponse(
      body: response.body,
      warnings: preparedRequest.warnings,
    );
  }
}
