import 'package:llm_dart_core/llm_dart_core.dart';

import '../client/openai_client.dart';
import '../config/openai_config.dart';

/// OpenAI Content Moderation capability implementation
///
/// This module handles content moderation functionality for OpenAI providers.
class OpenAIModeration implements ModerationCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIModeration(this.client, this.config);

  @override
  Future<ModerationResponse> moderate(ModerationRequest request) async {
    final requestBody = <String, dynamic>{
      'input': request.input,
      if (request.model != null) 'model': request.model,
    };

    final responseData = await client.postJson('moderations', requestBody);
    return ModerationResponse.fromJson(responseData);
  }

  Future<ModerationResult> moderateText(String text, {String? model}) async {
    final response = await moderate(
      ModerationRequest(
        input: [text],
        model: model,
      ),
    );

    return response.results.first;
  }

  Future<List<ModerationResult>> moderateTexts(
    List<String> texts, {
    String? model,
  }) async {
    final response = await moderate(
      ModerationRequest(
        input: texts,
        model: model,
      ),
    );

    return response.results;
  }

  Future<bool> isTextSafe(String text, {String? model}) async {
    final result = await moderateText(text, model: model);
    return !result.flagged;
  }

  Future<bool> hasUnsafeContent(
    List<String> texts, {
    String? model,
  }) async {
    final results = await moderateTexts(texts, model: model);
    return results.any((result) => result.flagged);
  }

  Future<ModerationAnalysis> analyzeContent(
    String text, {
    String? model,
  }) async {
    final result = await moderateText(text, model: model);

    final categoriesMap = _categoriesToMap(result.categories);
    final scoresMap = _categoryScoresToMap(result.categoryScores);

    return ModerationAnalysis(
      text: text,
      flagged: result.flagged,
      categories: categoriesMap,
      categoryScores: scoresMap,
      highestRiskCategory: _getHighestRiskCategory(scoresMap),
      riskLevel: _calculateRiskLevel(scoresMap),
      recommendations: _generateRecommendations(result),
    );
  }

  Future<List<ModerationAnalysis>> analyzeMultipleContents(
    List<String> texts, {
    String? model,
  }) async {
    final results = await moderateTexts(texts, model: model);

    return results.asMap().entries.map((entry) {
      final index = entry.key;
      final result = entry.value;

      final categoriesMap = _categoriesToMap(result.categories);
      final scoresMap = _categoryScoresToMap(result.categoryScores);

      return ModerationAnalysis(
        text: texts[index],
        flagged: result.flagged,
        categories: categoriesMap,
        categoryScores: scoresMap,
        highestRiskCategory: _getHighestRiskCategory(scoresMap),
        riskLevel: _calculateRiskLevel(scoresMap),
        recommendations: _generateRecommendations(result),
      );
    }).toList();
  }

  Future<List<String>> filterSafeContent(
    List<String> texts, {
    String? model,
  }) async {
    final results = await moderateTexts(texts, model: model);
    final safeTexts = <String>[];

    for (int i = 0; i < texts.length; i++) {
      if (!results[i].flagged) {
        safeTexts.add(texts[i]);
      }
    }

    return safeTexts;
  }

  Future<ModerationStats> getModerationStats(
    List<String> texts, {
    String? model,
  }) async {
    final results = await moderateTexts(texts, model: model);

    int flaggedCount = 0;
    final categoryStats = <String, int>{};

    for (final result in results) {
      if (result.flagged) {
        flaggedCount++;
      }

      final categoriesMap = _categoriesToMap(result.categories);
      for (final category in categoriesMap.keys) {
        if (categoriesMap[category] == true) {
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        }
      }
    }

    return ModerationStats(
      totalTexts: texts.length,
      flaggedTexts: flaggedCount,
      safeTexts: texts.length - flaggedCount,
      flaggedPercentage: (flaggedCount / texts.length) * 100,
      categoryBreakdown: categoryStats,
      mostCommonViolation:
          categoryStats.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    );
  }

  String? _getHighestRiskCategory(Map<String, double> categoryScores) {
    if (categoryScores.isEmpty) return null;

    return categoryScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String _calculateRiskLevel(Map<String, double> categoryScores) {
    if (categoryScores.isEmpty) return 'unknown';

    final maxScore = categoryScores.values.reduce((a, b) => a > b ? a : b);

    if (maxScore >= 0.8) return 'high';
    if (maxScore >= 0.5) return 'medium';
    if (maxScore >= 0.2) return 'low';
    return 'minimal';
  }

  List<String> _generateRecommendations(ModerationResult result) {
    final recommendations = <String>[];

    if (!result.flagged) {
      recommendations.add('Content appears safe for use.');
      return recommendations;
    }

    final categoriesMap = _categoriesToMap(result.categories);
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

  Map<String, bool> _categoriesToMap(ModerationCategories categories) {
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

  Map<String, double> _categoryScoresToMap(
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
