part of 'openai_chat_completions_codec.dart';

extension _OpenAIChatCompletionsCodecRequestEncoder
    on OpenAIChatCompletionsCodec {
  OpenAIChatCompletionsRequest _encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    _validateUnsupportedChatCompletionsProviderOptions(providerOptions);

    final warnings = <ModelWarning>[];
    final messages = <Map<String, Object?>>[];
    final systemMessageMode = _resolveSystemMessageMode(
      modelId,
      providerOptions.common,
    );

    for (final message in prompt) {
      messages.addAll(
        _encodePromptMessage(
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
      if (providerOptions.common.parallelToolCalls != null)
        'parallel_tool_calls': providerOptions.common.parallelToolCalls,
      if (providerOptions.common.serviceTier != null)
        'service_tier': providerOptions.common.serviceTier,
      if (providerOptions.common.verbosity != null)
        'verbosity': providerOptions.common.verbosity,
      if (providerOptions.common.user != null)
        'user': providerOptions.common.user,
      if (providerNamespace == 'openai' &&
          providerOptions.common.reasoningEffort != null)
        'reasoning_effort': providerOptions.common.reasoningEffort!.value,
      if (providerNamespace == 'openai' &&
          providerOptions.common.maxCompletionTokens != null)
        'max_completion_tokens': providerOptions.common.maxCompletionTokens,
      if (providerOptions.common.logprobs != null) 'logprobs': true,
      if (providerOptions.common.logprobs case final logprobs?)
        'top_logprobs': _encodeChatTopLogProbs(logprobs),
      if (providerOptions.xaiSearch != null)
        'search_parameters': providerOptions.xaiSearch!.toJson(),
    };

    _applyOpenAICompatibilityRules(
      modelId: modelId,
      providerOptions: providerOptions.common,
      body: body,
      warnings: warnings,
    );

    final encodedTools = _encodeTools(tools);
    if (encodedTools.isNotEmpty) {
      body['tools'] = encodedTools;
      final encodedToolChoice = _encodeToolChoice(
        toolChoice,
        hasFunctionTools: tools.isNotEmpty,
      );
      if (encodedToolChoice != null) {
        body['tool_choice'] = encodedToolChoice;
      }
    }

    if (providerOptions.common.responseFormat case final responseFormat?) {
      body['response_format'] = _encodeResponseFormat(responseFormat);
    }

    return OpenAIChatCompletionsRequest(
      body: body,
      warnings: warnings,
    );
  }
}
