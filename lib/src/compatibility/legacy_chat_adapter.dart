import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart' as core;

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../core/config.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';

class LegacyChatCapabilityAdapter implements ChatCapability {
  final core.LanguageModel model;
  final LLMConfig config;
  final core.ProviderInvocationOptions? providerOptions;

  const LegacyChatCapabilityAdapter({
    required this.model,
    required this.config,
    this.providerOptions,
  });

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      throw const CancelledError();
    }

    final request = buildRequest(messages, tools);
    final operation =
        model.generate(request).then(_LegacyChatResponse.fromResult);
    return _awaitWithCancellation(operation, cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    if (cancelToken?.isCancelled ?? false) {
      throw const CancelledError();
    }

    final request = buildRequest(messages, tools);
    final state = _LegacyStreamState();

    await for (final event in model.stream(request)) {
      if (cancelToken?.isCancelled ?? false) {
        throw const CancelledError();
      }

      for (final mappedEvent in _mapStreamEvent(event, state)) {
        yield mappedEvent;
      }
    }
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final response = await chat([ChatMessage.user(prompt)]);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }

    return text;
  }

  core.GenerateTextRequest buildRequest(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    core.ProviderInvocationOptions? providerOptionsOverride,
  }) {
    final effectiveTools = tools ?? config.tools ?? const <Tool>[];
    final convertedTools =
        effectiveTools.map(_convertTool).toList(growable: false);
    final convertedToolChoice =
        convertedTools.isEmpty ? null : _convertToolChoice(config.toolChoice);

    return core.GenerateTextRequest(
      prompt: convertMessages(messages),
      tools: convertedTools,
      toolChoice: convertedToolChoice,
      options: core.GenerateTextOptions(
        maxOutputTokens: config.maxTokens,
        temperature: config.temperature,
        stopSequences: config.stopSequences,
        topP: config.topP,
        topK: config.topK,
      ),
      callOptions: core.CallOptions(
        timeout: config.timeout,
        providerOptions: providerOptionsOverride ?? providerOptions,
      ),
    );
  }

  List<core.PromptMessage> convertMessages(List<ChatMessage> messages) {
    final prompt = <core.PromptMessage>[];
    final hasSystemMessage =
        messages.any((message) => message.role == ChatRole.system);

    if (!hasSystemMessage &&
        config.systemPrompt != null &&
        config.systemPrompt!.isNotEmpty) {
      prompt.add(core.SystemPromptMessage.text(config.systemPrompt!));
    }

    for (final message in messages) {
      prompt.addAll(convertMessage(message));
    }

    return prompt;
  }

  List<core.PromptMessage> convertMessage(ChatMessage message) {
    final metadata = _messageMetadata(message);
    final textPart = _buildTextPart(message.content, metadata);

    switch (message.messageType) {
      case TextMessage():
        return [_buildTextPromptMessage(message.role, textPart)];
      case ImageMessage(:final mime, :final data):
        return [
          _buildMediaPromptMessage(
            role: message.role,
            textPart: textPart,
            part: core.ImagePromptPart(
              mediaType: mime.mimeType,
              bytes: data,
              providerMetadata: metadata,
            ),
          ),
        ];
      case ImageUrlMessage(:final url):
        return [
          _buildMediaPromptMessage(
            role: message.role,
            textPart: textPart,
            part: core.ImagePromptPart(
              mediaType: 'image/*',
              uri: Uri.parse(url),
              providerMetadata: metadata,
            ),
          ),
        ];
      case FileMessage(:final mime, :final data):
        return [
          _buildMediaPromptMessage(
            role: message.role,
            textPart: textPart,
            part: core.FilePromptPart(
              mediaType: mime.mimeType,
              bytes: data,
              providerMetadata: metadata,
            ),
          ),
        ];
      case ToolUseMessage(:final toolCalls):
        final parts = <core.PromptPart>[
          if (textPart != null) textPart,
          for (final toolCall in toolCalls)
            core.ToolCallPromptPart(
              toolCallId: toolCall.id,
              toolName: toolCall.function.name,
              input: _decodeJsonValue(toolCall.function.arguments),
              providerMetadata: metadata,
            ),
        ];
        return [
          core.AssistantPromptMessage(parts: parts),
        ];
      case ToolResultMessage(:final results):
        return [
          for (final result in results)
            core.ToolPromptMessage(
              toolName: result.function.name,
              parts: [
                core.ToolResultPromptPart(
                  toolCallId: result.id,
                  toolName: result.function.name,
                  output: _decodeToolResultOutput(
                    encodedOutput: result.function.arguments,
                    fallbackText: message.content,
                  ),
                  providerMetadata: metadata,
                ),
              ],
            ),
        ];
    }
  }

  core.PromptMessage _buildTextPromptMessage(
    ChatRole role,
    core.TextPromptPart? textPart,
  ) {
    final parts = [
      if (textPart != null) textPart,
    ];

    return switch (role) {
      ChatRole.system => core.SystemPromptMessage(parts: parts),
      ChatRole.user => core.UserPromptMessage(parts: parts),
      ChatRole.assistant => core.AssistantPromptMessage(parts: parts),
    };
  }

  core.PromptMessage _buildMediaPromptMessage({
    required ChatRole role,
    required core.TextPromptPart? textPart,
    required core.PromptPart part,
  }) {
    final parts = <core.PromptPart>[
      if (textPart != null) textPart,
      part,
    ];

    return switch (role) {
      ChatRole.system => core.SystemPromptMessage(parts: parts),
      ChatRole.user => core.UserPromptMessage(parts: parts),
      ChatRole.assistant => core.AssistantPromptMessage(parts: parts),
    };
  }

  core.TextPromptPart? _buildTextPart(
    String content,
    core.ProviderMetadata? metadata,
  ) {
    if (content.isEmpty) {
      return null;
    }

    return core.TextPromptPart(
      content,
      providerMetadata: metadata,
    );
  }

  core.ProviderMetadata? _messageMetadata(ChatMessage message) {
    if (message.extensions.isEmpty) {
      return null;
    }

    return core.ProviderMetadata(_normalizeMap(message.extensions));
  }

  core.FunctionToolDefinition _convertTool(Tool tool) {
    if (tool.toolType != 'function') {
      throw UnsupportedError(
        'Only function tools can be bridged into the refactored language-model API.',
      );
    }

    return core.FunctionToolDefinition(
      name: tool.function.name,
      description: tool.function.description,
      inputSchema: core.ToolJsonSchema.raw(
        _normalizeMap(tool.function.parameters.toJson()),
      ),
    );
  }

  core.ToolChoice? _convertToolChoice(ToolChoice? toolChoice) {
    return switch (toolChoice) {
      null => null,
      AutoToolChoice() => const core.AutoToolChoice(),
      AnyToolChoice() => const core.RequiredToolChoice(),
      NoneToolChoice() => const core.NoneToolChoice(),
      SpecificToolChoice(:final toolName) => core.SpecificToolChoice(toolName),
    };
  }

  Iterable<ChatStreamEvent> _mapStreamEvent(
    core.TextStreamEvent event,
    _LegacyStreamState state,
  ) sync* {
    switch (event) {
      case core.TextDeltaEvent(:final delta):
        state.text.write(delta);
        yield TextDeltaEvent(delta);
      case core.ReasoningDeltaEvent(:final delta):
        state.thinking.write(delta);
        yield ThinkingDeltaEvent(delta);
      case core.ToolInputStartEvent(:final toolCallId, :final toolName):
        state.startToolCall(toolCallId, toolName);
      case core.ToolInputDeltaEvent(:final toolCallId, :final delta):
        final toolCall = state.appendToolCallDelta(toolCallId, delta);
        if (toolCall != null) {
          yield ToolCallDeltaEvent(toolCall);
        }
      case core.ToolInputErrorEvent(
          :final toolCallId,
          :final toolName,
          :final errorText,
          :final input
        ):
        state.failToolCall(
          toolCallId: toolCallId,
          toolName: toolName,
          input: input,
        );
        yield ErrorEvent(GenericError(errorText));
      case core.ToolCallEvent(:final toolCall):
        final legacyToolCall = _toLegacyToolCall(
          toolCall.toolCallId,
          toolCall.toolName,
          toolCall.input,
        );
        state.completeToolCall(legacyToolCall);
        yield ToolCallDeltaEvent(legacyToolCall);
      case core.FinishEvent(:final usage):
        yield CompletionEvent(
          _LegacyChatResponse(
            text: state.text.isEmpty ? null : state.text.toString(),
            toolCalls: state.completedToolCalls.isEmpty
                ? null
                : state.completedToolCalls,
            thinking: state.thinking.isEmpty ? null : state.thinking.toString(),
            usage: _convertUsage(usage),
          ),
        );
      case core.ErrorEvent(:final error):
        yield ErrorEvent(_toLegacyError(error));
      default:
        break;
    }
  }

  Future<T> _awaitWithCancellation<T>(
    Future<T> operation,
    TransportCancellation? cancelToken,
  ) async {
    if (cancelToken == null) {
      return operation;
    }

    return Future.any([
      operation,
      cancelToken.whenCancelled.then<T>((_) => throw const CancelledError()),
    ]);
  }
}

