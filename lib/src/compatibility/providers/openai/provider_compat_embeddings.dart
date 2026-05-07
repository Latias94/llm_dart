part of 'provider_compat.dart';

mixin OpenAIProviderEmbeddingsMixin implements EmbeddingCapability {
  OpenAIEmbeddings get _embeddings;

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    TransportCancellation? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }
}
