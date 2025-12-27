import 'dart:convert';

import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_core/utils/tool_validator.dart';

import 'prompt.dart';
import 'prompt_input.dart';

/// Result for a non-streaming object generation call.
class GenerateObjectResult {
  /// Parsed object. When tool calling is used, this is the tool arguments map.
  final Map<String, dynamic> object;

  /// The raw provider response object for advanced use cases.
  final ChatResponse rawResponse;

  const GenerateObjectResult({
    required this.object,
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
  required ParametersSchema schema,
  String toolName = 'return_object',
  String toolDescription =
      'Return the result as a JSON object that matches the schema.',
  CancelToken? cancelToken,
}) async {
  final input = standardizePromptInput(
    system: system,
    prompt: prompt,
    messages: messages,
    promptIr: promptIr,
  );

  final tool = Tool.function(
    name: toolName,
    description: toolDescription,
    parameters: schema,
  );

  final ChatResponse response;
  switch (input) {
    case StandardizedChatMessages(:final messages):
      final augmentedMessages = <ChatMessage>[
        ChatMessage.system(
          'You must call the tool "$toolName" exactly once and only provide the JSON object via tool arguments.',
        ),
        ...messages,
      ];

      response = await model.chatWithTools(
        augmentedMessages,
        [tool],
        cancelToken: cancelToken,
      );

    case StandardizedPromptIr(:final prompt):
      final augmentedPrompt = Prompt(
        messages: [
          PromptMessage.system(
            'You must call the tool "$toolName" exactly once and only provide the JSON object via tool arguments.',
          ),
          ...prompt.messages,
        ],
      );

      response = model is PromptChatCapability
          ? await (model as PromptChatCapability).chatPrompt(
              augmentedPrompt,
              tools: [tool],
              cancelToken: cancelToken,
            )
          : await model.chatWithTools(
              augmentedPrompt.toChatMessages(),
              [tool],
              cancelToken: cancelToken,
            );
  }

  final toolCall = response.toolCalls
      ?.cast<ToolCall?>()
      .firstWhere((c) => c?.function.name == toolName, orElse: () => null);

  if (toolCall != null) {
    final args = jsonDecode(toolCall.function.arguments);
    if (args is! Map<String, dynamic>) {
      throw const InvalidRequestError(
          'Tool arguments must be a JSON object (map).');
    }

    final validationErrors = ToolValidator.validateParameters(args, schema);
    if (validationErrors.isNotEmpty) {
      throw InvalidRequestError(
        'Generated object does not match schema: ${validationErrors.join(', ')}',
      );
    }

    return GenerateObjectResult(object: args, rawResponse: response);
  }

  final text = response.text;
  if (text == null || text.isEmpty) {
    throw const InvalidRequestError(
        'No tool call and no text content to parse.');
  }

  final parsed = _extractFirstJsonObject(text);
  if (parsed == null) {
    throw const InvalidRequestError(
      'Failed to extract a JSON object from response text.',
    );
  }

  return GenerateObjectResult(object: parsed, rawResponse: response);
}

/// Generate a JSON object from a `Prompt` IR (legacy helper).
@Deprecated('Use generateObject(model: ..., promptIr: ...) instead.')
Future<GenerateObjectResult> generateObjectFromPromptIr({
  required ChatCapability model,
  required Prompt prompt,
  required ParametersSchema schema,
  String toolName = 'return_object',
  String toolDescription =
      'Return the result as a JSON object that matches the schema.',
  CancelToken? cancelToken,
}) =>
    generateObject(
      model: model,
      promptIr: prompt,
      schema: schema,
      toolName: toolName,
      toolDescription: toolDescription,
      cancelToken: cancelToken,
    );

/// Generate a JSON object from a plain prompt (legacy helper).
@Deprecated('Use generateObject(model: ..., system: ..., prompt: ...) instead.')
Future<GenerateObjectResult> generateObjectFromPrompt({
  required ChatCapability model,
  required String prompt,
  required ParametersSchema schema,
  String? systemPrompt,
  String toolName = 'return_object',
  String toolDescription =
      'Return the result as a JSON object that matches the schema.',
  CancelToken? cancelToken,
}) {
  return generateObject(
    model: model,
    system: systemPrompt,
    prompt: prompt,
    schema: schema,
    toolName: toolName,
    toolDescription: toolDescription,
    cancelToken: cancelToken,
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