final class _LegacyStreamState {
  final StringBuffer text = StringBuffer();
  final StringBuffer thinking = StringBuffer();
  final Map<String, _LegacyToolCallState> _toolCalls = {};
  final List<ToolCall> completedToolCalls = <ToolCall>[];

  void startToolCall(String toolCallId, String toolName) {
    _toolCalls.putIfAbsent(
      toolCallId,
      () => _LegacyToolCallState(
        toolCallId: toolCallId,
        toolName: toolName,
      ),
    );
  }

  ToolCall? appendToolCallDelta(String toolCallId, String delta) {
    final state = _toolCalls[toolCallId];
    if (state == null) {
      return null;
    }

    state.arguments.write(delta);
    return ToolCall(
      id: state.toolCallId,
      callType: 'function',
      function: FunctionCall(
        name: state.toolName,
        arguments: state.arguments.toString(),
      ),
    );
  }

  void completeToolCall(ToolCall toolCall) {
    _toolCalls.remove(toolCall.id);
    completedToolCalls.add(toolCall);
  }

  void failToolCall({
    required String toolCallId,
    required String toolName,
    Object? input,
  }) {
    _toolCalls.remove(toolCallId);
    completedToolCalls.removeWhere((toolCall) => toolCall.id == toolCallId);
    if (input != null) {
      completedToolCalls.add(
        ToolCall(
          id: toolCallId,
          callType: 'function',
          function: FunctionCall(
            name: toolName,
            arguments: _encodeJsonValue(input),
          ),
        ),
      );
    }
  }
}

