import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/anthropic/config.dart';
import 'request_builder_body.dart';
import 'request_builder_messages.dart';
import 'request_builder_tools.dart';
import 'request_builder_validation.dart';

/// Helper class to build Anthropic API request bodies
/// Separates the complex request building logic into focused methods
class AnthropicRequestBuilder {
  final AnthropicConfig config;

  AnthropicRequestBuilder(this.config);

  /// Build complete request body for Anthropic API
  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final processedData = processAnthropicMessages(messages);
    final processedTools = processAnthropicTools(config, messages, tools);

    if (processedData.anthropicMessages.isEmpty) {
      throw const InvalidRequestError(
        'At least one non-system message is required',
      );
    }

    validateAnthropicMessageSequence(processedData.anthropicMessages);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': processedData.anthropicMessages,
      'max_tokens': config.maxTokens ?? 1024,
      'stream': stream,
    };

    addAnthropicSystemContent(body, config, processedData);
    addAnthropicTools(body, config, processedTools);
    addAnthropicOptionalParameters(body, config);

    return body;
  }

  /// Build request body for Anthropic token counting API.
  Map<String, dynamic> buildTokenCountRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) {
    final processedData = processAnthropicMessages(messages);
    final processedTools = processAnthropicTools(config, messages, tools);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': processedData.anthropicMessages,
    };

    addAnthropicSystemContent(body, config, processedData);

    if (processedTools.tools.isNotEmpty) {
      body['tools'] = processedTools.tools
          .map((tool) => convertAnthropicTool(config, tool))
          .toList();
    }

    final thinkingConfig = buildAnthropicThinkingConfig(config);
    if (thinkingConfig != null) {
      body['thinking'] = thinkingConfig;
    }

    return body;
  }
}
