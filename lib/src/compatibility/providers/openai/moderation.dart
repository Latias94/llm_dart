import '../../../../core/capability.dart';
import '../../../../models/moderation_models.dart';
import '../../../../providers/openai/config.dart';
import 'client.dart';
import 'openai_moderation_support.dart';

export 'openai_moderation_support.dart'
    show ModerationAnalysis, ModerationStats;

/// OpenAI Content Moderation capability implementation.
///
/// This module handles moderation endpoint orchestration for OpenAI providers
/// while delegating local analysis helpers to provider-local support.
class OpenAIModeration implements ModerationCapability {
  final OpenAIClient client;
  final OpenAIConfig config;
  final OpenAIModerationSupport _support = const OpenAIModerationSupport();

  OpenAIModeration(this.client, this.config);

  @override
  Future<ModerationResponse> moderate(ModerationRequest request) async {
    final requestBody = _support.buildRequestBody(request);
    final responseData = await client.postJson('moderations', requestBody);
    return ModerationResponse.fromJson(responseData);
  }

  /// Moderate a single text input.
  Future<ModerationResult> moderateText(String text, {String? model}) async {
    final response = await moderate(ModerationRequest(
      input: [text],
      model: model,
    ));

    return response.results.first;
  }

  /// Moderate multiple text inputs.
  Future<List<ModerationResult>> moderateTexts(
    List<String> texts, {
    String? model,
  }) async {
    final response = await moderate(ModerationRequest(
      input: texts,
      model: model,
    ));

    return response.results;
  }

  /// Check if text is safe.
  Future<bool> isTextSafe(String text, {String? model}) async {
    final result = await moderateText(text, model: model);
    return !result.flagged;
  }

  /// Check if any text in the list is unsafe.
  Future<bool> hasUnsafeContent(List<String> texts, {String? model}) async {
    final results = await moderateTexts(texts, model: model);
    return results.any((result) => result.flagged);
  }

  /// Get detailed moderation analysis.
  Future<ModerationAnalysis> analyzeContent(
    String text, {
    String? model,
  }) async {
    final result = await moderateText(text, model: model);
    return _support.buildAnalysis(
      text: text,
      result: result,
    );
  }

  /// Batch analyze multiple texts.
  Future<List<ModerationAnalysis>> analyzeMultipleContents(
    List<String> texts, {
    String? model,
  }) async {
    final results = await moderateTexts(texts, model: model);
    return _support.buildAnalyses(texts, results);
  }

  /// Filter out unsafe content from a list.
  Future<List<String>> filterSafeContent(
    List<String> texts, {
    String? model,
  }) async {
    final results = await moderateTexts(texts, model: model);
    return _support.filterSafeContent(texts, results);
  }

  /// Get moderation statistics for a batch of texts.
  Future<ModerationStats> getModerationStats(
    List<String> texts, {
    String? model,
  }) async {
    final results = await moderateTexts(texts, model: model);
    return _support.buildStats(texts, results);
  }
}
