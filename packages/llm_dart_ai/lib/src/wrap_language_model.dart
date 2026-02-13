import 'package:llm_dart_core/llm_dart_core.dart';

import 'prompt_input.dart';

/// Wraps a chat model with default per-call request overrides (headers/body).
///
/// This mirrors the Vercel AI SDK idea of a "default settings middleware":
/// a base set of request options is applied to every call, with each call able
/// to further override them via [LLMCallOptions].
///
/// Notes:
/// - Defaults are applied to both non-streaming and streaming calls when the
///   underlying model supports call-level overrides.
/// - Prompt IR calls are supported best-effort by compiling to legacy
///   [ChatMessage] lists when the provider does not implement prompt-native
///   capabilities.
ChatCapability wrapLanguageModel(
  ChatCapability model, {
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
}) {
  if (defaultCallOptions.isEmpty) return model;
  return _DefaultCallOptionsLanguageModel(
    inner: model,
    defaultCallOptions: defaultCallOptions,
  );
}

class _DefaultCallOptionsLanguageModel extends ChatCapability
    implements
        ChatCallOptionsCapability,
        PromptChatCapability,
        PromptChatCallOptionsCapability,
        ChatStreamPartsCapability,
        ChatStreamPartsCallOptionsCapability,
        PromptChatStreamPartsCapability,
        PromptChatStreamPartsCallOptionsCapability {
  final ChatCapability inner;
  final LLMCallOptions defaultCallOptions;

  _DefaultCallOptionsLanguageModel({
    required this.inner,
    required this.defaultCallOptions,
  });

  LLMCallOptions _effective(LLMCallOptions callOptions) =>
      defaultCallOptions.mergedWith(callOptions);

  InvalidRequestError _callOptionsNotSupported(String surface) {
    return InvalidRequestError(
      'This model does not support call-level overrides (headers/body) for $surface. '
      'Implement the corresponding *CallOptionsCapability (or use a provider that does).',
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    final effective = defaultCallOptions;
    if (effective.isEmpty) {
      return inner.chatWithTools(messages, tools, cancelToken: cancelToken);
    }

    if (inner is! ChatCallOptionsCapability) {
      throw _callOptionsNotSupported('chat');
    }

    return (inner as ChatCallOptionsCapability).chatWithToolsWithCallOptions(
      messages,
      tools,
      callOptions: effective,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    final effective = _effective(callOptions);
    if (effective.isEmpty) {
      return inner.chatWithTools(messages, tools, cancelToken: cancelToken);
    }

    if (inner is! ChatCallOptionsCapability) {
      throw _callOptionsNotSupported('chat');
    }

    return (inner as ChatCallOptionsCapability).chatWithToolsWithCallOptions(
      messages,
      tools,
      callOptions: effective,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    final effective = defaultCallOptions;
    if (inner is PromptChatCapability) {
      if (effective.isEmpty) {
        return (inner as PromptChatCapability).chatPrompt(
          prompt,
          tools: tools,
          cancelToken: cancelToken,
        );
      }

      if (inner is! PromptChatCallOptionsCapability) {
        throw _callOptionsNotSupported('Prompt IR chat');
      }

      return (inner as PromptChatCallOptionsCapability).chatPromptWithCallOptions(
        prompt,
        tools: tools,
        callOptions: effective,
        cancelToken: cancelToken,
      );
    }

    requirePromptCapabilityForFileReferenceParts(
      prompt: prompt,
      requiredCapabilityName: '`PromptChatCapability`',
    );

    if (effective.isEmpty) {
      return inner.chatWithTools(
        prompt.toChatMessages(),
        tools,
        cancelToken: cancelToken,
      );
    }

    if (inner is! ChatCallOptionsCapability) {
      throw _callOptionsNotSupported('chat');
    }

    return (inner as ChatCallOptionsCapability).chatWithToolsWithCallOptions(
      prompt.toChatMessages(),
      tools,
      callOptions: effective,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPromptWithCallOptions(
    Prompt prompt, {
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    final effective = _effective(callOptions);
    if (inner is PromptChatCapability) {
      if (effective.isEmpty) {
        return (inner as PromptChatCapability).chatPrompt(
          prompt,
          tools: tools,
          cancelToken: cancelToken,
        );
      }

      if (inner is! PromptChatCallOptionsCapability) {
        throw _callOptionsNotSupported('Prompt IR chat');
      }

      return (inner as PromptChatCallOptionsCapability).chatPromptWithCallOptions(
        prompt,
        tools: tools,
        callOptions: effective,
        cancelToken: cancelToken,
      );
    }

    requirePromptCapabilityForFileReferenceParts(
      prompt: prompt,
      requiredCapabilityName: '`PromptChatCapability`',
    );

    if (effective.isEmpty) {
      return inner.chatWithTools(
        prompt.toChatMessages(),
        tools,
        cancelToken: cancelToken,
      );
    }

    if (inner is! ChatCallOptionsCapability) {
      throw _callOptionsNotSupported('chat');
    }

    return (inner as ChatCallOptionsCapability).chatWithToolsWithCallOptions(
      prompt.toChatMessages(),
      tools,
      callOptions: effective,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    final effective = defaultCallOptions;
    if (effective.isEmpty) {
      if (inner is! ChatStreamPartsCapability) {
        throw UnsupportedError(
          'Model does not support parts-first streaming. Implement '
          '`ChatStreamPartsCapability.chatStreamParts()` (or use a provider that does).',
        );
      }
      return (inner as ChatStreamPartsCapability).chatStreamParts(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      );
    }

    if (inner is! ChatStreamPartsCallOptionsCapability) {
      throw _callOptionsNotSupported('streaming');
    }

    return (inner as ChatStreamPartsCallOptionsCapability)
        .chatStreamPartsWithCallOptions(
      messages,
      tools: tools,
      callOptions: effective,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    final effective = _effective(callOptions);
    if (effective.isEmpty) {
      if (inner is! ChatStreamPartsCapability) {
        throw UnsupportedError(
          'Model does not support parts-first streaming. Implement '
          '`ChatStreamPartsCapability.chatStreamParts()` (or use a provider that does).',
        );
      }
      return (inner as ChatStreamPartsCapability).chatStreamParts(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      );
    }

    if (inner is! ChatStreamPartsCallOptionsCapability) {
      throw _callOptionsNotSupported('streaming');
    }

    return (inner as ChatStreamPartsCallOptionsCapability)
        .chatStreamPartsWithCallOptions(
      messages,
      tools: tools,
      callOptions: effective,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    final effective = defaultCallOptions;
    if (inner is PromptChatStreamPartsCapability) {
      if (effective.isEmpty) {
        return (inner as PromptChatStreamPartsCapability).chatPromptStreamParts(
          prompt,
          tools: tools,
          cancelToken: cancelToken,
        );
      }

      if (inner is! PromptChatStreamPartsCallOptionsCapability) {
        throw _callOptionsNotSupported('Prompt IR streaming');
      }

      return (inner as PromptChatStreamPartsCallOptionsCapability)
          .chatPromptStreamPartsWithCallOptions(
        prompt,
        tools: tools,
        callOptions: effective,
        cancelToken: cancelToken,
      );
    }

    requirePromptCapabilityForFileReferenceParts(
      prompt: prompt,
      requiredCapabilityName: '`PromptChatStreamPartsCapability`',
    );

    return chatStreamParts(
      prompt.toChatMessages(),
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamPartsWithCallOptions(
    Prompt prompt, {
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    final effective = _effective(callOptions);
    if (inner is PromptChatStreamPartsCapability) {
      if (effective.isEmpty) {
        return (inner as PromptChatStreamPartsCapability).chatPromptStreamParts(
          prompt,
          tools: tools,
          cancelToken: cancelToken,
        );
      }

      if (inner is! PromptChatStreamPartsCallOptionsCapability) {
        throw _callOptionsNotSupported('Prompt IR streaming');
      }

      return (inner as PromptChatStreamPartsCallOptionsCapability)
          .chatPromptStreamPartsWithCallOptions(
        prompt,
        tools: tools,
        callOptions: effective,
        cancelToken: cancelToken,
      );
    }

    requirePromptCapabilityForFileReferenceParts(
      prompt: prompt,
      requiredCapabilityName: '`PromptChatStreamPartsCapability`',
    );

    return chatStreamPartsWithCallOptions(
      prompt.toChatMessages(),
      tools: tools,
      callOptions: effective,
      cancelToken: cancelToken,
    );
  }
}

