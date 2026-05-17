import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_result_content_codec.dart';
import 'anthropic_result_metadata.dart';
import 'anthropic_result_tool_codec.dart';
import 'anthropic_result_util.dart';

final class AnthropicMessagesResultCodec {
  const AnthropicMessagesResultCodec();

  GenerateTextResult decodeResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    final content = <ContentPart>[];
    final toolDescriptors = <String, AnthropicResultToolDescriptor>{};

    for (final rawPart in anthropicResultAsList(response['content'])) {
      final part = anthropicResultAsMap(rawPart);
      if (part == null) {
        continue;
      }

      final type = anthropicResultAsString(part['type']);
      if (type == 'text') {
        content.addAll(decodeAnthropicResultTextParts(part));
        continue;
      }

      if (type == 'thinking') {
        content.add(decodeAnthropicResultThinkingPart(part));
        continue;
      }

      if (type == 'redacted_thinking') {
        content.add(decodeAnthropicResultRedactedThinkingPart(part));
        continue;
      }

      if (type == 'compaction') {
        content.add(decodeAnthropicResultCompactionPart(part));
        continue;
      }

      if (type == 'tool_use') {
        final toolCallPart = decodeAnthropicResultToolUsePart(
          part,
          toolDescriptors,
        );
        if (toolCallPart != null) {
          content.add(toolCallPart);
        }
        continue;
      }

      if (type == 'server_tool_use') {
        final toolCallPart = decodeAnthropicResultServerToolUsePart(
          part,
          toolDescriptors,
        );
        if (toolCallPart != null) {
          content.add(toolCallPart);
        }
        continue;
      }

      if (type == 'mcp_tool_use') {
        final toolCallPart = decodeAnthropicResultMcpToolUsePart(
          part,
          toolDescriptors,
        );
        if (toolCallPart != null) {
          content.add(toolCallPart);
        }
        continue;
      }

      if (isAnthropicResultToolResultPart(type)) {
        content.addAll(
          decodeAnthropicResultToolResultParts(part, toolDescriptors),
        );
        continue;
      }

      if (type != null) {
        final customPart = decodeAnthropicResultCustomPart(part);
        if (customPart != null) {
          content.add(customPart);
        }
      }
    }

    return GenerateTextResult(
      content: content,
      finishReason: mapAnthropicResultFinishReason(
        anthropicResultAsString(response['stop_reason']),
      ),
      rawFinishReason: anthropicResultAsString(response['stop_reason']),
      responseId: anthropicResultAsString(response['id']),
      responseModelId: anthropicResultAsString(response['model']),
      usage: decodeAnthropicResultUsage(
        anthropicResultAsMap(response['usage']),
      ),
      providerMetadata: anthropicResultProviderMetadata({
        'usage': anthropicResultAsMap(response['usage']),
        'stopSequence': anthropicResultAsString(response['stop_sequence']),
        'container': decodeAnthropicResultContainer(
          anthropicResultAsMap(response['container']),
        ),
        'contextManagement':
            anthropicResultAsMap(response['context_management']),
      }),
      warnings: warnings,
    );
  }
}
