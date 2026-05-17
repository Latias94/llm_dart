import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GenerateTextResultLifecycle {
  final List<ModelWarning> _warnings = <ModelWarning>[];

  String? _responseId;
  DateTime? _responseTimestamp;
  String? _responseModelId;
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
    required String? responseId,
    required DateTime? timestamp,
    required String? modelId,
    required ProviderMetadata? providerMetadata,
  }) {
    _setIfNotNull(
      responseId,
      (value) => _responseId = value,
    );
    _setIfNotNull(
      timestamp,
      (value) => _responseTimestamp = value,
    );
    _setIfNotNull(
      modelId,
      (value) => _responseModelId = value,
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
      responseId: _responseId,
      responseTimestamp: _responseTimestamp,
      responseModelId: _responseModelId,
      usage: _usage,
      providerMetadata: _providerMetadata,
      warnings: _warnings,
    );
  }
}

void _setIfNotNull<T>(T? value, void Function(T value) assign) {
  if (value != null) {
    assign(value);
  }
}
