import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_assistant_text_projection.dart';
import 'openai_chat_completions_metadata_support.dart';
import 'openai_chat_completions_source_projection.dart';
import 'openai_chat_completions_tool_projection.dart';

export 'openai_chat_completions_assistant_text_projection.dart'
    show OpenAIChatCompletionsDecodedAssistantText;

final class OpenAIChatCompletionsSupport {
  final String providerNamespace;

  const OpenAIChatCompletionsSupport({
    required this.providerNamespace,
  });

  List<ToolCallContentPart> decodeToolCalls(List<Object?> rawToolCalls) {
    return decodeOpenAIChatCompletionsToolCalls(
      rawToolCalls,
      providerMetadata: providerMetadata,
    );
  }

  List<SourceContentPart> decodeTopLevelSources(Map<String, Object?> response) {
    return decodeOpenAIChatCompletionsTopLevelSources(
      response,
      providerMetadata: providerMetadata,
    );
  }

  Iterable<SourceEvent> decodeChunkSources(
    Map<String, Object?> chunk, {
    required String? responseId,
    required Set<String> emittedSourceIds,
  }) sync* {
    yield* decodeOpenAIChatCompletionsChunkSources(
      chunk,
      responseId: responseId,
      emittedSourceIds: emittedSourceIds,
      providerMetadata: providerMetadata,
    );
  }

  OpenAIChatCompletionsDecodedAssistantText decodeAssistantText(
    Map<String, Object?> message,
  ) {
    return decodeOpenAIChatCompletionsAssistantText(message);
  }

  String? extractReasoningText(Map<String, Object?> message) {
    return extractOpenAIChatCompletionsReasoningText(message);
  }

  ProviderMetadata? responseMetadata(
    Map<String, Object?> response,
    Map<String, Object?>? choice, {
    List<Object?>? logprobs,
  }) {
    return openAIChatCompletionsResponseMetadata(
      providerNamespace: providerNamespace,
      response: response,
      choice: choice,
      logprobs: logprobs,
    );
  }

  ProviderMetadata? providerMetadata(Map<String, Object?> values) {
    return openAIChatCompletionsProviderMetadata(
      providerNamespace: providerNamespace,
      values: values,
    );
  }
}
