import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_grounding_projection.dart';
import 'google_provider_metadata_support.dart';
import 'google_result_part_projection.dart';
import 'google_shared.dart';

final class GoogleGenerateContentResultCodec {
  const GoogleGenerateContentResultCodec();

  GenerateTextResult decodeResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    final responseId = asString(response['responseId']);
    final responseModelId = asString(response['modelVersion']);
    final promptFeedback = asMap(response['promptFeedback']);
    final usageMetadata = asMap(response['usageMetadata']);
    final candidates = asList(response['candidates']);
    final candidate = candidates.isEmpty ? null : asMap(candidates.first);
    final content = <ContentPart>[];
    var hasClientToolCalls = false;

    if (candidate != null) {
      final candidateContent = asMap(candidate['content']);
      final parts = asList(candidateContent?['parts']);
      final partProjection =
          GoogleGenerateContentResultPartProjector().project(parts);
      content.addAll(partProjection.content);
      hasClientToolCalls = partProjection.hasClientToolCalls;

      for (final sourcePart in projectGoogleGroundingContentParts(
        asMap(candidate['groundingMetadata']),
      )) {
        content.add(sourcePart);
      }
    }

    final rawFinishReason = asString(candidate?['finishReason']) ??
        asString(promptFeedback?['blockReason']);

    return GenerateTextResult(
      content: content,
      finishReason: mapGoogleFinishReason(
        rawFinishReason,
        hasClientToolCalls: hasClientToolCalls,
      ),
      rawFinishReason: rawFinishReason,
      responseMetadata: ModelResponseMetadata(
        id: responseId,
        modelId: responseModelId,
      ),
      usage: decodeGoogleUsage(usageMetadata),
      providerMetadata: buildGoogleGenerationMetadata(
        promptFeedback: promptFeedback,
        groundingMetadata: asMap(candidate?['groundingMetadata']),
        urlContextMetadata: asMap(candidate?['urlContextMetadata']),
        safetyRatings: asList(candidate?['safetyRatings']),
        usageMetadata: usageMetadata,
        finishMessage: asString(candidate?['finishMessage']),
      ),
      warnings: warnings,
    );
  }
}
