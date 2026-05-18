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

  List<SourceReference> get sources =>
      steps.expand((step) => step.sources).toList(growable: false);

  List<GeneratedFile> get files =>
      steps.expand((step) => step.files).toList(growable: false);

  List<ToolCallContent> get toolCalls =>
      steps.expand((step) => step.toolCalls).toList(growable: false);

  List<ToolCallContent> get staticToolCalls =>
      steps.expand((step) => step.staticToolCalls).toList(growable: false);

  List<ToolCallContent> get dynamicToolCalls =>
      steps.expand((step) => step.dynamicToolCalls).toList(growable: false);

  List<ToolResultContent> get toolResults =>
      steps.expand((step) => step.toolResults).toList(growable: false);

  List<ToolResultContent> get staticToolResults =>
      steps.expand((step) => step.staticToolResults).toList(growable: false);

  List<ToolResultContent> get dynamicToolResults =>
      steps.expand((step) => step.dynamicToolResults).toList(growable: false);

  List<ToolApprovalRequestContent> get toolApprovalRequests =>
      lastStep.toolApprovalRequests;

  FinishReason get finishReason => lastStep.finishReason;

  String? get rawFinishReason => lastStep.rawFinishReason;

  ModelResponseMetadata? get responseMetadata => lastStep.responseMetadata;

  String? get responseId => lastStep.responseId;

  DateTime? get responseTimestamp => lastStep.responseTimestamp;

  String? get responseModelId => lastStep.responseModelId;

  ProviderMetadata? get providerMetadata => lastStep.providerMetadata;

  List<ModelWarning> get warnings =>
      steps.expand((step) => step.warnings).toList(growable: false);
}
