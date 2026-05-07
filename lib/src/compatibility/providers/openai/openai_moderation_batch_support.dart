part of 'openai_moderation_support.dart';

final class _OpenAIModerationBatchSupport {
  static const _categorySupport = _OpenAIModerationCategorySupport();

  const _OpenAIModerationBatchSupport();

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
      final categoriesMap = _categorySupport.categoriesToMap(result.categories);
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
