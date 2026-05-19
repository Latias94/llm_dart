import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_generate_text_options.dart';
import 'openai_responses_request_body_projection.dart';
import 'openai_responses_request_prompt_codec.dart';
import 'openai_responses_request_tool_codec.dart';

final class OpenAIResponsesRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OpenAIResponsesRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OpenAIResponsesRequestCodec {
  final OpenAIResponsesRequestBodyProjection bodyProjection;
  final OpenAIResponsesPromptCodec promptCodec;
  final OpenAIResponsesRequestToolCodec toolCodec;

  const OpenAIResponsesRequestCodec({
    this.bodyProjection = const OpenAIResponsesRequestBodyProjection(),
    this.promptCodec = const OpenAIResponsesPromptCodec(),
    this.toolCodec = const OpenAIResponsesRequestToolCodec(),
  });

  OpenAIResponsesRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required OpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    final warnings = <ModelWarning>[];
    final input = <Object?>[];
    final context = bodyProjection.resolveContext(
      modelId: modelId,
      providerOptions: providerOptions,
    );

    for (final message in prompt) {
      input.addAll(
        promptCodec.encodePromptMessage(
          message,
          warnings,
          systemMessageMode: context.systemMessageMode,
          store: context.store,
          hasConversation: context.hasConversation,
        ),
      );
    }

    final body = bodyProjection.encodeBody(
      modelId: modelId,
      input: input,
      options: options,
      providerOptions: providerOptions,
      stream: stream,
      context: context,
      warnings: warnings,
    );

    final encodedTools = toolCodec.encodeTools(
      tools: tools,
      builtInTools: providerOptions.builtInTools,
    );
    if (encodedTools.isNotEmpty) {
      body['tools'] = encodedTools;
      final encodedToolChoice = toolCodec.encodeToolChoice(
        toolChoice,
        hasFunctionTools: tools.isNotEmpty,
        builtInTools: providerOptions.builtInTools,
      );
      if (encodedToolChoice != null) {
        body['tool_choice'] = encodedToolChoice;
      }
    }

    return OpenAIResponsesRequest(
      body: body,
      warnings: warnings,
    );
  }
}
