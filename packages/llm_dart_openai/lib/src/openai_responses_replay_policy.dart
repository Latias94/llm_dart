final class OpenAIResponsesReplayPolicy {
  final bool store;
  final bool hasConversation;

  const OpenAIResponsesReplayPolicy({
    required this.store,
    required this.hasConversation,
  });

  bool shouldSkipStoredItem(String? itemId) =>
      hasConversation && itemId != null;

  bool shouldReferenceStoredItem(String? itemId) => store && itemId != null;

  Map<String, Object?> itemReference(String id) {
    return {
      'type': 'item_reference',
      'id': id,
    };
  }
}
