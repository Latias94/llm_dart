import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_native_tools.dart';

final class OpenAIChatModelSettings implements ProviderModelOptions {
  final bool useResponsesApi;
  final String? organization;
  final String? project;
  final Map<String, String> headers;
  final List<OpenAIBuiltInTool> builtInTools;

  const OpenAIChatModelSettings({
    this.useResponsesApi = true,
    this.organization,
    this.project,
    this.headers = const {},
    this.builtInTools = const [],
  });
}

final class OpenAIEmbeddingModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIEmbeddingModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAISpeechModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAISpeechModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIImageModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIImageModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAITranscriptionModelSettings implements ProviderModelOptions {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAITranscriptionModelSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}
