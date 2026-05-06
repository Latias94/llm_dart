import 'package:llm_dart_provider/llm_dart_provider.dart';

final class ChatRequestOptions {
  final GenerateTextOptions generateOptions;
  final CallOptions callOptions;
  final Map<String, Object?> metadata;

  const ChatRequestOptions({
    this.generateOptions = const GenerateTextOptions(),
    this.callOptions = const CallOptions(),
    this.metadata = const {},
  });
}
