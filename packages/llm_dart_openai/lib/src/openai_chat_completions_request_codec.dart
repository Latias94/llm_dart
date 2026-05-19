import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_request_options_codec.dart';
import 'openai_chat_completions_request_policy.dart';
import 'openai_chat_completions_request_prompt_codec.dart';
import 'openai_chat_completions_request_tool_codec.dart';
import 'openai_family_profile.dart';
import 'openai_generate_text_options.dart';
import 'openai_request_format_codec.dart';
import 'resolved_openai_options.dart';

final class OpenAIChatCompletionsRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OpenAIChatCompletionsRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OpenAIChatCompletionsRequestCodec {
  final String providerNamespace;
  final OpenAIFamilyProfile? profile;

  const OpenAIChatCompletionsRequestCodec({
    this.providerNamespace = 'openai',
    this.profile,
  });

  OpenAIChatCompletionsRequestPolicy get _requestPolicy => switch (profile) {
        final profile? => openAIChatCompletionsRequestPolicyForProfile(
            profile,
          ),
        null => openAIChatCompletionsRequestPolicyFor(providerNamespace),
      };

  OpenAIChatCompletionsRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required ResolvedOpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    const requestOptionsCodec = OpenAIChatCompletionsRequestOptionsCodec();
    final promptCodec = OpenAIChatCompletionsPromptCodec(
      providerNamespace: providerNamespace,
    );
    const toolCodec = OpenAIChatCompletionsRequestToolCodec();
    final requestPolicy = _requestPolicy;

    requestOptionsCodec.validateUnsupportedProviderOptions(providerOptions);

    final warnings = <ModelWarning>[];
    final messages = <Map<String, Object?>>[];
    final systemMessageMode = requestOptionsCodec.resolveSystemMessageMode(
      modelId,
      providerOptions.common,
    );
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
      if (providerOptions.xaiSearch != null)
        'search_parameters': providerOptions.xaiSearch!.toJson(),
    };

    requestPolicy.addProviderRequestFields(
      modelId: modelId,
      body: body,
      providerOptions: providerOptions,
      effectiveReasoningEffort: effectiveReasoningEffort,
    );

    requestPolicy.applyCompatibilityRules(
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
    } else {
      requestPolicy.addProviderResponseFormat(
        body: body,
        providerOptions: providerOptions,
      );
    }

    return OpenAIChatCompletionsRequest(
      body: body,
      warnings: warnings,
    );
  }
}
