import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GenerateTextResultLifecycle {
  final List<ModelWarning> _warnings = <ModelWarning>[];

  ModelResponseMetadata? _responseMetadata;
  FinishReason? _finishReason;
  String? _rawFinishReason;
  UsageStats? _usage;
  ProviderMetadata? _providerMetadata;
  ModelError? _error;

  bool get hasFinishEvent => _finishReason != null;

  void addWarnings(List<ModelWarning> warnings) {
    _warnings.addAll(warnings);
  }

  void applyResponseMetadata({
    required ModelResponseMetadata? responseMetadata,
    required String? responseId,
    required DateTime? timestamp,
    required String? modelId,
    required ProviderMetadata? providerMetadata,
  }) {
    final previous = _responseMetadata;
    final incoming = modelResponseMetadataFrom(
      metadata: responseMetadata,
      id: responseId,
      timestamp: timestamp,
      modelId: modelId,
    );

    _responseMetadata = modelResponseMetadataFrom(
      metadata: incoming ?? previous,
      id: previous?.id,
      timestamp: previous?.timestamp,
      modelId: previous?.modelId,
      headers: previous?.headers.isNotEmpty == true
          ? previous?.headers
          : null,
    );
    mergeProviderMetadata(providerMetadata);
  }

  void applyRunFinish({
    required FinishReason finishReason,
    required String? rawFinishReason,
    required UsageStats? usage,
  }) {
    _finishReason = finishReason;
    _rawFinishReason = rawFinishReason;
    _usage = usage ?? _usage;
  }

  void applyFinish({
    required FinishReason finishReason,
    required String? rawFinishReason,
    required UsageStats? usage,
    required ProviderMetadata? providerMetadata,
  }) {
    _finishReason = finishReason;
    _rawFinishReason = rawFinishReason;
    _usage = usage ?? _usage;
    mergeProviderMetadata(providerMetadata);
  }

  void mergeProviderMetadata(ProviderMetadata? value) {
    _providerMetadata = ProviderMetadata.mergeNullable(
      _providerMetadata,
      value,
    );
  }

  void setError(ModelError error) {
    _error = error;
  }

  GenerateTextResult build({
    required List<ContentPart> content,
  }) {
    if (_error case final error?) {
      throw error;
    }

    if (_finishReason == null) {
      throw StateError(
        'Cannot build GenerateTextResult before a finish event is received.',
      );
    }

    return GenerateTextResult(
      content: content,
      finishReason: _finishReason!,
      rawFinishReason: _rawFinishReason,
      responseMetadata: _responseMetadata,
      usage: _usage,
      providerMetadata: _providerMetadata,
      warnings: _warnings,
    );
  }
}
