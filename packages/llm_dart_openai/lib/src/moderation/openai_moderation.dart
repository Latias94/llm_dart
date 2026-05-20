import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../provider/openai_family_profile.dart';
import '../provider/openai_family_url_support.dart';
import 'openai_moderation_body.dart';
import 'openai_moderation_client_support.dart';
import 'openai_moderation_models.dart';
import 'openai_moderation_options.dart';
import 'openai_moderation_transport.dart';
import '../provider/openai_profile_boundary.dart';

export 'openai_moderation_models.dart'
    show
        OpenAIModerationCategories,
        OpenAIModerationCategoryScores,
        OpenAIModerationResponse,
        OpenAIModerationResult;
export 'openai_moderation_options.dart' show OpenAIModerationSettings;

final class OpenAIModerationClient {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIModerationSettings settings;

  late final OpenAIModerationTransportSupport _requestSupport =
      OpenAIModerationTransportSupport(
    apiKey: apiKey,
    baseUrl: baseUrl,
    profile: profile,
    settings: settings,
  );

  OpenAIModerationClient({
    required this.apiKey,
    required this.profile,
    required this.transport,
    this.settings = const OpenAIModerationSettings(),
    String? baseUrl,
  }) : baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile) {
    requireOpenAIProfile(profile, featureName: 'OpenAI moderation client');
  }

  Uri get moderationUri => _requestSupport.moderationUri;

  Future<OpenAIModerationResponse> moderate(
    Object input, {
    String? model,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final body = buildOpenAIModerationRequestBody(
      input: input,
      model: model,
      settings: settings,
    );
    return sendOpenAIModerationRequest(
      transport: transport,
      request: _requestSupport.moderationRequest(
        body: body,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
      ),
    );
  }

  Future<OpenAIModerationResult> moderateText(
    String text, {
    String? model,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await moderate(
      text,
      model: model,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
    return response.results.first;
  }

  Future<List<OpenAIModerationResult>> moderateTexts(
    List<String> texts, {
    String? model,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await moderate(
      List<String>.unmodifiable(texts),
      model: model,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
    return response.results;
  }

  Future<bool> isTextSafe(
    String text, {
    String? model,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final result = await moderateText(
      text,
      model: model,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
    return !result.flagged;
  }
}
