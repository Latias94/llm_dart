import '../../../../models/moderation_models.dart';
import 'openai_moderation_models.dart';

export 'openai_moderation_models.dart';

/// Local request shaping and analysis support for the OpenAI moderation shell.
///
/// This keeps deterministic moderation helpers separate from raw endpoint
/// orchestration while preserving the public compatibility surface.
final class OpenAIModerationSupport {
  const OpenAIModerationSupport();

  Map<String, dynamic> buildRequestBody(ModerationRequest request) {
    return <String, dynamic>{
      'input': request.input,
      if (request.model != null) 'model': request.model,
    };
  }

  ModerationAnalysis buildAnalysis({
    required String text,
    required ModerationResult result,
  }) {
    final categoriesMap = categoriesToMap(result.categories);
    final scoresMap = categoryScoresToMap(result.categoryScores);

    return ModerationAnalysis(
      text: text,
      flagged: result.flagged,
      categories: categoriesMap,
      categoryScores: scoresMap,
      highestRiskCategory: highestRiskCategory(scoresMap),
      riskLevel: calculateRiskLevel(scoresMap),
      recommendations: generateRecommendations(
        result: result,
        categories: categoriesMap,
      ),
    );
  }

  List<ModerationAnalysis> buildAnalyses(
    List<String> texts,
    List<ModerationResult> results,
  ) {
    return results.asMap().entries.map((entry) {
      final index = entry.key;
      final result = entry.value;
      return buildAnalysis(
        text: texts[index],
        result: result,
      );
    }).toList();
  }

  String? highestRiskCategory(Map<String, double> categoryScores) {
    if (categoryScores.isEmpty) {
      return null;
    }

    return categoryScores.entries
        .reduce((left, right) => left.value > right.value ? left : right)
        .key;
  }

  String calculateRiskLevel(Map<String, double> categoryScores) {
    if (categoryScores.isEmpty) {
      return 'unknown';
    }

    final maxScore = categoryScores.values.reduce(
      (left, right) => left > right ? left : right,
    );

    if (maxScore >= 0.8) {
      return 'high';
    }
    if (maxScore >= 0.5) {
      return 'medium';
    }
    if (maxScore >= 0.2) {
      return 'low';
    }
    return 'minimal';
  }

  List<String> generateRecommendations({
    required ModerationResult result,
    Map<String, bool>? categories,
  }) {
    final recommendations = <String>[];
    if (!result.flagged) {
      recommendations.add('Content appears safe for use.');
      return recommendations;
    }

    final categoriesMap = categories ?? categoriesToMap(result.categories);
    for (final category in categoriesMap.keys) {
      if (categoriesMap[category] == true) {
        switch (category) {
          case 'hate':
            recommendations.add('Remove or modify hate speech content.');
            break;
          case 'harassment':
            recommendations.add('Remove harassing language.');
            break;
          case 'self-harm':
            recommendations.add('Remove self-harm related content.');
            break;
          case 'sexual':
            recommendations.add('Remove sexual content.');
            break;
          case 'violence':
            recommendations.add('Remove violent content.');
            break;
          default:
            recommendations.add(
              'Review and modify flagged content in category: $category',
            );
        }
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Content was flagged but no specific recommendations available.',
      );
    }

    return recommendations;
  }

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

  List<String> filterSafeContent(
    List<String> texts,
    List<ModerationResult> results,
  ) {
    final safeTexts = <String>[];
    for (var index = 0; index < texts.length; index++) {
      if (!results[index].flagged) {
        safeTexts.add(texts[index]);
      }
    }

    return safeTexts;
  }

  ModerationStats buildStats(
    List<String> texts,
    List<ModerationResult> results,
  ) {
    final flaggedCount = results.where((result) => result.flagged).length;
    final categoryStats = <String, int>{};

    for (final result in results) {
      final categoriesMap = categoriesToMap(result.categories);
      for (final category in categoriesMap.keys) {
        if (categoriesMap[category] == true) {
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        }
      }
    }

    final totalTexts = texts.length;
    final flaggedPercentage =
        totalTexts == 0 ? 0.0 : (flaggedCount / totalTexts) * 100;

    return ModerationStats(
      totalTexts: totalTexts,
      flaggedTexts: flaggedCount,
      safeTexts: totalTexts - flaggedCount,
      flaggedPercentage: flaggedPercentage,
      categoryBreakdown: categoryStats,
      mostCommonViolation: mostCommonViolation(categoryStats),
    );
  }

  String mostCommonViolation(Map<String, int> categoryStats) {
    if (categoryStats.isEmpty) {
      return 'none';
    }

    return categoryStats.entries
        .reduce((left, right) => left.value > right.value ? left : right)
        .key;
  }
}
