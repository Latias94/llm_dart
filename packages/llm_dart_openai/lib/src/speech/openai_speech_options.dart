import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../provider/openai_provider_options_namespaces.dart';

final class OpenAISpeechOptions
    implements ProviderInvocationOptionsBagProjection {
  final String? outputFormat;
  final String? instructions;
  final double? speed;
  final String? language;

  const OpenAISpeechOptions({
    this.outputFormat,
    this.instructions,
    this.speed,
    this.language,
  });

  @override
  ProviderOptionsBag toProviderOptionsBag() {
    return ProviderOptionsBag.forProvider(openAIProviderOptionsNamespace, {
          'output_format': outputFormat,
          'instructions': instructions,
          'speed': speed,
          'language': language,
        }) ??
        ProviderOptionsBag.empty;
  }
}
