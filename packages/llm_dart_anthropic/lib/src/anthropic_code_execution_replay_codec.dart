import 'anthropic_code_execution_replay_json.dart';
import 'anthropic_code_execution_replay_result.dart';

const anthropicCodeExecutionReplayKind = 'anthropic.result.code_execution';
const anthropicCodeExecutionReplaySchema = 'anthropic.execution.result.v1';
const anthropicCodeExecutionCanonicalToolName = 'code_execution';

final class AnthropicCodeExecutionReplayData {
  final String toolCallId;
  final String toolName;
  final AnthropicCodeExecutionBlockType blockType;
  final Map<String, Object?> block;
  final AnthropicCodeExecutionResult result;

  const AnthropicCodeExecutionReplayData({
    required this.toolCallId,
    required this.toolName,
    required this.blockType,
    required this.block,
    required this.result,
  });
}

AnthropicCodeExecutionReplayData anthropicDecodeCodeExecutionReplayBlock({
  required String toolCallId,
  required String toolName,
  required AnthropicCodeExecutionBlockType blockType,
  required Map<String, Object?> block,
}) {
  final normalizedBlock = anthropicReplayNormalizeObject(
    block,
    path: 'block',
  );
  final wireType = anthropicReplayRequiredNonEmptyString(
    normalizedBlock['type'],
    path: 'block.type',
  );
  if (wireType != blockType.value) {
    throw FormatException(
      'Expected block.type to equal ${blockType.value}, got $wireType.',
    );
  }

  final wireToolCallId = anthropicReplayRequiredNonEmptyString(
    normalizedBlock['tool_use_id'],
    path: 'block.tool_use_id',
  );
  if (wireToolCallId != toolCallId) {
    throw FormatException(
      'Expected block.tool_use_id to equal $toolCallId, got $wireToolCallId.',
    );
  }

  final result = anthropicParseExecutionResult(
    anthropicReplayRequiredObject(
      normalizedBlock['content'],
      path: 'block.content',
    ),
    path: 'block.content',
  );

  return AnthropicCodeExecutionReplayData(
    toolCallId: toolCallId,
    toolName: toolName,
    blockType: blockType,
    block: normalizedBlock,
    result: result,
  );
}

AnthropicCodeExecutionReplayData anthropicDecodeCodeExecutionReplayJson(
  Map<String, Object?> json,
) {
  final normalized = anthropicReplayNormalizeObject(
    json,
    path: 'replay',
  );
  final replayRole = anthropicReplayRequiredNonEmptyString(
    normalized['replayRole'],
    path: 'replay.replayRole',
  );
  if (replayRole != 'tool') {
    throw FormatException(
      'Expected replay.replayRole to equal "tool", got $replayRole.',
    );
  }

  final schemaValue = anthropicReplayRequiredNonEmptyString(
    normalized['schema'],
    path: 'replay.schema',
  );
  if (schemaValue != anthropicCodeExecutionReplaySchema) {
    throw FormatException(
      'Expected replay.schema to equal $anthropicCodeExecutionReplaySchema, '
      'got $schemaValue.',
    );
  }

  final blockTypeValue = anthropicReplayRequiredNonEmptyString(
    normalized['blockType'],
    path: 'replay.blockType',
  );
  final blockType = AnthropicCodeExecutionBlockType.tryParse(blockTypeValue);
  if (blockType == null) {
    throw FormatException('Unsupported replay.blockType: $blockTypeValue.');
  }

  return anthropicDecodeCodeExecutionReplayBlock(
    toolCallId: anthropicReplayRequiredNonEmptyString(
      normalized['toolCallId'],
      path: 'replay.toolCallId',
    ),
    toolName: anthropicReplayOptionalString(
          normalized['toolName'],
          path: 'replay.toolName',
        ) ??
        anthropicCodeExecutionCanonicalToolName,
    blockType: blockType,
    block: anthropicReplayRequiredObject(
      normalized['block'],
      path: 'replay.block',
    ),
  );
}

Map<String, Object?> anthropicEncodeCodeExecutionReplayJson(
  AnthropicCodeExecutionReplayData data,
) {
  return {
    'schema': anthropicCodeExecutionReplaySchema,
    'replayRole': 'tool',
    'toolCallId': data.toolCallId,
    'toolName': data.toolName,
    'blockType': data.blockType.value,
    'block': anthropicReplayNormalizeObject(
      data.block,
      path: 'block',
    ),
  };
}
