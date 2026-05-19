import 'openai_json_support.dart';
import 'openai_json_value.dart';

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
      hate: openAIRequiredBool(json['hate'], path: 'categories.hate'),
      hateThreatening: openAIRequiredBool(
        json['hate/threatening'],
        path: 'categories.hate/threatening',
      ),
      harassment: openAIRequiredBool(
        json['harassment'],
        path: 'categories.harassment',
      ),
      harassmentThreatening: openAIRequiredBool(
        json['harassment/threatening'],
        path: 'categories.harassment/threatening',
      ),
      selfHarm: openAIRequiredBool(
        json['self-harm'],
        path: 'categories.self-harm',
      ),
      selfHarmIntent: openAIRequiredBool(
        json['self-harm/intent'],
        path: 'categories.self-harm/intent',
      ),
      selfHarmInstructions: openAIRequiredBool(
        json['self-harm/instructions'],
        path: 'categories.self-harm/instructions',
      ),
      sexual: openAIRequiredBool(json['sexual'], path: 'categories.sexual'),
      sexualMinors: openAIRequiredBool(
        json['sexual/minors'],
        path: 'categories.sexual/minors',
      ),
      violence: openAIRequiredBool(
        json['violence'],
        path: 'categories.violence',
      ),
      violenceGraphic: openAIRequiredBool(
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
      hate: openAIRequiredDouble(json['hate'], path: 'category_scores.hate'),
      hateThreatening: openAIRequiredDouble(
        json['hate/threatening'],
        path: 'category_scores.hate/threatening',
      ),
      harassment: openAIRequiredDouble(
        json['harassment'],
        path: 'category_scores.harassment',
      ),
      harassmentThreatening: openAIRequiredDouble(
        json['harassment/threatening'],
        path: 'category_scores.harassment/threatening',
      ),
      selfHarm: openAIRequiredDouble(
        json['self-harm'],
        path: 'category_scores.self-harm',
      ),
      selfHarmIntent: openAIRequiredDouble(
        json['self-harm/intent'],
        path: 'category_scores.self-harm/intent',
      ),
      selfHarmInstructions: openAIRequiredDouble(
        json['self-harm/instructions'],
        path: 'category_scores.self-harm/instructions',
      ),
      sexual: openAIRequiredDouble(
        json['sexual'],
        path: 'category_scores.sexual',
      ),
      sexualMinors: openAIRequiredDouble(
        json['sexual/minors'],
        path: 'category_scores.sexual/minors',
      ),
      violence: openAIRequiredDouble(
        json['violence'],
        path: 'category_scores.violence',
      ),
      violenceGraphic: openAIRequiredDouble(
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
      flagged: openAIRequiredBool(json['flagged'], path: 'result.flagged'),
      categories: OpenAIModerationCategories.fromJson(
        openAIRequiredMap(json['categories'], path: 'result.categories'),
      ),
      categoryScores: OpenAIModerationCategoryScores.fromJson(
        openAIRequiredMap(
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
      id: openAIRequiredNonEmptyString(json['id'], path: 'response.id'),
      model:
          openAIRequiredNonEmptyString(json['model'], path: 'response.model'),
      results: openAIRequiredList(
        json['results'],
        path: 'response.results',
      ).asMap().entries.map((entry) {
        return OpenAIModerationResult.fromJson(
          openAIRequiredMap(
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

OpenAIModerationResponse decodeOpenAIModerationResponse(Object? body) {
  return OpenAIModerationResponse.fromJson(
    decodeOpenAIJsonObject(
      body,
      responseName: 'moderation',
    ),
  );
}
