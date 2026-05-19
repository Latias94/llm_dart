import 'openai_streaming_support.dart';

final class OpenAIResponsesStreamState extends OpenAIStreamState {
  final Set<String> emittedAnnotationKeys = {};
  final List<String> hostedToolSearchCallIds = [];
  final Set<String> emittedWebSearchToolCallIds = {};
  final Map<String, String> customToolNamesByCallId = {};
  final Map<int, OpenAIResponsesApplyPatchStreamState> applyPatchInputs = {};
}

final class OpenAIResponsesApplyPatchStreamState {
  bool hasDiff;

  OpenAIResponsesApplyPatchStreamState({
    this.hasDiff = false,
  });
}