final class _LegacyToolCallState {
  final String toolCallId;
  final String toolName;
  final StringBuffer arguments = StringBuffer();

  _LegacyToolCallState({
    required this.toolCallId,
    required this.toolName,
  });
}

final class _LegacyChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final String? thinking;

  @override
  final UsageInfo? usage;

  const _LegacyChatResponse({
    this.text,
    this.toolCalls,
    this.thinking,
    this.usage,
  });

  factory _LegacyChatResponse.fromResult(core.GenerateTextResult result) {
    final text = result.text.isEmpty ? null : result.text;
    final toolCalls = result.content
        .whereType<core.ToolCallContentPart>()
        .map(
          (part) => _toLegacyToolCall(
            part.toolCall.toolCallId,
            part.toolCall.toolName,
            part.toolCall.input,
          ),
        )
        .toList(growable: false);

    return _LegacyChatResponse(
      text: text,
      toolCalls: toolCalls.isEmpty ? null : toolCalls,
      thinking: result.reasoningText,
      usage: _convertUsage(result.usage),
    );
  }
}

ToolCall _toLegacyToolCall(
  String toolCallId,
  String toolName,
  Object? input,
) {
  return ToolCall(
    id: toolCallId,
    callType: 'function',
    function: FunctionCall(
      name: toolName,
      arguments: _encodeJsonValue(input),
    ),
  );
}

UsageInfo? _convertUsage(core.UsageStats? usage) {
  if (usage == null) {
    return null;
  }

  return UsageInfo(
    promptTokens: usage.inputTokens,
    completionTokens: usage.outputTokens,
    totalTokens: usage.totalTokens,
    reasoningTokens: usage.reasoningTokens,
  );
}

LLMError _toLegacyError(Object error) {
  if (error is LLMError) {
    return error;
  }

  if (error is core.ModelWarning) {
    return GenericError(error.message);
  }

  final message = error.toString();
  if (message.toLowerCase().contains('cancel')) {
    return CancelledError(message);
  }

  return GenericError(message);
}

Object? _decodeToolResultOutput({
  required String encodedOutput,
  required String fallbackText,
}) {
  if (encodedOutput.trim().isNotEmpty) {
    return _decodeJsonValue(encodedOutput);
  }

  if (fallbackText.isNotEmpty) {
    return fallbackText;
  }

  return null;
}

Object? _decodeJsonValue(String encoded) {
  final normalized = encoded.trim();
  if (normalized.isEmpty) {
    return null;
  }

  try {
    return jsonDecode(normalized);
  } catch (_) {
    return normalized;
  }
}

String _encodeJsonValue(Object? value) {
  if (value == null) {
    return '{}';
  }

  if (value is String) {
    return value;
  }

  return jsonEncode(value);
}

Map<String, Object?> _normalizeMap(Map<String, dynamic> value) {
  return value.map(
    (key, entryValue) => MapEntry(
      key,
      _normalizeJsonValue(entryValue),
    ),
  );
}

Object? _normalizeJsonValue(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value.map(_normalizeJsonValue).toList(growable: false),
    Map() => value.map(
        (key, nestedValue) => MapEntry(
          key as String,
          _normalizeJsonValue(nestedValue),
        ),
      ),
    _ => value.toString(),
  };
}
