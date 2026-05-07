part of 'openai_moderation_support.dart';

final class _OpenAIModerationAnalysisSupport {
  static const _categorySupport = _OpenAIModerationCategorySupport();

  const _OpenAIModerationAnalysisSupport();

  ModerationAnalysis buildAnalysis({
    required String text,
    required ModerationResult result,
  }) {
    final categoriesMap = _categorySupport.categoriesToMap(result.categories);
    final scoresMap =
        _categorySupport.categoryScoresToMap(result.categoryScores);

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

    final categoriesMap =
        categories ?? _categorySupport.categoriesToMap(result.categories);
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
}
