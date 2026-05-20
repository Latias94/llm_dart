import 'openai_json_support.dart';
import 'openai_json_value.dart';
import 'openai_moderation_category_projection.dart';

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
    final values = OpenAIModerationCategoryValues.fromJson(
      json,
      pathPrefix: 'categories',
      decode: openAIRequiredBool,
    );
    return OpenAIModerationCategories(
      hate: values.hate,
      hateThreatening: values.hateThreatening,
      harassment: values.harassment,
      harassmentThreatening: values.harassmentThreatening,
      selfHarm: values.selfHarm,
      selfHarmIntent: values.selfHarmIntent,
      selfHarmInstructions: values.selfHarmInstructions,
      sexual: values.sexual,
      sexualMinors: values.sexualMinors,
      violence: values.violence,
      violenceGraphic: values.violenceGraphic,
    );
  }

  Map<String, bool> toJson() {
    return openAIModerationCategoryJson(
      hate: hate,
      hateThreatening: hateThreatening,
      harassment: harassment,
      harassmentThreatening: harassmentThreatening,
      selfHarm: selfHarm,
      selfHarmIntent: selfHarmIntent,
      selfHarmInstructions: selfHarmInstructions,
      sexual: sexual,
      sexualMinors: sexualMinors,
      violence: violence,
      violenceGraphic: violenceGraphic,
    );
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
    final values = OpenAIModerationCategoryValues.fromJson(
      json,
      pathPrefix: 'category_scores',
      decode: openAIRequiredDouble,
    );
    return OpenAIModerationCategoryScores(
      hate: values.hate,
      hateThreatening: values.hateThreatening,
      harassment: values.harassment,
      harassmentThreatening: values.harassmentThreatening,
      selfHarm: values.selfHarm,
      selfHarmIntent: values.selfHarmIntent,
      selfHarmInstructions: values.selfHarmInstructions,
      sexual: values.sexual,
      sexualMinors: values.sexualMinors,
      violence: values.violence,
      violenceGraphic: values.violenceGraphic,
    );
  }

  Map<String, double> toJson() {
    return openAIModerationCategoryJson(
      hate: hate,
      hateThreatening: hateThreatening,
      harassment: harassment,
      harassmentThreatening: harassmentThreatening,
      selfHarm: selfHarm,
      selfHarmIntent: selfHarmIntent,
      selfHarmInstructions: selfHarmInstructions,
      sexual: sexual,
      sexualMinors: sexualMinors,
      violence: violence,
      violenceGraphic: violenceGraphic,
    );
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
