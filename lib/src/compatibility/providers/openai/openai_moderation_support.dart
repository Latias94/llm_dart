import '../../../../models/moderation_models.dart';

part 'openai_moderation_analysis_support.dart';
part 'openai_moderation_batch_support.dart';
part 'openai_moderation_models.dart';

/// Local request shaping and analysis support for the OpenAI moderation shell.
///
/// This keeps deterministic moderation helpers separate from raw endpoint
/// orchestration while preserving the public compatibility surface.
final class OpenAIModerationSupport
    with _OpenAIModerationAnalysisSupport, _OpenAIModerationBatchSupport {
  const OpenAIModerationSupport();

  Map<String, dynamic> buildRequestBody(ModerationRequest request) {
    return <String, dynamic>{
      'input': request.input,
      if (request.model != null) 'model': request.model,
    };
  }
}
