import 'package:llm_dart_provider/llm_dart_provider.dart';

final class OpenAISpeechOptions implements ProviderInvocationOptions {
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
}
