import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../provider/openai_family_profile.dart';
import 'openai_moderation_options.dart';

final class OpenAIModerationTransportSupport {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final OpenAIModerationSettings settings;

  const OpenAIModerationTransportSupport({
    required this.apiKey,
    required this.baseUrl,
    required this.profile,
    required this.settings,
  });

  Uri get moderationUri => Uri.parse('$baseUrl/moderations');

  TransportRequest moderationRequest({
    required Map<String, Object?> body,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? extraHeaders,
  }) {
    return TransportRequest(
      uri: moderationUri,
      method: TransportMethod.post,
      headers: buildHeaders(extraHeaders: extraHeaders),
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      responseType: TransportResponseType.json,
    );
  }

  Map<String, String> buildHeaders({
    Map<String, String>? extraHeaders,
  }) {
    return profile.buildHeaders(
      apiKey: apiKey,
      extraHeaders: {
        if (settings.organization case final organization?)
          'openai-organization': organization,
        if (settings.project case final project?) 'openai-project': project,
        ...settings.headers,
        'content-type': 'application/json',
        'accept': 'application/json',
        if (extraHeaders != null) ...extraHeaders,
      },
    );
  }
}
