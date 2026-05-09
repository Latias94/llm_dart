import '../../models/chat_models.dart';
import 'anthropic_legacy_extensions_block_collector.dart';
import 'anthropic_legacy_extensions_models.dart';
import 'anthropic_legacy_extensions_utils.dart';

AnthropicLegacyExtensionAnalysis analyzeAnthropicLegacyMessageExtensions(
  List<ChatMessage> messages,
) {
  return AnthropicLegacyExtensionAnalysis(
    messageAnalyses: [
      for (var index = 0; index < messages.length; index++)
        analyzeAnthropicLegacyMessage(
          messages[index],
          messageIndex: index,
        ),
    ],
  );
}

AnthropicLegacyMessageAnalysis analyzeAnthropicLegacyMessage(
  ChatMessage message, {
  required int messageIndex,
}) {
  if (message.extensions.isEmpty) {
    return const AnthropicLegacyMessageAnalysis();
  }

  if (message.extensions.length != 1 ||
      !message.extensions.containsKey('anthropic')) {
    throw UnsupportedError(
      'Anthropic compatibility only supports the "anthropic" message extension.',
    );
  }

  if (message.messageType is! TextMessage) {
    throw UnsupportedError(
      'Anthropic compatibility only supports legacy message extensions on text messages.',
    );
  }

  final anthropicData = asAnthropicLegacyMap(
    message.extensions['anthropic'],
    path: 'messages[$messageIndex].extensions.anthropic',
  );
  final extraKeys = anthropicData.keys.where((key) => key != 'contentBlocks');
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports anthropic.contentBlocks in message extensions.',
    );
  }

  final contentBlocks = anthropicData['contentBlocks'];
  if (contentBlocks == null) {
    if (message.role != ChatRole.system && message.content.isEmpty) {
      throw UnsupportedError(
        'Anthropic compatibility requires non-system legacy messages with extensions to keep non-empty text content.',
      );
    }

    return const AnthropicLegacyMessageAnalysis();
  }

  if (contentBlocks is! List) {
    throw UnsupportedError(
      'Anthropic contentBlocks must be a list.',
    );
  }

  final collector = AnthropicLegacyMessageBlockCollector(
    messageRole: message.role,
    messageIndex: messageIndex,
  );

  for (var blockIndex = 0; blockIndex < contentBlocks.length; blockIndex++) {
    collector.collect(
      contentBlocks[blockIndex],
      blockIndex: blockIndex,
    );
  }

  collector.validateMessageContent(message.content);
  return collector.build();
}
