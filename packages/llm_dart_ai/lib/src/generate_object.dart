import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'ai_errors.dart';
import 'call_options_dispatch.dart';
import 'prompt_input.dart';
import 'metadata_fallbacks.dart';
import 'response_messages.dart';
import 'types.dart';
import 'openai_tool_control.dart';
import 'provider_tool_normalization.dart';

/// Result for a non-streaming object generation call.
class GenerateObjectResult {
  /// Parsed object. When tool calling is used, this is the tool arguments map.
  final Map<String, dynamic> object;

  /// Warnings for the call, e.g. unsupported settings.
  final List<LLMWarning> warnings;

  /// Best-effort request metadata for this generation (provider-dependent).
  final LLMRequestMetadataPart? requestMetadata;

  /// Best-effort response metadata for this generation (provider-dependent).
  final LLMResponseMetadataPart? responseMetadata;

  /// Best-effort response messages for this generation.
  final List<ChatMessage> responseMessages;

  /// Best-effort response prompt messages for this generation (Vercel-style IR).
  final List<PromptMessage> responsePromptMessages;

  /// The raw provider response object for advanced use cases.
  final ChatResponse rawResponse;

  const GenerateObjectResult({
    required this.object,
    this.warnings = const <LLMWarning>[],
    this.requestMetadata,
    this.responseMetadata,
    this.responseMessages = const <ChatMessage>[],
    this.responsePromptMessages = const <PromptMessage>[],
    required this.rawResponse,
  });
}

