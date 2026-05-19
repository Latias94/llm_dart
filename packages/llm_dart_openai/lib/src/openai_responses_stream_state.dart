import 'openai_streaming_support.dart';

final class OpenAIResponsesStreamState extends OpenAIStreamState {
  final Set<String> emittedAnnotationKeys = {};
  final List<String> hostedToolSearchCallIds = [];
  final Set<String> emittedWebSearchToolCallIds = {};
}
