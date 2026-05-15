import 'openai_streaming_support.dart';

final class OpenAIChatCompletionsStreamState extends OpenAIStreamState {
  final Set<String> emittedSourceIds = {};
}
