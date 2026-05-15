import 'google_content_projection_support.dart';

final class GoogleGenerateContentStreamState {
  String? responseId;
  String? modelVersion;
  Map<String, Object?>? promptFeedback;
  Map<String, Object?>? usageMetadata;
  Map<String, Object?>? groundingMetadata;
  Map<String, Object?>? urlContextMetadata;
  List<Object?>? safetyRatings;
  String? rawFinishReason;
  String? finishMessage;

  String? currentTextBlockId;
  String? currentReasoningBlockId;

  int blockCounter = 0;
  int toolCounter = 0;
  bool hasClientToolCalls = false;
  bool emittedResponseMetadata = false;
  bool finished = false;

  final Set<String> emittedSourceKeys = {};
  final GoogleCodeExecutionTracker codeExecutionTracker =
      GoogleCodeExecutionTracker();
}
