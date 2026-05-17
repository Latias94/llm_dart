import 'package:llm_dart_provider/llm_dart_provider.dart';

final class StructuredOutputContext {
  final String? responseId;
  final DateTime? responseTimestamp;
  final String? responseModelId;
  final FinishReason finishReason;
  final String? rawFinishReason;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;

  const StructuredOutputContext({
    this.responseId,
    this.responseTimestamp,
    this.responseModelId,
    required this.finishReason,
    this.rawFinishReason,
    this.usage,
    this.providerMetadata,
  });
}
