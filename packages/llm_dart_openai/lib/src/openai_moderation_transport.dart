import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
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
    required Object input,
    String? model,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? extraHeaders,
  }) {
    return TransportRequest(
      uri: moderationUri,
      method: TransportMethod.post,
      headers: buildHeaders(extraHeaders: extraHeaders),
      body: {
        'input': normalizeInput(input),
        if (resolveModel(model) case final resolvedModel?)
          'model': resolvedModel,
      },
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

  String? resolveModel(String? model) {
    if (model != null) {
      return model;
    }

    return settings.defaultModel;
  }

  Object normalizeInput(Object input) {
    if (input is String) {
      return input;
    }

    if (input is List<String>) {
      return List<String>.unmodifiable(input);
    }

    if (input is List) {
      return List<String>.generate(
        input.length,
        (index) {
          final value = input[index];
          if (value is! String) {
            throw ArgumentError.value(
              input,
              'input',
              'Expected moderation input to be a String or List<String>.',
            );
          }
          return value;
        },
        growable: false,
      );
    }

    throw ArgumentError.value(
      input,
      'input',
      'Expected moderation input to be a String or List<String>.',
    );
  }
}
