import 'package:llm_dart_provider/llm_dart_provider.dart';

final class OpenAIEmbedOptions implements ProviderInvocationOptions {
  final String? encodingFormat;
  final String? user;

  const OpenAIEmbedOptions({
    this.encodingFormat,
    this.user,
  });
}