/// Generate a JSON object using a tool-call schema (preferred), with a text
/// fallback that extracts the first JSON object from the response.
///
/// This keeps the "standard surface" small:
/// - Uses function tools (cross-provider stable)
/// - Avoids provider-specific structured output formats at this layer
Future<GenerateObjectResult> generateObject({
  required ChatCapability model,
  String? system,
  String? prompt,
  List<ChatMessage>? messages,
  Prompt? promptIr,
  List<ProviderTool>? providerTools,
  ToolChoice? toolChoice,
  bool? parallelToolCalls,
  required Object schema,
  String toolName = 'return_object',
  String toolDescription =
      'Return the result as a JSON object that matches the schema.',
  IncludeOptions include = const IncludeOptions(),
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final schemaDef = asSchema<Map<String, dynamic>>(schema);

  final startedAt = DateTime.now().toUtc();
  final defaultModelId = model is ModelIdentityCapability
      ? (model as ModelIdentityCapability).modelId
      : null;
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  final effectiveCallOptions = applyOpenAIToolControlsToCallOptions(
    defaultCallOptions.mergedWith(callOptions),
    toolChoice: toolChoice,
    parallelToolCalls: parallelToolCalls,
  );

  final tool = Tool.function(
    name: toolName,
    description: toolDescription,
    inputSchema: schemaDef.jsonSchema,
  );

  final instruction =
      'You must call the tool "$toolName" exactly once and only provide the JSON object via tool arguments.';

  final augmentedInput = switch (input) {
    StandardizedChatMessages(:final messages) => StandardizedChatMessages([
        ChatMessage.system(instruction),
        ...messages,
      ]),
    StandardizedPromptIr(:final prompt) => StandardizedPromptIr(
        Prompt(
          messages: [
            PromptMessage.system(instruction),
            ...prompt.messages,
          ],
        ),
      ),
  };

  final normalized = normalizeProviderToolsAndCollectWarnings(
    model: model,
    providerTools: providerTools,
  );

  final response = await chatWithToolsBestEffort(
    model: model,
    input: augmentedInput,
    tools: [tool],
    providerTools: normalized.providerTools,
    callOptions: effectiveCallOptions,
    cancelToken: cancelToken,
  );

  final providerWarnings = response is ChatResponseWithWarnings
      ? response.warnings
      : const <LLMWarning>[];
  final warnings = normalized.warnings.isEmpty
      ? providerWarnings
      : (providerWarnings.isEmpty
          ? normalized.warnings
          : List<LLMWarning>.unmodifiable([
              ...normalized.warnings,
              ...providerWarnings,
            ]));

  final toolCall = response.toolCalls
      ?.cast<ToolCall?>()
      .firstWhere((c) => c?.function.name == toolName, orElse: () => null);

  if (toolCall != null) {
    Object? decodedArgs;
    try {
      decodedArgs = jsonDecode(toolCall.function.arguments);
    } catch (e) {
      throw NoObjectGeneratedError(
        message: 'Failed to parse tool arguments as JSON.',
        text: toolCall.function.arguments,
        finishReason: response is ChatResponseWithFinishReason
            ? response.finishReason
            : null,
        usage: response.usage,
        responseMetadata: response is ChatResponseWithResponseMetadata
            ? response.responseMetadata
            : null,
        cause: e,
      );
    }

    if (decodedArgs is! Map<String, dynamic>) {
      throw NoObjectGeneratedError(
        message: 'Tool arguments must be a JSON object (map).',
        text: toolCall.function.arguments,
        finishReason: response is ChatResponseWithFinishReason
            ? response.finishReason
            : null,
        usage: response.usage,
        responseMetadata: response is ChatResponseWithResponseMetadata
            ? response.responseMetadata
            : null,
      );
    }

    final validate = schemaDef.validate;
    if (validate != null) {
      final validation = await Future.value(validate(decodedArgs));
      if (!validation.success) {
        throw NoObjectGeneratedError(
          message: 'Generated object does not match schema.',
          text: toolCall.function.arguments,
          finishReason: response is ChatResponseWithFinishReason
              ? response.finishReason
              : null,
          usage: response.usage,
          responseMetadata: response is ChatResponseWithResponseMetadata
              ? response.responseMetadata
              : null,
          cause: validation is ValidationFailure
              ? (validation as ValidationFailure).error
              : 'Schema validation failed.',
        );
      }
    } else {
      final validationErrors = ToolValidator.validateParameters(
        decodedArgs,
        schemaDef.jsonSchema,
      );
      if (validationErrors.isNotEmpty) {
        throw NoObjectGeneratedError(
          message: 'Generated object does not match schema.',
          text: toolCall.function.arguments,
          finishReason: response is ChatResponseWithFinishReason
              ? response.finishReason
              : null,
          usage: response.usage,
          responseMetadata: response is ChatResponseWithResponseMetadata
              ? response.responseMetadata
              : null,
          cause: validationErrors,
        );
      }
    }

    return GenerateObjectResult(
      object: decodedArgs,
      warnings: warnings,
      rawResponse: response,
      requestMetadata: requestMetadataWithInclude(
        response is ChatResponseWithRequestMetadata
            ? response.requestMetadata
            : null,
        include,
      ),
      responseMetadata: responseMetadataWithInclude(
        responseMetadataWithDefaults(
          response is ChatResponseWithResponseMetadata
              ? response.responseMetadata
              : null,
          startedAt,
          defaultModelId: defaultModelId,
        ),
        include,
      ),
      responseMessages: buildResponseMessagesBestEffort(response),
      responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
    );
  }

  final text = response.text;
  if (text == null || text.isEmpty) {
    throw NoObjectGeneratedError(
      message: 'No tool call and no text content to parse.',
      text: response.text,
      finishReason: response is ChatResponseWithFinishReason
          ? response.finishReason
          : null,
      usage: response.usage,
      responseMetadata: response is ChatResponseWithResponseMetadata
          ? response.responseMetadata
          : null,
    );
  }

  final parsed = _extractFirstJsonObject(text);
  if (parsed == null) {
    throw NoObjectGeneratedError(
      message: 'Failed to extract a JSON object from response text.',
      text: text,
      finishReason: response is ChatResponseWithFinishReason
          ? response.finishReason
          : null,
      usage: response.usage,
      responseMetadata: response is ChatResponseWithResponseMetadata
          ? response.responseMetadata
          : null,
    );
  }

  final validate = schemaDef.validate;
  if (validate != null) {
    final validation = await Future.value(validate(parsed));
    if (!validation.success) {
      throw NoObjectGeneratedError(
        message: 'Generated object does not match schema.',
        text: text,
        finishReason: response is ChatResponseWithFinishReason
            ? response.finishReason
            : null,
        usage: response.usage,
        responseMetadata: response is ChatResponseWithResponseMetadata
            ? response.responseMetadata
            : null,
        cause: validation is ValidationFailure
            ? (validation as ValidationFailure).error
            : 'Schema validation failed.',
      );
    }
  } else {
    final validationErrors =
        ToolValidator.validateParameters(parsed, schemaDef.jsonSchema);
    if (validationErrors.isNotEmpty) {
      throw NoObjectGeneratedError(
        message: 'Generated object does not match schema.',
        text: text,
        finishReason: response is ChatResponseWithFinishReason
            ? response.finishReason
            : null,
        usage: response.usage,
        responseMetadata: response is ChatResponseWithResponseMetadata
            ? response.responseMetadata
            : null,
        cause: validationErrors,
      );
    }
  }

  return GenerateObjectResult(
    object: parsed,
    warnings: warnings,
    rawResponse: response,
    requestMetadata: requestMetadataWithInclude(
      response is ChatResponseWithRequestMetadata
          ? response.requestMetadata
          : null,
      include,
    ),
    responseMetadata: responseMetadataWithInclude(
      responseMetadataWithDefaults(
        response is ChatResponseWithResponseMetadata
            ? response.responseMetadata
            : null,
        startedAt,
        defaultModelId: defaultModelId,
      ),
      include,
    ),
    responseMessages: buildResponseMessagesBestEffort(response),
    responsePromptMessages: buildResponsePromptMessagesBestEffort(response),
  );
}

Map<String, dynamic>? _extractFirstJsonObject(String text) {
  final start = text.indexOf('{');
  if (start == -1) return null;

  var depth = 0;
  for (var i = start; i < text.length; i++) {
    final ch = text.codeUnitAt(i);
    if (ch == 0x7B) depth++; // {
    if (ch == 0x7D) depth--; // }
    if (depth == 0) {
      final candidate = text.substring(start, i + 1);
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) return decoded;
        return null;
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}
