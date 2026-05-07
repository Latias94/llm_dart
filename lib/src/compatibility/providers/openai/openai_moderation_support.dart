import '../../../../models/moderation_models.dart';

part 'openai_moderation_analysis_support.dart';
part 'openai_moderation_batch_support.dart';
part 'openai_moderation_category_support.dart';
part 'openai_moderation_models.dart';
part 'openai_moderation_request_support.dart';

/// Local request shaping and analysis support for the OpenAI moderation shell.
///
/// This keeps deterministic moderation helpers separate from raw endpoint
/// orchestration while preserving the public compatibility surface.
final class OpenAIModerationSupport {
  static const _requestSupport = _OpenAIModerationRequestSupport();
  static const _categorySupport = _OpenAIModerationCategorySupport();
  static const _analysisSupport = _OpenAIModerationAnalysisSupport();
  static const _batchSupport = _OpenAIModerationBatchSupport();

  const OpenAIModerationSupport();

  Map<String, dynamic> buildRequestBody(ModerationRequest request) {
    return _requestSupport.buildRequestBody(request);
  }

  ModerationAnalysis buildAnalysis({
    required String text,
    required ModerationResult result,
  }) {
    return _analysisSupport.buildAnalysis(
      text: text,
      result: result,
    );
  }

  List<ModerationAnalysis> buildAnalyses(
    List<String> texts,
    List<ModerationResult> results,
  ) {
    return _analysisSupport.buildAnalyses(texts, results);
  }

  String? highestRiskCategory(Map<String, double> categoryScores) {
    return _analysisSupport.highestRiskCategory(categoryScores);
  }

  String calculateRiskLevel(Map<String, double> categoryScores) {
    return _analysisSupport.calculateRiskLevel(categoryScores);
  }

  List<String> generateRecommendations({
    required ModerationResult result,
    Map<String, bool>? categories,
  }) {
    return _analysisSupport.generateRecommendations(
      result: result,
      categories: categories,
    );
  }

  Map<String, bool> categoriesToMap(ModerationCategories categories) {
    return _categorySupport.categoriesToMap(categories);
  }

  Map<String, double> categoryScoresToMap(
    ModerationCategoryScores scores,
  ) {
    return _categorySupport.categoryScoresToMap(scores);
  }

  List<String> filterSafeContent(
    List<String> texts,
    List<ModerationResult> results,
  ) {
    return _batchSupport.filterSafeContent(texts, results);
  }

  ModerationStats buildStats(
    List<String> texts,
    List<ModerationResult> results,
  ) {
    return _batchSupport.buildStats(texts, results);
  }

  String mostCommonViolation(Map<String, int> categoryStats) {
    return _batchSupport.mostCommonViolation(categoryStats);
  }
}
