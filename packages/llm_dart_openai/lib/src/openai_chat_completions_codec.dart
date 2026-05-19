import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_request_codec.dart';
import 'openai_chat_completions_stream_event_codec.dart';
import 'openai_chat_completions_stream_result_codec.dart';
import 'openai_chat_completions_stream_state.dart';
import 'openai_chat_completions_support.dart';
import 'openai_family_profile.dart';
import 'resolved_openai_options.dart';

export 'openai_chat_completions_request_codec.dart'
    show OpenAIChatCompletionsRequest, OpenAIChatCompletionsRequestCodec;
export 'openai_chat_completions_stream_state.dart';

final class OpenAIChatCompletionsCodec {
  final String providerNamespace;
  final OpenAIFamilyProfile? profile;

  const OpenAIChatCompletionsCodec({
    this.providerNamespace = 'openai',
  }) : profile = null;

  OpenAIChatCompletionsCodec.forProfile(OpenAIFamilyProfile this.profile)
      : providerNamespace = profile.providerId;

  OpenAIChatCompletionsSupport get _support => OpenAIChatCompletionsSupport(
        providerNamespace: providerNamespace,
      );

  OpenAIChatCompletionsRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    return OpenAIChatCompletionsRequestCodec(
      providerNamespace: providerNamespace,
      profile: profile,
    ).encodeRequest(
      modelId: modelId,
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      providerOptions: providerOptions,
      stream: stream,
    );
  }

  GenerateTextResult decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) =>
      decodeOpenAIChatCompletionsGenerateResponse(
        response,
        support: _support,
        warnings: warnings,
      );

  Iterable<LanguageModelStreamEvent> decodeStreamChunk(
    Map<String, Object?> chunk,
    OpenAIChatCompletionsStreamState state,
  ) =>
      decodeOpenAIChatCompletionsStreamChunk(_support, chunk, state);
}
