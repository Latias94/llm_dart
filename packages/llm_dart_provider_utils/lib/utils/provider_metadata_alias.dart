import 'package:llm_dart_core/llm_dart_core.dart';

/// Inject a providerMetadata alias key into an existing providerMetadata map.
///
/// This is used for Vercel AI SDK parity, where the response metadata can be
/// accessed either via the base provider id key (e.g. `openai`) or a more
/// specific capability key (e.g. `openai.chat`, `openai.responses`).
///
/// The alias payload is selected as:
/// - `providerMetadata[baseKey]` when present, else
/// - the single value in the map when the map has exactly one entry.
///
/// If [aliasKey] already exists, the map is returned unchanged.
Map<String, dynamic> withProviderMetadataAlias(
  Map<String, dynamic> providerMetadata, {
  required String baseKey,
  required String aliasKey,
}) {
  if (providerMetadata.containsKey(aliasKey)) return providerMetadata;

  final copy = Map<String, dynamic>.from(providerMetadata);

  dynamic payload;
  if (copy.containsKey(baseKey)) {
    payload = copy[baseKey];
  } else if (copy.length == 1) {
    payload = copy.values.first;
  }

  if (payload != null) {
    copy[aliasKey] = payload;
  }

  return copy;
}

/// Wrap a [ChatResponse] so its `providerMetadata` includes [aliasKey].
ChatResponse wrapChatResponseWithProviderMetadataAlias(
  ChatResponse response, {
  required String baseKey,
  required String aliasKey,
}) {
  if (response is ChatResponseWithAssistantMessage) {
    return _ChatResponseWithAssistantMessageAliasedProviderMetadata(
      response,
      baseKey: baseKey,
      aliasKey: aliasKey,
    );
  }
  return _ChatResponseAliasedProviderMetadata(
    response,
    baseKey: baseKey,
    aliasKey: aliasKey,
  );
}

/// Wrap a chat stream so `CompletionEvent.response.providerMetadata` includes
/// [aliasKey].
Stream<ChatStreamEvent> wrapChatStreamWithProviderMetadataAlias(
  Stream<ChatStreamEvent> stream, {
  required String baseKey,
  required String aliasKey,
}) async* {
  await for (final event in stream) {
    switch (event) {
      case CompletionEvent(response: final response):
        yield CompletionEvent(
          wrapChatResponseWithProviderMetadataAlias(
            response,
            baseKey: baseKey,
            aliasKey: aliasKey,
          ),
        );
      default:
        yield event;
    }
  }
}

/// Wrap an LLM stream parts stream so `LLMProviderMetadataPart` and
/// `LLMFinishPart.response.providerMetadata` include [aliasKey].
Stream<LLMStreamPart> wrapStreamPartsWithProviderMetadataAlias(
  Stream<LLMStreamPart> stream, {
  required String baseKey,
  required String aliasKey,
}) async* {
  await for (final part in stream) {
    switch (part) {
      case LLMProviderMetadataPart(providerMetadata: final providerMetadata):
        yield LLMProviderMetadataPart(
          withProviderMetadataAlias(
            providerMetadata,
            baseKey: baseKey,
            aliasKey: aliasKey,
          ),
        );
      case LLMFinishPart(response: final response):
        yield LLMFinishPart(
          wrapChatResponseWithProviderMetadataAlias(
            response,
            baseKey: baseKey,
            aliasKey: aliasKey,
          ),
        );
      default:
        yield part;
    }
  }
}

class _ChatResponseAliasedProviderMetadata implements ChatResponse {
  final ChatResponse _inner;
  final String baseKey;
  final String aliasKey;

  _ChatResponseAliasedProviderMetadata(
    this._inner, {
    required this.baseKey,
    required this.aliasKey,
  });

  @override
  String? get text => _inner.text;

  @override
  List<ToolCall>? get toolCalls => _inner.toolCalls;

  @override
  String? get thinking => _inner.thinking;

  @override
  UsageInfo? get usage => _inner.usage;

  @override
  Map<String, dynamic>? get providerMetadata {
    final meta = _inner.providerMetadata;
    if (meta == null) return null;
    return withProviderMetadataAlias(
      meta,
      baseKey: baseKey,
      aliasKey: aliasKey,
    );
  }
}

class _ChatResponseWithAssistantMessageAliasedProviderMetadata
    extends _ChatResponseAliasedProviderMetadata
    implements ChatResponseWithAssistantMessage {
  final ChatResponseWithAssistantMessage _innerWithMessage;

  _ChatResponseWithAssistantMessageAliasedProviderMetadata(
    this._innerWithMessage, {
    required String baseKey,
    required String aliasKey,
  }) : super(_innerWithMessage, baseKey: baseKey, aliasKey: aliasKey);

  @override
  ChatMessage get assistantMessage => _innerWithMessage.assistantMessage;
}
