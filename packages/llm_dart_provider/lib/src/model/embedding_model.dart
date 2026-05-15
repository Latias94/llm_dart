import '../common/call_options.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import 'model_response_metadata.dart';

final class EmbedRequest {
  final List<String> values;
  final int? dimensions;
  final CallOptions callOptions;

  EmbedRequest({
    required List<String> values,
    this.dimensions,
    this.callOptions = const CallOptions(),
  }) : values = List.unmodifiable(values);
}

final class EmbedResult {
  final List<List<double>> embeddings;
  final UsageStats? usage;
  final List<ModelWarning> warnings;
  final ModelResponseMetadata? responseMetadata;
  final ProviderMetadata? providerMetadata;

  EmbedResult({
    required List<List<double>> embeddings,
    this.usage,
    List<ModelWarning> warnings = const [],
    this.responseMetadata,
    this.providerMetadata,
  })  : embeddings = List.unmodifiable(
          embeddings.map(List<double>.unmodifiable),
        ),
        warnings = List.unmodifiable(warnings);
}

abstract interface class EmbeddingModel {
  String get providerId;

  String get modelId;

  Future<EmbedResult> doEmbed(EmbedRequest request);
}
