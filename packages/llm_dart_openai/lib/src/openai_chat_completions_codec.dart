import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_request_options_codec.dart';
import 'openai_chat_completions_request_prompt_codec.dart';
import 'openai_chat_completions_request_tool_codec.dart';
import 'openai_chat_completions_stream_event_codec.dart';
import 'openai_chat_completions_stream_result_codec.dart';
import 'openai_chat_completions_stream_state.dart';
import 'openai_chat_completions_support.dart';
import 'openai_options.dart';
import 'openai_request_format_codec.dart';
import 'resolved_openai_options.dart';

export 'openai_chat_completions_stream_state.dart';

final class OpenAIChatCompletionsRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OpenAIChatCompletionsRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OpenAIChatCompletionsCodec {
  final String providerNamespace;

  const OpenAIChatCompletionsCodec({
    this.providerNamespace = 'openai',
  });

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
    return _encodeRequest(
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

  OpenAIChatCompletionsRequest _encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    final requestOptionsCodec = OpenAIChatCompletionsRequestOptionsCodec(
      providerNamespace: providerNamespace,
    );
    final promptCodec = OpenAIChatCompletionsPromptCodec(
      providerNamespace: providerNamespace,
    );
    const toolCodec = OpenAIChatCompletionsRequestToolCodec();

    requestOptionsCodec.validateUnsupportedProviderOptions(providerOptions);

    final warnings = <ModelWarning>[];
    final messages = <Map<String, Object?>>[];
    final systemMessageMode = requestOptionsCodec.resolveSystemMessageMode(
      modelId,
      providerOptions.common,
    );
    final deepseekOptions =
        providerNamespace == 'deepseek' ? providerOptions.deepseek : null;
    final deepseekLogprobs = deepseekOptions?.logprobs;
    final deepseekTopLogprobs = deepseekOptions?.topLogprobs;
    final deepseekFrequencyPenalty = deepseekOptions?.frequencyPenalty;
    final deepseekPresencePenalty = deepseekOptions?.presencePenalty;
    final deepseekResponseFormat = deepseekOptions?.responseFormat;
    final commonLogprobs = providerOptions.common.logprobs;
    final sharedReasoningEffort = mapSharedOpenAIReasoningEffort(
      options.reasoning,
      warnings: warnings,
    );
    final effectiveReasoningEffort =
        providerOptions.common.reasoningEffort ?? sharedReasoningEffort;
    if (providerOptions.common.reasoningEffort != null &&
        sharedReasoningEffort != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'options.reasoning',
          message:
              'OpenAI providerOptions.reasoningEffort overrides shared options.reasoning.',
        ),
      );
    }

    for (final message in prompt) {
      messages.addAll(
        promptCodec.encodePromptMessage(
          message,
          warnings,
          systemMessageMode: systemMessageMode,
        ),
      );
    }

    final body = <String, Object?>{
      'model': modelId,
      'messages': messages,
      'stream': stream,
      if (options.maxOutputTokens != null)
        'max_tokens': options.maxOutputTokens,
      if (options.temperature != null) 'temperature': options.temperature,
      if (options.stopSequences != null && options.stopSequences!.isNotEmpty)
        'stop': options.stopSequences,
      if (options.topP != null) 'top_p': options.topP,
      if (options.topK != null) 'top_k': options.topK,
      if (options.frequencyPenalty != null)
        'frequency_penalty': options.frequencyPenalty,
      if (options.presencePenalty != null)
        'presence_penalty': options.presencePenalty,
      if (options.seed != null) 'seed': options.seed,
      if (providerOptions.common.parallelToolCalls != null)
        'parallel_tool_calls': providerOptions.common.parallelToolCalls,
      if (providerOptions.common.serviceTier != null)
        'service_tier': providerOptions.common.serviceTier,
      if (providerOptions.common.verbosity != null)
        'verbosity': providerOptions.common.verbosity,
      if (providerOptions.common.user != null)
        'user': providerOptions.common.user,
      if (providerNamespace == 'openai' && effectiveReasoningEffort != null)
        'reasoning_effort': effectiveReasoningEffort.value,
      if (providerNamespace == 'openai' &&
          providerOptions.common.maxCompletionTokens != null)
        'max_completion_tokens': providerOptions.common.maxCompletionTokens,
      if (deepseekLogprobs != null) 'logprobs': deepseekLogprobs,
      if (deepseekLogprobs == null && commonLogprobs != null) 'logprobs': true,
      if (deepseekTopLogprobs != null) 'top_logprobs': deepseekTopLogprobs,
      if (deepseekTopLogprobs == null && commonLogprobs != null)
        'top_logprobs': requestOptionsCodec.encodeChatTopLogProbs(
          commonLogprobs,
        ),
      if (providerNamespace == 'deepseek' && deepseekFrequencyPenalty != null)
        'frequency_penalty': deepseekFrequencyPenalty,
      if (providerNamespace == 'deepseek' && deepseekPresencePenalty != null)
        'presence_penalty': deepseekPresencePenalty,
      if (providerOptions.xaiSearch != null)
        'search_parameters': providerOptions.xaiSearch!.toJson(),
    };

    requestOptionsCodec.applyCompatibilityRules(
      modelId: modelId,
      commonOptions: providerOptions.common.copyWith(
        reasoningEffort: effectiveReasoningEffort,
      ),
      body: body,
      warnings: warnings,
    );

    final encodedTools = toolCodec.encodeTools(tools);
    if (encodedTools.isNotEmpty) {
      body['tools'] = encodedTools;
      final encodedToolChoice = toolCodec.encodeToolChoice(
        toolChoice,
        hasFunctionTools: tools.isNotEmpty,
      );
      if (encodedToolChoice != null) {
        body['tool_choice'] = encodedToolChoice;
      }
    }

    if (providerOptions.common.responseFormat case final responseFormat?) {
      body['response_format'] = encodeOpenAIJsonSchemaResponseFormat(
        responseFormat,
      );
    } else if (providerNamespace == 'deepseek' &&
        deepseekResponseFormat != null) {
      body['response_format'] = deepseekResponseFormat;
    }

    return OpenAIChatCompletionsRequest(
      body: body,
      warnings: warnings,
    );
  }
}
