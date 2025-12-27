import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';

/// Generate embeddings using a provider-agnostic capability.
Future<List<List<double>>> embed({
  required EmbeddingCapability model,
  required List<String> input,
  CancelToken? cancelToken,
}) {
  return model.embed(input, cancelToken: cancelToken);
}
