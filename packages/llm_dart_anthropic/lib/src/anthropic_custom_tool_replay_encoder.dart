import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_code_execution_replay.dart';
import 'anthropic_request_json.dart';

final class AnthropicCustomToolReplayEncoder {
  const AnthropicCustomToolReplayEncoder();

  Map<String, Object?>? encode(CustomPromptPart part) {
    switch (part.kind) {
      case 'anthropic.result.web_fetch':
        return _encodeValidatedBlock(
          part,
          expectedType: 'web_fetch_tool_result',
        );
      case 'anthropic.result.web_search':
        return _encodeValidatedBlock(
          part,
          expectedType: 'web_search_tool_result',
        );
      case 'anthropic.result.tool_search':
        final block = _encodeValidatedBlock(
          part,
          expectedType: 'tool_search_tool_result',
        );
        normalizeAnthropicJsonObject(
          block['content'],
          path: 'tool.custom(${part.kind}).block.content',
        );
        return block;
      case 'anthropic.result.code_execution':
        try {
          final replay = AnthropicCodeExecutionReplay.parseData(
            part.data,
            providerMetadata: providerReplayMetadataFromOptions(
              part.providerOptions,
            ),
          );
          return replay.block;
        } on FormatException catch (error) {
          throw UnsupportedError(error.message);
        }
      default:
        return null;
    }
  }

  Map<String, Object?> _encodeValidatedBlock(
    CustomPromptPart part, {
    required String expectedType,
  }) {
    final payload = normalizeAnthropicJsonObject(
      part.data,
      path: 'tool.custom(${part.kind})',
    );
    if (payload['replayRole'] != 'tool') {
      throw UnsupportedError(
        'Anthropic custom tool replay "${part.kind}" requires replayRole="tool".',
      );
    }

    final block = normalizeAnthropicJsonObject(
      payload['block'],
      path: 'tool.custom(${part.kind}).block',
    );
    final blockType = block['type'];
    if (blockType != expectedType) {
      throw UnsupportedError(
        'Anthropic custom tool replay "${part.kind}" requires a $expectedType block.',
      );
    }

    final toolUseId = block['tool_use_id'];
    if (toolUseId is! String || toolUseId.isEmpty) {
      throw UnsupportedError(
        'Anthropic custom tool replay "${part.kind}" requires a non-empty tool_use_id.',
      );
    }

    return block;
  }
}
