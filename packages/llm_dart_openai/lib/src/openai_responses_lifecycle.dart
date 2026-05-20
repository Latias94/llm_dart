import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_profile_boundary.dart';
import 'openai_responses_lifecycle_client_support.dart';
import 'openai_responses_lifecycle_models.dart';
import 'openai_responses_lifecycle_transport.dart';

export 'openai_responses_lifecycle_models.dart'
    show
        OpenAIRawResponse,
        OpenAIResponseDeleteResult,
        OpenAIResponseInputItem,
        OpenAIResponseInputItemsList;
export 'openai_responses_lifecycle_transport.dart'
    show OpenAIResponsesLifecycleSettings;

final class OpenAIResponsesLifecycleClient {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIResponsesLifecycleSettings settings;

  late final OpenAIResponsesLifecycleTransportSupport _requestSupport =
      OpenAIResponsesLifecycleTransportSupport(
    apiKey: apiKey,
    baseUrl: baseUrl,
    profile: profile,
    settings: settings,
  );

  OpenAIResponsesLifecycleClient({
    required this.apiKey,
    required this.profile,
    required this.transport,
    this.settings = const OpenAIResponsesLifecycleSettings(),
    String? baseUrl,
  }) : baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile) {
    requireOpenAIProfile(
      profile,
      featureName: 'OpenAI Responses lifecycle client',
    );
  }

  Uri get responsesUri => _requestSupport.responsesUri;

  Uri responseUri(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) {
    return _requestSupport.responseUri(
      responseId,
      include: include,
      startingAfter: startingAfter,
      stream: stream,
    );
  }

  Uri cancelResponseUri(String responseId) {
    return _requestSupport.cancelResponseUri(responseId);
  }

  Uri inputItemsUri(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) {
    return _requestSupport.inputItemsUri(
      responseId,
      after: after,
      before: before,
      include: include,
      limit: limit,
      order: order,
    );
  }

  Future<OpenAIRawResponse> createResponse(
    Map<String, Object?> body, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return sendOpenAIResponsesLifecycleJsonModel(
      transport: transport,
      requestSupport: _requestSupport,
      uri: responsesUri,
      method: TransportMethod.post,
      responseName: 'Responses create response',
      decode: (json) => OpenAIRawResponse.fromJson(json),
      contentType: true,
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIRawResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return sendOpenAIResponsesLifecycleJsonModel(
      transport: transport,
      requestSupport: _requestSupport,
      uri: responseUri(
        responseId,
        include: include,
        startingAfter: startingAfter,
        stream: stream,
      ),
      method: TransportMethod.get,
      responseName: 'Responses retrieve response',
      decode: (json) => OpenAIRawResponse.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIResponseDeleteResult> deleteResponse(
    String responseId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return sendOpenAIResponsesLifecycleJsonModel(
      transport: transport,
      requestSupport: _requestSupport,
      uri: responseUri(responseId),
      method: TransportMethod.delete,
      responseName: 'Responses delete response',
      decode: (json) => OpenAIResponseDeleteResult.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIRawResponse> cancelResponse(
    String responseId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return sendOpenAIResponsesLifecycleJsonModel(
      transport: transport,
      requestSupport: _requestSupport,
      uri: cancelResponseUri(responseId),
      method: TransportMethod.post,
      responseName: 'Responses cancel response',
      decode: (json) => OpenAIRawResponse.fromJson(json),
      contentType: true,
      body: const <String, Object?>{},
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIResponseInputItemsList> listInputItems(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return sendOpenAIResponsesLifecycleJsonModel(
      transport: transport,
      requestSupport: _requestSupport,
      uri: inputItemsUri(
        responseId,
        after: after,
        before: before,
        include: include,
        limit: limit,
        order: order,
      ),
      method: TransportMethod.get,
      responseName: 'Responses input items response',
      decode: (json) => OpenAIResponseInputItemsList.fromJson(json),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIRawResponse> continueConversation(
    String previousResponseId,
    Map<String, Object?> body, {
    bool? background,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return createResponse(
      {
        ...body,
        'previous_response_id': _requestSupport.requireResponseId(
          previousResponseId,
          parameterName: 'previousResponseId',
        ),
        if (background != null) 'background': background,
      },
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIRawResponse> forkConversation(
    String fromResponseId,
    Map<String, Object?> body, {
    bool? background,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return continueConversation(
      fromResponseId,
      body,
      background: background,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }
}
