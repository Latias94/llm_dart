import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_step_result.dart';

final class GenerateTextRunResult {
  final List<GenerateTextStepResult> steps;

  GenerateTextRunResult({
    required List<GenerateTextStepResult> steps,
  }) : steps = List.unmodifiable(steps) {
    if (this.steps.isEmpty) {
      throw ArgumentError.value(
        steps,
        'steps',
        'GenerateTextRunResult requires at least one step.',
      );
    }
  }

  GenerateTextStepResult get lastStep => steps.last;

  UsageStats? get totalUsage {
    UsageStats? total;

    for (final step in steps) {
      total = UsageStats.mergeNullable(total, step.usage);
    }

    return total;
  }

  List<ContentPart> get content => lastStep.content;

  String get text => lastStep.text;

  String? get reasoningText => lastStep.reasoningText;

  List<SourceReference> get sources => lastStep.sources;

  List<GeneratedFile> get files => lastStep.files;

  List<ToolCallContent> get toolCalls => lastStep.toolCalls;

  List<ToolResultContent> get toolResults => lastStep.toolResults;

  List<ToolApprovalRequestContent> get toolApprovalRequests =>
      lastStep.toolApprovalRequests;

  FinishReason get finishReason => lastStep.finishReason;

  String? get rawFinishReason => lastStep.rawFinishReason;

  String? get responseId => lastStep.responseId;

  DateTime? get responseTimestamp => lastStep.responseTimestamp;

  String? get responseModelId => lastStep.responseModelId;

  ProviderMetadata? get providerMetadata => lastStep.providerMetadata;
}
