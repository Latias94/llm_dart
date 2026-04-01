import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart' as core;

import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/llm_error.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';

part 'legacy_chat_adapter_request.dart';
part 'legacy_chat_adapter_response.dart';
part 'legacy_chat_adapter_streaming.dart';

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

      for (final mappedEvent in _mapLegacyStreamEvent(event, state)) {
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
        responseFormat: _buildCompatResponseFormat(
          config.getExtension<StructuredOutputFormat>('jsonSchema'),
        ),
      ),
      callOptions: core.CallOptions(
        timeout: config.timeout,
        providerOptions: providerOptionsOverride ?? providerOptions,
      ),
    );
  }

  List<core.PromptMessage> convertMessages(List<ChatMessage> messages) {
    return _convertLegacyMessages(
      config: config,
      messages: messages,
      convertMessage: convertMessage,
    );
  }

  List<core.PromptMessage> convertMessage(ChatMessage message) {
    return _convertLegacyMessage(message);
  }
}

final class GoogleLegacyChatCapabilityAdapter
    extends LegacyChatCapabilityAdapter {
  const GoogleLegacyChatCapabilityAdapter({
    required super.model,
    required super.config,
    super.providerOptions,
  });

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
    final state = _GoogleLegacyStreamState();

    await for (final event in model.stream(request)) {
      if (cancelToken?.isCancelled ?? false) {
        throw const CancelledError();
      }

      for (final mappedEvent in _mapGoogleLegacyStreamEvent(event, state)) {
        yield mappedEvent;
      }
    }
  }
}
