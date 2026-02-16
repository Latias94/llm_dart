import 'package:llm_dart_core/llm_dart_core.dart';

import 'types.dart';

/// Embed a single string value (AI SDK-style).
Future<EmbedResult> embed({
  required EmbeddingCapability model,
  required String value,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final result = await embedMany(
    model: model,
    values: [value],
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
  if (result.embeddings.isEmpty) {
    throw const InvalidRequestError('Embedding model returned no embeddings.');
  }
  return EmbedResult(
    value: value,
    embedding: result.embeddings.first,
    usage: result.usage,
    warnings: result.warnings,
    providerMetadata: result.providerMetadata,
    response: result.responses.isEmpty ? null : result.responses.first,
  );
}

/// Embed multiple string values (AI SDK-style).
Future<EmbedManyResult> embedMany({
  required EmbeddingCapability model,
  required List<String> values,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  final EmbeddingResponse response;
  if (effectiveCallOptions.isEmpty) {
    response = await model.embed(values, cancelToken: cancelToken);
  } else {
    if (model is! EmbeddingCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides (headers/body) for embeddings. '
        'Implement `EmbeddingCallOptionsCapability` (or use a provider that does).',
      );
    }

    response =
        await (model as EmbeddingCallOptionsCapability).embedWithCallOptions(
      values,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );
  }

  if (response.embeddings.length != values.length) {
    throw ResponseFormatError(
      'Invalid embedding response: embedding count does not match input count.',
      'expected=${values.length} actual=${response.embeddings.length}',
    );
  }

  final usage = EmbeddingUsage(tokens: response.usage?.tokens ?? 0);
  final responses = response.response == null
      ? const <EmbeddingCallResponse?>[]
      : <EmbeddingCallResponse?>[response.response];

  return EmbedManyResult(
    values: List<String>.unmodifiable(values),
    embeddings: List<List<double>>.unmodifiable(
      response.embeddings.map((e) => List<double>.unmodifiable(e)),
    ),
    usage: usage,
    warnings: List<LLMWarning>.unmodifiable(response.warnings),
    providerMetadata: response.providerMetadata,
    responses: List<EmbeddingCallResponse?>.unmodifiable(responses),
  );
}
