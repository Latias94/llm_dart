import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../content/content_part.dart';
import 'language_model.dart';

final class GenerateTextStepResult {
  final int stepNumber;
  final String providerId;
  final String modelId;
  final GenerateTextRequest request;
  final GenerateTextResult result;

  const GenerateTextStepResult({
    required this.stepNumber,
    required this.providerId,
    required this.modelId,
    required this.request,
    required this.result,
  });

  List<ContentPart> get content => result.content;

  String get text => result.text;

  String? get reasoningText => result.reasoningText;

  List<SourceReference> get sources => result.content
      .whereType<SourceContentPart>()
      .map((part) => part.source)
      .toList(growable: false);

  List<GeneratedFile> get files => result.content
      .whereType<FileContentPart>()
      .map((part) => part.file)
      .toList(growable: false);

  List<ToolCallContent> get toolCalls => result.content
      .whereType<ToolCallContentPart>()
      .map((part) => part.toolCall)
      .toList(growable: false);

  List<ToolResultContent> get toolResults => result.content
      .whereType<ToolResultContentPart>()
      .map((part) => part.toolResult)
      .toList(growable: false);

  List<ToolApprovalRequestContent> get toolApprovalRequests => result.content
      .whereType<ToolApprovalRequestContentPart>()
      .map((part) => part.approvalRequest)
      .toList(growable: false);

  FinishReason get finishReason => result.finishReason;

  String? get rawFinishReason => result.rawFinishReason;

  String? get responseId => result.responseId;

  DateTime? get responseTimestamp => result.responseTimestamp;

  String? get responseModelId => result.responseModelId;

  UsageStats? get usage => result.usage;

  ProviderMetadata? get providerMetadata => result.providerMetadata;

  List<ModelWarning> get warnings => result.warnings;
}
