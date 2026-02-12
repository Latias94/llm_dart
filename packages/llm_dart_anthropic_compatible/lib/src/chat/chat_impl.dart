part of 'package:llm_dart_anthropic_compatible/chat.dart';

/// Anthropic Chat capability implementation
///
/// This module handles all chat-related functionality for Anthropic providers,
/// including streaming, tool calling, and reasoning model support.
///
/// **API Documentation:**
/// - Messages API: https://docs.anthropic.com/en/api/messages
/// - Streaming: https://docs.anthropic.com/en/api/messages-streaming
/// - Tool Use: https://docs.anthropic.com/en/docs/tool-use
/// - Extended Thinking: https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
/// - Token Counting: https://docs.anthropic.com/en/api/messages-count-tokens
class AnthropicChat
    implements
        ChatCapability,
        ModelIdentityCapability,
        PromptChatCapability,
        ChatStreamPartsCapability,
        PromptChatStreamPartsCapability {
  final AnthropicClient client;
  final AnthropicConfig config;
  late final AnthropicRequestBuilder _requestBuilder;

  AnthropicChat(
    this.client,
    this.config, {
    AnthropicRequestBuilder? requestBuilder,
  }) {
    _requestBuilder = requestBuilder ?? AnthropicRequestBuilder(config);
  }

  @override
  String get providerId => config.providerId;

  @override
  String get modelId => config.model;

  String get chatEndpoint => 'messages';

  /// Send a chat request with optional tool support
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/messages
  ///
  /// Supports all Anthropic message types including text, images, PDFs,
  /// tool calls, and extended thinking for supported models.
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    final built = _requestBuilder.buildRequest(messages, tools, false);
    final originalConfig = config.originalConfig;
    final requestMetadata = originalConfig == null
        ? null
        : (emitRequestMetadataEnabled(
            originalConfig.providerOptions,
            config.providerId,
            fallbackProviderId:
                config.providerId == 'anthropic' ? null : 'anthropic',
          )
            ? LLMRequestMetadataPart(
                body: sanitizeRequestBodyForMetadata(built.body),
              )
            : null);
    // Headers including interleaved thinking beta are automatically handled by AnthropicClient
    final responseWithHeaders = await client.postJsonWithHeaders(
      chatEndpoint,
      built.body,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      built.toolNameMapping,
      responseHeaders: responseWithHeaders.headers,
      requestMetadata: requestMetadata,
    );
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async {
    final built = _requestBuilder.buildRequestFromPrompt(prompt, tools, false);
    final originalConfig = config.originalConfig;
    final requestMetadata = originalConfig == null
        ? null
        : (emitRequestMetadataEnabled(
            originalConfig.providerOptions,
            config.providerId,
            fallbackProviderId:
                config.providerId == 'anthropic' ? null : 'anthropic',
          )
            ? LLMRequestMetadataPart(
                body: sanitizeRequestBodyForMetadata(built.body),
              )
            : null);
    final responseWithHeaders = await client.postJsonWithHeaders(
      chatEndpoint,
      built.body,
      cancelToken: cancelToken,
    );
    return _parseResponse(
      responseWithHeaders.json,
      built.toolNameMapping,
      responseHeaders: responseWithHeaders.headers,
      requestMetadata: requestMetadata,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _anthropicChatStreamParts(
      client,
      config,
      _requestBuilder,
      chatEndpoint,
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    final effectiveTools = tools ?? config.tools;
    final built = _requestBuilder.buildRequestFromPrompt(
      prompt,
      effectiveTools,
      true,
    );

    return _anthropicChatStreamPartsFromBuiltRequest(
      client,
      config,
      chatEndpoint,
      built,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt =
        'Summarize in 2-3 sentences:\n${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final request = [ChatMessage.user(prompt)];
    final response = await chat(request);
    final text = response.text;
    if (text == null) {
      throw const GenericError('no text in summary response');
    }
    return text;
  }

  /// Count tokens in messages using Anthropic's token counting API
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/messages-count-tokens
  ///
  /// This uses Anthropic's dedicated endpoint to accurately count tokens
  /// for messages, system prompts, tools, and thinking configurations
  /// without sending an actual chat request. Useful for:
  /// - Cost estimation before sending requests
  /// - Staying within model token limits
  /// - Optimizing prompt length
  Future<int> countTokens(List<ChatMessage> messages,
      {List<Tool>? tools}) async {
    try {
      final requestBody =
          _requestBuilder.buildCountTokensRequestBody(messages, tools);
      final responseData =
          await client.postJson('messages/count_tokens', requestBody);
      return responseData['input_tokens'] as int? ?? 0;
    } catch (e) {
      client.logger.warning('Failed to count tokens: $e');
      // Fallback to rough estimation (4 chars per token)
      final totalChars =
          messages.map((m) => m.content.length).fold(0, (a, b) => a + b);
      return (totalChars / 4).ceil();
    }
  }

  /// Parse response from Anthropic API
  ChatResponse _parseResponse(
    Map<String, dynamic> responseData,
    ToolNameMapping toolNameMapping, {
    Map<String, String>? responseHeaders,
    LLMRequestMetadataPart? requestMetadata,
  }) {
    final id = responseData['id'] as String?;
    final model = responseData['model'] as String?;
    final headers = (responseHeaders != null && responseHeaders.isNotEmpty)
        ? responseHeaders
        : null;

    final responseMetadata = (id != null || model != null || headers != null)
        ? LLMResponseMetadataPart(
            id: id,
            model: model,
            headers: headers,
            body: responseData,
            raw: {
              if (id != null) 'id': id,
              if (model != null) 'model': model,
            },
          )
        : null;

    return AnthropicChatResponse(
      responseData,
      config.providerId,
      toolNameMapping,
      responseMetadata,
      requestMetadata,
    );
  }

  static LLMError _mapAnthropicError(Map<String, dynamic> error) {
    final message = error['message'] as String? ?? 'Unknown error';
    final errorType = error['type'] as String? ?? 'api_error';

    switch (errorType) {
      case 'authentication_error':
        return AuthError(message);
      case 'permission_error':
        return AuthError('Permission denied: $message');
      case 'invalid_request_error':
        return InvalidRequestError(message);
      case 'not_found_error':
        return InvalidRequestError('Not found: $message');
      case 'rate_limit_error':
        return RateLimitError(message);
      case 'api_error':
      case 'overloaded_error':
        return ProviderError('Anthropic API error: $message');
      default:
        return ProviderError('Anthropic API error ($errorType): $message');
    }
  }
}

// `_ToolCallState` moved to `lib/src/chat/tool_call_state.dart`.
