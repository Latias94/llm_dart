part of 'openai_moderation_support.dart';

final class _OpenAIModerationCategorySupport {
  const _OpenAIModerationCategorySupport();

  Map<String, bool> categoriesToMap(ModerationCategories categories) {
    return {
      'hate': categories.hate,
      'hate/threatening': categories.hateThreatening,
      'harassment': categories.harassment,
      'harassment/threatening': categories.harassmentThreatening,
      'self-harm': categories.selfHarm,
      'self-harm/intent': categories.selfHarmIntent,
      'self-harm/instructions': categories.selfHarmInstructions,
      'sexual': categories.sexual,
      'sexual/minors': categories.sexualMinors,
      'violence': categories.violence,
      'violence/graphic': categories.violenceGraphic,
    };
  }

  Map<String, double> categoryScoresToMap(
    ModerationCategoryScores scores,
  ) {
    return {
      'hate': scores.hate,
      'hate/threatening': scores.hateThreatening,
      'harassment': scores.harassment,
      'harassment/threatening': scores.harassmentThreatening,
      'self-harm': scores.selfHarm,
      'self-harm/intent': scores.selfHarmIntent,
      'self-harm/instructions': scores.selfHarmInstructions,
      'sexual': scores.sexual,
      'sexual/minors': scores.sexualMinors,
      'violence': scores.violence,
      'violence/graphic': scores.violenceGraphic,
    };
  }
}
