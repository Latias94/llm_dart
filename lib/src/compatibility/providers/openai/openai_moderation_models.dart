part of 'openai_moderation_support.dart';

/// Extended moderation analysis result.
class ModerationAnalysis {
  final String text;
  final bool flagged;
  final Map<String, bool> categories;
  final Map<String, double> categoryScores;
  final String? highestRiskCategory;
  final String riskLevel;
  final List<String> recommendations;

  const ModerationAnalysis({
    required this.text,
    required this.flagged,
    required this.categories,
    required this.categoryScores,
    this.highestRiskCategory,
    required this.riskLevel,
    required this.recommendations,
  });

  @override
  String toString() {
    return 'ModerationAnalysis('
        'flagged: $flagged, '
        'riskLevel: $riskLevel, '
        'highestRisk: $highestRiskCategory'
        ')';
  }
}

/// Moderation statistics for a batch of texts.
class ModerationStats {
  final int totalTexts;
  final int flaggedTexts;
  final int safeTexts;
  final double flaggedPercentage;
  final Map<String, int> categoryBreakdown;
  final String mostCommonViolation;

  const ModerationStats({
    required this.totalTexts,
    required this.flaggedTexts,
    required this.safeTexts,
    required this.flaggedPercentage,
    required this.categoryBreakdown,
    required this.mostCommonViolation,
  });

  @override
  String toString() {
    return 'ModerationStats('
        'total: $totalTexts, '
        'flagged: $flaggedTexts (${flaggedPercentage.toStringAsFixed(1)}%), '
        'mostCommon: $mostCommonViolation'
        ')';
  }
}
