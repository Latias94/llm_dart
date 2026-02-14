import 'package:llm_dart_core/llm_dart_core.dart';

/// Embed a single string value (AI SDK-style).
Future<List<double>> embed({
  required EmbeddingCapability model,
  required String value,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final vectors = await embedMany(
    model: model,
    values: [value],
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
  if (vectors.isEmpty) {
    throw const InvalidRequestError('Embedding model returned no embeddings.');
  }
  return vectors.first;
}

/// Embed multiple string values (AI SDK-style).
Future<List<List<double>>> embedMany({
  required EmbeddingCapability model,
  required List<String> values,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  if (effectiveCallOptions.isEmpty) {
    return model.embed(values, cancelToken: cancelToken);
  }

  if (model is! EmbeddingCallOptionsCapability) {
    throw const InvalidRequestError(
      'This model does not support call-level overrides (headers/body) for embeddings. '
      'Implement `EmbeddingCallOptionsCapability` (or use a provider that does).',
    );
  }

  return (model as EmbeddingCallOptionsCapability).embedWithCallOptions(
    values,
    callOptions: effectiveCallOptions,
    cancelToken: cancelToken,
  );
}
