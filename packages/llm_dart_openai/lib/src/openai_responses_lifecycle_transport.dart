import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_non_text_model_support.dart';

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

  Uri get responsesUri => Uri.parse('$baseUrl/responses');

  Uri responseUri(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) {
    return _uriWithQuery(
      '$baseUrl/responses/${Uri.encodeComponent(requireResponseId(
        responseId,
        parameterName: 'responseId',
      ))}',
      {
        if (include != null && include.isNotEmpty) 'include': include.join(','),
        if (startingAfter != null) 'starting_after': '$startingAfter',
        if (stream) 'stream': '$stream',
      },
    );
  }

  Uri cancelResponseUri(String responseId) {
    return Uri.parse(
      '$baseUrl/responses/${Uri.encodeComponent(requireResponseId(
        responseId,
        parameterName: 'responseId',
      ))}/cancel',
    );
  }

  Uri inputItemsUri(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) {
    if (limit < 1) {
      throw ArgumentError.value(
        limit,
        'limit',
        'OpenAI response input item list limit must be >= 1.',
      );
    }

    return _uriWithQuery(
      '$baseUrl/responses/${Uri.encodeComponent(requireResponseId(
        responseId,
        parameterName: 'responseId',
      ))}/input_items',
      {
        'limit': '$limit',
        if (order.isNotEmpty) 'order': order,
        if (after != null && after.isNotEmpty) 'after': after,
        if (before != null && before.isNotEmpty) 'before': before,
        if (include != null && include.isNotEmpty) 'include': include.join(','),
      },
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
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        parameterName,
        'Expected a non-empty OpenAI response ID.',
      );
    }
    return normalized;
  }
}

Uri _uriWithQuery(String uri, Map<String, String> queryParameters) {
  final parsed = Uri.parse(uri);
  if (queryParameters.isEmpty) {
    return parsed;
  }
  return parsed.replace(queryParameters: queryParameters);
}
