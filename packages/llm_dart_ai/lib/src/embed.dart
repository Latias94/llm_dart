import 'package:llm_dart_core/llm_dart_core.dart';

/// Generate embeddings using a provider-agnostic capability.
Future<List<List<double>>> embed({
  required EmbeddingCapability model,
  required List<String> input,
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  if (callOptions.isEmpty) {
    return model.embed(input, cancelToken: cancelToken);
  }

  if (model is! EmbeddingCallOptionsCapability) {
    throw const InvalidRequestError(
      'This model does not support call-level overrides (headers/body) for embeddings. '
      'Implement `EmbeddingCallOptionsCapability` (or use a provider that does).',
    );
  }

  return (model as EmbeddingCallOptionsCapability).embedWithCallOptions(
    input,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}
