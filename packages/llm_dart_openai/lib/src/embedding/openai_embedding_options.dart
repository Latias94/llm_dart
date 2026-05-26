import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../provider/openai_provider_options_namespaces.dart';

final class OpenAIEmbedOptions
    implements ProviderInvocationOptionsBagProjection {
  final String? encodingFormat;
  final String? user;

  const OpenAIEmbedOptions({
    this.encodingFormat,
    this.user,
  });

  @override
  ProviderOptionsBag toProviderOptionsBag() {
    return ProviderOptionsBag.forProvider(openAIProviderOptionsNamespace, {
          'encoding_format': encodingFormat,
          'user': user,
        }) ??
        ProviderOptionsBag.empty;
  }
}
