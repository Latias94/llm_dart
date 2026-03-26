import '../common/provider_metadata.dart';
import '../common/provider_options.dart';
import '../common/usage_stats.dart';

final class EmbedRequest {
  final List<String> values;
  final int? dimensions;
  final ProviderInvocationOptions? providerOptions;

  EmbedRequest({
    required List<String> values,
    this.dimensions,
    this.providerOptions,
  }) : values = List.unmodifiable(values);
}

final class EmbedResult {
  final List<List<double>> embeddings;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;

  EmbedResult({
    required List<List<double>> embeddings,
    this.usage,
    this.providerMetadata,
  }) : embeddings = List.unmodifiable(
          embeddings.map(List<double>.unmodifiable),
        );
}

abstract interface class EmbeddingModel {
  String get providerId;

  String get modelId;

  Future<EmbedResult> embed(EmbedRequest request);
}
