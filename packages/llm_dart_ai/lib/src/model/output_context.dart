import 'package:llm_dart_provider/llm_dart_provider.dart';

final class StructuredOutputContext {
  final ModelResponseMetadata? responseMetadata;
  final String? _responseId;
  final DateTime? _responseTimestamp;
  final String? _responseModelId;
  final FinishReason finishReason;
  final String? rawFinishReason;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;

  const StructuredOutputContext({
    this.responseMetadata,
    String? responseId,
    DateTime? responseTimestamp,
    String? responseModelId,
    required this.finishReason,
    this.rawFinishReason,
    this.usage,
    this.providerMetadata,
  })  : _responseId = responseId,
        _responseTimestamp = responseTimestamp,
        _responseModelId = responseModelId;

  String? get responseId => responseMetadata?.id ?? _responseId;

  DateTime? get responseTimestamp =>
      responseMetadata?.timestamp ?? _responseTimestamp;

  String? get responseModelId => responseMetadata?.modelId ?? _responseModelId;
}
