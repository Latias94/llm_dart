import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    show HttpHeaderUtils;

import '../core/config.dart';
import '../models/tool_models.dart';
import '../models/chat_models.dart';

/// Utility class for common configuration transformations
///
/// This class provides helper methods for converting between unified LLMConfig
/// and provider-specific configurations, reducing code duplication across providers.
///
/// NOTE: Header-building helpers delegate to `HttpHeaderUtils` in the
/// `llm_dart_provider_utils` package and are kept here only for backwards
/// compatibility. New code should prefer `HttpHeaderUtils` directly.
@Deprecated(
  'ConfigUtils is legacy. Use HttpHeaderUtils from '
  'llm_dart_provider_utils for HTTP headers and implement '
  'message conversion inside provider-specific packages.',
)
class ConfigUtils {
  /// Extract common HTTP headers from config
  static Map<String, String> buildHeaders({
    required String apiKey,
    required String authHeaderName,
    String? authPrefix,
    Map<String, String>? additionalHeaders,
  }) =>
      HttpHeaderUtils.buildHeaders(
        apiKey: apiKey,
        authHeaderName: authHeaderName,
        authPrefix: authPrefix,
        additionalHeaders: additionalHeaders,
      );

  /// Build OpenAI-compatible headers
  static Map<String, String> buildOpenAIHeaders(String apiKey) =>
      HttpHeaderUtils.buildOpenAIHeaders(apiKey);

  /// Build Anthropic-compatible headers
  static Map<String, String> buildAnthropicHeaders(String apiKey) =>
      HttpHeaderUtils.buildAnthropicHeaders(apiKey);

  /// Extract common request parameters from LLMConfig
  static Map<String, dynamic> buildCommonParams(LLMConfig config) {
    final params = <String, dynamic>{
      'model': config.model,
    };

    if (config.maxTokens != null) {
      params['max_tokens'] = config.maxTokens;
    }

    if (config.temperature != null) {
      params['temperature'] = config.temperature;
    }

    if (config.topP != null) {
      params['top_p'] = config.topP;
    }

    if (config.topK != null) {
      params['top_k'] = config.topK;
    }

    return params;
  }

  /// Convert ChatMessage list to OpenAI format
  static List<Map<String, dynamic>> convertMessagesToOpenAI(
    List<ChatMessage> messages,
    String? systemPrompt,
  ) {
    final apiMessages = <Map<String, dynamic>>[];

    // Add system message if configured
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      apiMessages.add({'role': 'system', 'content': systemPrompt});
    }

    // Convert messages to OpenAI format
    for (final message in messages) {
      if (message.messageType is ToolResultMessage) {
        // Handle tool results as separate messages
        final toolResults = (message.messageType as ToolResultMessage).results;
        for (final result in toolResults) {
          apiMessages.add({
            'role': 'tool',
            'tool_call_id': result.id,
            'content': result.function.arguments.isNotEmpty
                ? result.function.arguments
                : message.content,
          });
        }
      } else {
        apiMessages.add(_convertMessageToOpenAI(message));
      }
    }

    return apiMessages;
  }

  /// Convert single ChatMessage to OpenAI format
  static Map<String, dynamic> _convertMessageToOpenAI(ChatMessage message) {
    final result = <String, dynamic>{
      'role': message.role.name,
      'content': message.content,
    };

    // Add name field if present
    if (message.name != null) {
      result['name'] = message.name;
    }

    // Handle tool calls for assistant messages
    if (message.messageType is ToolUseMessage) {
      final toolUseMessage = message.messageType as ToolUseMessage;
      result['tool_calls'] =
          toolUseMessage.toolCalls.map((call) => call.toJson()).toList();
    }

    return result;
  }

  /// Convert ChatMessage list to Anthropic format
  static List<Map<String, dynamic>> convertMessagesToAnthropic(
    List<ChatMessage> messages,
  ) {
    final apiMessages = <Map<String, dynamic>>[];

    for (final message in messages) {
      // Skip system messages - they're handled separately in Anthropic
      if (message.role == ChatRole.system) {
        continue;
      }

      apiMessages.add({
        'role': message.role.name,
        'content': message.content,
      });
    }

    return apiMessages;
  }

  /// Extract system prompt from messages or config
  static String? extractSystemPrompt(
    List<ChatMessage> messages,
    String? configSystemPrompt,
  ) {
    // First check for system message in the conversation
    for (final message in messages) {
      if (message.role == ChatRole.system) {
        return message.content;
      }
    }

    // Fall back to config system prompt
    return configSystemPrompt;
  }

  /// Add tools to request body if provided
  static void addToolsToRequest(
    Map<String, dynamic> requestBody,
    List<Tool>? tools,
    ToolChoice? toolChoice,
  ) {
    if (tools != null && tools.isNotEmpty) {
      requestBody['tools'] = tools.map((t) => t.toJson()).toList();

      if (toolChoice != null) {
        requestBody['tool_choice'] = toolChoice.toJson();
      }
    }
  }

  /// Normalize base URL to ensure it ends with a slash
  static String normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  /// Validate required configuration fields
  static void validateRequiredFields(
      LLMConfig config, List<String> requiredFields) {
    final errors = <String>[];

    for (final field in requiredFields) {
      switch (field) {
        case 'apiKey':
          if (config.apiKey == null || config.apiKey!.isEmpty) {
            errors.add('API key is required');
          }
          break;
        case 'model':
          if (config.model.isEmpty) {
            errors.add('Model is required');
          }
          break;
        case 'baseUrl':
          if (config.baseUrl.isEmpty) {
            errors.add('Base URL is required');
          }
          break;
      }
    }

    if (errors.isNotEmpty) {
      throw ArgumentError(
          'Configuration validation failed: ${errors.join(', ')}');
    }
  }

  /// Get extension value with type safety and default
  static T getExtensionOrDefault<T>(
    LLMConfig config,
    String key,
    T defaultValue,
  ) {
    final value = config.getExtension<T>(key);
    return value ?? defaultValue;
  }

  /// Build request timeout from config
  static Duration getRequestTimeout(LLMConfig config) {
    return config.timeout ?? const Duration(seconds: 60);
  }
}
