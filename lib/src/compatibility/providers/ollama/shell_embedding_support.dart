part of 'shell_support.dart';

final class _OllamaCompatEmbeddingSupport {
  final OllamaConfig config;
  final core.EmbeddingModel embeddingModel;

  const _OllamaCompatEmbeddingSupport({
    required this.config,
    required this.embeddingModel,
  });

  Future<List<List<double>>> embed(
    List<String> input, {
    TransportCancellation? cancelToken,
  }) async {
    final result = await embeddingModel.embed(
      core.EmbedRequest(
        values: input,
        callOptions: core.CallOptions(
          timeout: config.timeout,
          cancellation: cancelToken,
        ),
      ),
    );

    return result.embeddings;
  }
}
