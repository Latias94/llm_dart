import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'output_spec_foundation.dart';
import 'output_spec_json.dart';
import 'output_spec_strategy.dart';

void validateOutputRunnerOptions({
  required GenerateTextOptions options,
  required String runnerName,
}) {
  if (options.responseFormat != null) {
    throw ArgumentError(
      '$runnerName uses OutputSpec.responseFormat and does not allow GenerateTextOptions.responseFormat at the same time.',
    );
  }
}

GenerateTextOptions withOutputResponseFormat(
  GenerateTextOptions options,
  ResponseFormat? responseFormat,
) {
  return GenerateTextOptions(
    maxOutputTokens: options.maxOutputTokens,
    temperature: options.temperature,
    stopSequences: options.stopSequences,
    topP: options.topP,
    topK: options.topK,
    presencePenalty: options.presencePenalty,
    frequencyPenalty: options.frequencyPenalty,
    seed: options.seed,
    reasoning: options.reasoning,
    includeRawChunks: options.includeRawChunks,
    responseFormat: responseFormat,
  );
}

StructuredOutputContext createStructuredOutputContext(
  GenerateTextResult result,
) {
  return StructuredOutputContext(
    responseMetadata: result.responseMetadata,
    responseId: result.responseId,
    responseTimestamp: result.responseTimestamp,
    responseModelId: result.responseModelId,
    finishReason: result.finishReason,
    rawFinishReason: result.rawFinishReason,
    usage: result.usage,
    providerMetadata: result.providerMetadata,
  );
}

Future<GenerateOutputResult<T>> parseGenerateOutputResult<T>({
  required GenerateTextResult result,
  required OutputSpec<T> outputSpec,
  required StructuredOutputContext context,
}) async {
  try {
    final output = await outputSpec.parse(
      text: result.text,
      context: context,
    );
    return GenerateOutputResult(
      result: result,
      output: output,
    );
  } catch (error) {
    throw modelErrorFrom(
      error,
      kind: ModelErrorKind.validation,
      details: structuredOutputErrorDetails(
        text: result.text,
        context: context,
      ),
    );
  }
}

Map<String, Object?> structuredOutputErrorDetails({
  required String text,
  required StructuredOutputContext context,
}) {
  return {
    'stage': 'structured_output',
    'text': text,
    if (context.responseId != null) 'responseId': context.responseId,
    if (context.responseTimestamp != null)
      'responseTimestamp': context.responseTimestamp!.toIso8601String(),
    if (context.responseModelId != null)
      'responseModelId': context.responseModelId,
    'finishReason': context.finishReason.name,
    if (context.rawFinishReason != null)
      'rawFinishReason': context.rawFinishReason,
    if (context.usage != null)
      'usage': structuredOutputUsageToJson(context.usage!),
    if (context.providerMetadata != null)
      'providerMetadata': context.providerMetadata!.toJsonMap(),
  };
}
