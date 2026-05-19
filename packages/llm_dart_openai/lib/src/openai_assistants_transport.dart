import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_models.dart';
import 'openai_family_profile.dart';
import 'openai_non_text_model_support.dart';

final class OpenAIAssistantsSettings {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIAssistantsSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIAssistantsTransportSupport {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final OpenAIAssistantsSettings settings;

  const OpenAIAssistantsTransportSupport({
    required this.apiKey,
    required this.baseUrl,
    required this.profile,
    required this.settings,
  });

  Uri assistantsUri([OpenAIListAssistantsQuery? query]) {
    final uri = Uri.parse('$baseUrl/assistants');
    final queryParameters = query?.toQueryParameters() ?? const {};
    if (queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParameters);
  }

  Uri assistantUri(String assistantId) {
    return Uri.parse(
      '$baseUrl/assistants/${Uri.encodeComponent(requireAssistantId(
        assistantId,
        parameterName: 'assistantId',
      ))}',
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

  String requireAssistantId(
    String value, {
    required String parameterName,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        parameterName,
        'Expected a non-empty OpenAI assistant ID.',
      );
    }
    return normalized;
  }
}
