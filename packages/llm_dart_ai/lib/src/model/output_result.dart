import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GenerateOutputResult<T> {
  final GenerateTextResult result;
  final T output;

  const GenerateOutputResult({
    required this.result,
    required this.output,
  });

  String get text => result.text;

  String? get reasoningText => result.reasoningText;

  FinishReason get finishReason => result.finishReason;

  String? get rawFinishReason => result.rawFinishReason;

  ModelResponseMetadata? get responseMetadata => result.responseMetadata;

  String? get responseId => result.responseId;

  DateTime? get responseTimestamp => result.responseTimestamp;

  String? get responseModelId => result.responseModelId;

  UsageStats? get usage => result.usage;

  ProviderMetadata? get providerMetadata => result.providerMetadata;
}

typedef GenerateObjectResult<T> = GenerateOutputResult<T>;
