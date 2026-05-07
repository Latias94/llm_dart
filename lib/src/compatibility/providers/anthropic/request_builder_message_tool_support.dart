part of 'request_builder.dart';

final class _AnthropicMessageToolSupport {
  const _AnthropicMessageToolSupport();

  List<Map<String, dynamic>> convertToolUseBlocks(List<ToolCall> toolCalls) {
    final content = <Map<String, dynamic>>[];

    for (final toolCall in toolCalls) {
      try {
        final input = jsonDecode(toolCall.function.arguments);
        content.add({
          'type': 'tool_use',
          'id': toolCall.id,
          'name': toolCall.function.name,
          'input': input,
        });
      } catch (_) {
        content.add({
          'type': 'text',
          'text':
              '[Error: Invalid tool call arguments for ${toolCall.function.name}]',
        });
      }
    }

    return content;
  }

  List<Map<String, dynamic>> convertToolResultBlocks(List<ToolCall> results) {
    return [
      for (final result in results)
        {
          'type': 'tool_result',
          'tool_use_id': result.id,
          'content': result.function.arguments,
          'is_error': inferToolResultError(result.function.arguments),
        },
    ];
  }

  bool inferToolResultError(String resultContent) {
    try {
      final parsed = jsonDecode(resultContent);
      if (parsed is Map<String, dynamic>) {
        return parsed['error'] != null ||
            parsed['is_error'] == true ||
            parsed['success'] == false;
      }
    } catch (_) {
      final lowerContent = resultContent.toLowerCase();
      return lowerContent.contains('error') ||
          lowerContent.contains('failed') ||
          lowerContent.contains('exception');
    }

    return false;
  }
}
