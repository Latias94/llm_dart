import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'ollama_chat_binary_part_encoder.dart';
import 'ollama_chat_prompt_projection.dart';
import 'ollama_chat_request_options_policy.dart';
import 'ollama_options.dart';
import 'ollama_tool_codec.dart';

final class OllamaPreparedChatRequest {
  final Map<String, Object?> body;
  final List<ModelWarning> warnings;

  OllamaPreparedChatRequest({
    required Map<String, Object?> body,
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        warnings = List.unmodifiable(warnings);
}

final class OllamaChatRequestCodec {
  final String modelId;
  final OllamaChatModelSettings settings;
  final OllamaToolCodec toolCodec;
  final OllamaChatRequestOptionsPolicy optionsPolicy;

  const OllamaChatRequestCodec({
    required this.modelId,
    required this.settings,
    this.toolCodec = const OllamaToolCodec(),
    this.optionsPolicy = const OllamaChatRequestOptionsPolicy(),
  });

  Future<OllamaPreparedChatRequest> encode({
    required GenerateTextRequest request,
    required bool stream,
  }) async {
    if (request.prompt.isEmpty) {
      throw ArgumentError(
        'Ollama requests require at least one prompt message.',
      );
    }

    final warnings = <ModelWarning>[];
    final providerOptions = optionsPolicy.resolveProviderOptions(request);
    final requestOptions = optionsPolicy.project(
      options: request.options,
      providerOptions: providerOptions,
      warnings: warnings,
    );
    final tools = toolCodec.encodeToolDefinitions(
      tools: request.tools,
      toolChoice: request.toolChoice,
      warnings: warnings,
    );
    final messages = await OllamaChatPromptProjectionCodec(
      toolCodec: toolCodec,
    ).encodePrompt(
      prompt: request.prompt,
      binaryEncoder: OllamaChatBinaryPartEncoder(
        binaryResolver: _resolveBinaryResolver(providerOptions),
      ),
      warnings: warnings,
    );

    final options = requestOptions.options;
    final responseFormat = requestOptions.responseFormat;
    final reasoning = requestOptions.reasoning;

    return OllamaPreparedChatRequest(
      body: {
        'model': modelId,
        'messages': messages,
        'stream': stream,
        if (options.isNotEmpty) 'options': options,
        if (responseFormat != null) 'format': responseFormat,
        if (tools.isNotEmpty) 'tools': tools,
        if (providerOptions?.keepAlive case final keepAlive?)
          'keep_alive': keepAlive,
        if (providerOptions?.raw case final raw?) 'raw': raw,
        if (reasoning case final reasoning?) 'think': reasoning,
      },
      warnings: warnings,
    );
  }

  OllamaBinaryResolver? _resolveBinaryResolver(
    OllamaGenerateTextOptions? providerOptions,
  ) {
    return providerOptions?.binaryResolver ?? settings.binaryResolver;
  }
}
