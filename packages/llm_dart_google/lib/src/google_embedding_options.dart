import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GoogleEmbedOptions implements ProviderInvocationOptions {
  final String? taskType;
  final String? title;

  const GoogleEmbedOptions({
    this.taskType,
    this.title,
  });
}
