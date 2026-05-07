import 'dart:convert';

import '../../../../core/llm_error.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/anthropic/config.dart';

part 'request_builder_body.dart';
part 'request_builder_messages.dart';
part 'request_builder_models.dart';
part 'request_builder_tools.dart';
part 'request_builder_validation.dart';

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
    final processedData = _processAnthropicMessages(messages);
    final processedTools = _processAnthropicTools(config, messages, tools);

    if (processedData.anthropicMessages.isEmpty) {
      throw const InvalidRequestError(
        'At least one non-system message is required',
      );
    }

    _validateAnthropicMessageSequence(processedData.anthropicMessages);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': processedData.anthropicMessages,
      'max_tokens': config.maxTokens ?? 1024,
      'stream': stream,
    };

    _addAnthropicSystemContent(body, config, processedData);
    _addAnthropicTools(body, config, processedTools);
    _addAnthropicOptionalParameters(body, config);

    return body;
  }

  /// Build request body for Anthropic token counting API.
  Map<String, dynamic> buildTokenCountRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) {
    final processedData = _processAnthropicMessages(messages);
    final processedTools = _processAnthropicTools(config, messages, tools);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': processedData.anthropicMessages,
    };

    _addAnthropicSystemContent(body, config, processedData);

    if (processedTools.tools.isNotEmpty) {
      body['tools'] = processedTools.tools
          .map((tool) => _convertAnthropicTool(config, tool))
          .toList();
    }

    final thinkingConfig = _buildAnthropicThinkingConfig(config);
    if (thinkingConfig != null) {
      body['thinking'] = thinkingConfig;
    }

    return body;
  }
}
