import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_profile_boundary.dart';

final class OpenAIModerationSettings {
  final String? defaultModel;
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIModerationSettings({
    this.defaultModel,
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIModerationCategories {
  final bool hate;
  final bool hateThreatening;
  final bool harassment;
  final bool harassmentThreatening;
  final bool selfHarm;
  final bool selfHarmIntent;
  final bool selfHarmInstructions;
  final bool sexual;
  final bool sexualMinors;
  final bool violence;
  final bool violenceGraphic;

  const OpenAIModerationCategories({
    required this.hate,
    required this.hateThreatening,
    required this.harassment,
    required this.harassmentThreatening,
    required this.selfHarm,
    required this.selfHarmIntent,
    required this.selfHarmInstructions,
    required this.sexual,
    required this.sexualMinors,
    required this.violence,
    required this.violenceGraphic,
  });

  factory OpenAIModerationCategories.fromJson(Map<String, Object?> json) {
    return OpenAIModerationCategories(
      hate: _requiredBool(json['hate'], path: 'categories.hate'),
      hateThreatening: _requiredBool(
        json['hate/threatening'],
        path: 'categories.hate/threatening',
      ),
      harassment: _requiredBool(
        json['harassment'],
        path: 'categories.harassment',
      ),
      harassmentThreatening: _requiredBool(
        json['harassment/threatening'],
        path: 'categories.harassment/threatening',
      ),
      selfHarm: _requiredBool(
        json['self-harm'],
        path: 'categories.self-harm',
      ),
      selfHarmIntent: _requiredBool(
        json['self-harm/intent'],
        path: 'categories.self-harm/intent',
      ),
      selfHarmInstructions: _requiredBool(
        json['self-harm/instructions'],
        path: 'categories.self-harm/instructions',
      ),
      sexual: _requiredBool(json['sexual'], path: 'categories.sexual'),
      sexualMinors: _requiredBool(
        json['sexual/minors'],
        path: 'categories.sexual/minors',
      ),
      violence: _requiredBool(
        json['violence'],
        path: 'categories.violence',
      ),
      violenceGraphic: _requiredBool(
        json['violence/graphic'],
        path: 'categories.violence/graphic',
      ),
    );
  }

  Map<String, bool> toJson() {
    return {
      'hate': hate,
      'hate/threatening': hateThreatening,
      'harassment': harassment,
      'harassment/threatening': harassmentThreatening,
      'self-harm': selfHarm,
      'self-harm/intent': selfHarmIntent,
      'self-harm/instructions': selfHarmInstructions,
      'sexual': sexual,
      'sexual/minors': sexualMinors,
      'violence': violence,
      'violence/graphic': violenceGraphic,
    };
  }

  Iterable<String> get flaggedCategories sync* {
    for (final entry in toJson().entries) {
      if (entry.value) {
        yield entry.key;
      }
    }
  }
}

final class OpenAIModerationCategoryScores {
  final double hate;
  final double hateThreatening;
  final double harassment;
  final double harassmentThreatening;
  final double selfHarm;
  final double selfHarmIntent;
  final double selfHarmInstructions;
  final double sexual;
  final double sexualMinors;
  final double violence;
  final double violenceGraphic;

  const OpenAIModerationCategoryScores({
    required this.hate,
    required this.hateThreatening,
    required this.harassment,
    required this.harassmentThreatening,
    required this.selfHarm,
    required this.selfHarmIntent,
    required this.selfHarmInstructions,
    required this.sexual,
    required this.sexualMinors,
    required this.violence,
    required this.violenceGraphic,
  });

  factory OpenAIModerationCategoryScores.fromJson(Map<String, Object?> json) {
    return OpenAIModerationCategoryScores(
      hate: _requiredDouble(json['hate'], path: 'category_scores.hate'),
      hateThreatening: _requiredDouble(
        json['hate/threatening'],
        path: 'category_scores.hate/threatening',
      ),
      harassment: _requiredDouble(
        json['harassment'],
        path: 'category_scores.harassment',
      ),
      harassmentThreatening: _requiredDouble(
        json['harassment/threatening'],
        path: 'category_scores.harassment/threatening',
      ),
      selfHarm: _requiredDouble(
        json['self-harm'],
        path: 'category_scores.self-harm',
      ),
      selfHarmIntent: _requiredDouble(
        json['self-harm/intent'],
        path: 'category_scores.self-harm/intent',
      ),
      selfHarmInstructions: _requiredDouble(
        json['self-harm/instructions'],
        path: 'category_scores.self-harm/instructions',
      ),
      sexual: _requiredDouble(
        json['sexual'],
        path: 'category_scores.sexual',
      ),
      sexualMinors: _requiredDouble(
        json['sexual/minors'],
        path: 'category_scores.sexual/minors',
      ),
      violence: _requiredDouble(
        json['violence'],
        path: 'category_scores.violence',
      ),
      violenceGraphic: _requiredDouble(
        json['violence/graphic'],
        path: 'category_scores.violence/graphic',
      ),
    );
  }

  Map<String, double> toJson() {
    return {
      'hate': hate,
      'hate/threatening': hateThreatening,
      'harassment': harassment,
      'harassment/threatening': harassmentThreatening,
      'self-harm': selfHarm,
      'self-harm/intent': selfHarmIntent,
      'self-harm/instructions': selfHarmInstructions,
      'sexual': sexual,
      'sexual/minors': sexualMinors,
      'violence': violence,
      'violence/graphic': violenceGraphic,
    };
  }
}

final class OpenAIModerationResult {
  final bool flagged;
  final OpenAIModerationCategories categories;
  final OpenAIModerationCategoryScores categoryScores;

  const OpenAIModerationResult({
    required this.flagged,
    required this.categories,
    required this.categoryScores,
  });

  factory OpenAIModerationResult.fromJson(Map<String, Object?> json) {
    return OpenAIModerationResult(
      flagged: _requiredBool(json['flagged'], path: 'result.flagged'),
      categories: OpenAIModerationCategories.fromJson(
        _requiredMap(json['categories'], path: 'result.categories'),
      ),
      categoryScores: OpenAIModerationCategoryScores.fromJson(
        _requiredMap(
          json['category_scores'],
          path: 'result.category_scores',
        ),
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'flagged': flagged,
      'categories': categories.toJson(),
      'category_scores': categoryScores.toJson(),
    };
  }
}

final class OpenAIModerationResponse {
  final String id;
  final String model;
  final List<OpenAIModerationResult> results;

  const OpenAIModerationResponse({
    required this.id,
    required this.model,
    required this.results,
  });

  factory OpenAIModerationResponse.fromJson(Map<String, Object?> json) {
    return OpenAIModerationResponse(
      id: _requiredNonEmptyString(json['id'], path: 'response.id'),
      model: _requiredNonEmptyString(json['model'], path: 'response.model'),
      results: _requiredList(
        json['results'],
        path: 'response.results',
      ).asMap().entries.map((entry) {
        return OpenAIModerationResult.fromJson(
          _requiredMap(
            entry.value,
            path: 'response.results[${entry.key}]',
          ),
        );
      }).toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'model': model,
      'results': results.map((result) => result.toJson()).toList(),
    };
  }
}

final class OpenAIModerationClient {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIModerationSettings settings;

  OpenAIModerationClient({
    required this.apiKey,
    required this.profile,
    required this.transport,
    this.settings = const OpenAIModerationSettings(),
    String? baseUrl,
  }) : baseUrl = baseUrl ?? profile.defaultBaseUrl {
    requireOpenAIProfile(profile, featureName: 'OpenAI moderation client');
  }

  Uri get moderationUri => Uri.parse('$baseUrl/moderations');

  Future<OpenAIModerationResponse> moderate(
    Object input, {
    String? model,
    Duration? timeout,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: moderationUri,
        method: TransportMethod.post,
        headers: _buildHeaders(
          extraHeaders: headers,
        ),
        body: {
          'input': _normalizeInput(input),
          if (_resolveModel(model) case final resolvedModel?)
            'model': resolvedModel,
        },
        timeout: timeout,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIModerationResponse.fromJson(
      _decodeJsonObject(response.body),
    );
  }

  Future<OpenAIModerationResult> moderateText(
    String text, {
    String? model,
    Duration? timeout,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await moderate(
      text,
      model: model,
      timeout: timeout,
      cancellation: cancellation,
      headers: headers,
    );
    return response.results.first;
  }

  Future<List<OpenAIModerationResult>> moderateTexts(
    List<String> texts, {
    String? model,
    Duration? timeout,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await moderate(
      List<String>.unmodifiable(texts),
      model: model,
      timeout: timeout,
      cancellation: cancellation,
      headers: headers,
    );
    return response.results;
  }

  Future<bool> isTextSafe(
    String text, {
    String? model,
    Duration? timeout,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final result = await moderateText(
      text,
      model: model,
      timeout: timeout,
      cancellation: cancellation,
      headers: headers,
    );
    return !result.flagged;
  }

  Map<String, String> _buildHeaders({
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

  String? _resolveModel(String? model) {
    if (model != null) {
      return model;
    }

    return settings.defaultModel;
  }
}

Object _normalizeInput(Object input) {
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

Map<String, Object?> _decodeJsonObject(Object? body) {
  if (body is Map<String, Object?>) {
    return body;
  }

  if (body is Map) {
    return Map<String, Object?>.from(body);
  }

  throw StateError(
    'Expected an OpenAI moderation JSON object response but received '
    '${body.runtimeType}.',
  );
}

Map<String, Object?> _requiredMap(
  Object? value, {
  required String path,
}) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  throw FormatException('Expected a JSON object at $path.');
}

List<Object?> _requiredList(
  Object? value, {
  required String path,
}) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  throw FormatException('Expected a list at $path.');
}

String _requiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }

  throw FormatException('Expected a non-empty string at $path.');
}

bool _requiredBool(
  Object? value, {
  required String path,
}) {
  if (value is bool) {
    return value;
  }

  throw FormatException('Expected a bool at $path.');
}

double _requiredDouble(
  Object? value, {
  required String path,
}) {
  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Expected a number at $path.');
}
