import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../provider/openai_family_profile.dart';
import '../common/openai_non_text_model_support.dart';
import 'openai_responses_lifecycle_routes.dart';

final class OpenAIResponsesLifecycleSettings {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIResponsesLifecycleSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIResponsesLifecycleTransportSupport {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final OpenAIResponsesLifecycleSettings settings;

  const OpenAIResponsesLifecycleTransportSupport({
    required this.apiKey,
    required this.baseUrl,
    required this.profile,
    required this.settings,
  });

  OpenAIResponsesLifecycleRoutes get _routes {
    return OpenAIResponsesLifecycleRoutes(baseUrl: baseUrl);
  }

  Uri get responsesUri => _routes.responsesUri;

  Uri responseUri(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) {
    return _routes.responseUri(
      responseId,
      include: include,
      startingAfter: startingAfter,
      stream: stream,
    );
  }

  Uri cancelResponseUri(String responseId) {
    return _routes.cancelResponseUri(responseId);
  }

  Uri inputItemsUri(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) {
    return _routes.inputItemsUri(
      responseId,
      after: after,
      before: before,
      include: include,
      limit: limit,
      order: order,
    );
  }

  TransportRequest jsonRequest({
    required Uri uri,
    required TransportMethod method,
    Object? body,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? extraHeaders,
    bool contentType = false,
  }) {
    return TransportRequest(
      uri: uri,
      method: method,
      headers: buildHeaders(
        extraHeaders: extraHeaders,
        contentType: contentType,
      ),
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      responseType: TransportResponseType.json,
    );
  }

  Map<String, String> buildHeaders({
    Map<String, String>? extraHeaders,
    bool contentType = false,
  }) {
    return buildOpenAIFamilyDefaultHeaders(
      profile: profile,
      apiKey: apiKey,
      organization: settings.organization,
      project: settings.project,
      headers: {
        ...settings.headers,
        if (contentType) 'content-type': 'application/json',
        'accept': 'application/json',
        if (extraHeaders != null) ...extraHeaders,
      },
    );
  }

  String requireResponseId(
    String value, {
    required String parameterName,
  }) {
    return _routes.requireResponseId(value, parameterName: parameterName);
  }
}
