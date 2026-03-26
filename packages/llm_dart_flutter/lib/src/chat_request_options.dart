import 'package:llm_dart_core/llm_dart_core.dart';

final class ChatRequestOptions {
  final GenerateTextOptions generateOptions;
  final ProviderInvocationOptions? providerOptions;

  const ChatRequestOptions({
    this.generateOptions = const GenerateTextOptions(),
    this.providerOptions,
  });
}
