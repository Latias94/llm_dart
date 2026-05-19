import 'package:llm_dart_provider/llm_dart_provider.dart';

enum AnthropicPromptBlockType {
  system,
  user,
  assistant,
}

final class AnthropicPromptBlock {
  final AnthropicPromptBlockType type;
  final List<PromptMessage> messages = [];

  AnthropicPromptBlock(this.type);
}

List<AnthropicPromptBlock> groupAnthropicPromptBlocks(
  List<PromptMessage> prompt,
) {
  final blocks = <AnthropicPromptBlock>[];
  AnthropicPromptBlock? currentBlock;

  for (final message in prompt) {
    final type = switch (message) {
      SystemPromptMessage() => AnthropicPromptBlockType.system,
      AssistantPromptMessage() => AnthropicPromptBlockType.assistant,
      UserPromptMessage() ||
      ToolPromptMessage() =>
        AnthropicPromptBlockType.user,
    };

    if (currentBlock?.type != type) {
      currentBlock = AnthropicPromptBlock(type);
      blocks.add(currentBlock);
    }

    currentBlock!.messages.add(message);
  }

  return blocks;
}
