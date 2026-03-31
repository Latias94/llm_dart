import 'package:llm_dart_core/llm_dart_core.dart';

import 'openai_native_tools.dart';
import 'openai_response_format.dart';

final class OpenAIChatModelSettings implements ProviderModelOptions {
  final bool useResponsesApi;
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIChatModelSettings({
    this.useResponsesApi = true,
    this.organization,
    this.project,
    this.headers = const {},
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

final class OpenAIEmbedOptions implements ProviderInvocationOptions {
  final String? encodingFormat;

  const OpenAIEmbedOptions({
    this.encodingFormat,
  });
}

final class OpenAIGenerateTextOptions implements ProviderInvocationOptions {
  final String? previousResponseId;
  final bool? parallelToolCalls;
  final String? serviceTier;
  final String? verbosity;
  final List<OpenAIBuiltInTool>? builtInTools;
  final OpenAIJsonSchemaResponseFormat? responseFormat;

  const OpenAIGenerateTextOptions({
    this.previousResponseId,
    this.parallelToolCalls,
    this.serviceTier,
    this.verbosity,
    this.builtInTools,
    this.responseFormat,
  });
}
