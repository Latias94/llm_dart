import 'package:llm_dart_core/llm_dart_core.dart';

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
