import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'config.dart';

part 'src/request_builder/messages.dart';
part 'src/request_builder/models.dart';
part 'src/request_builder/optional_parameters.dart';
part 'src/request_builder/prompt.dart';
part 'src/request_builder/system_messages.dart';
part 'src/request_builder/tools.dart';
part 'src/request_builder/validation.dart';

class AnthropicBuiltRequest {
  final Map<String, dynamic> body;
  final ToolNameMapping toolNameMapping;

  const AnthropicBuiltRequest({
    required this.body,
    required this.toolNameMapping,
  });
}

/// Helper class to build Anthropic API request bodies.
class AnthropicRequestBuilder {
  final AnthropicConfig config;

  AnthropicRequestBuilder(this.config);

  String? get _providerOptionsFallbackId =>
      config.providerId == 'anthropic' ? null : 'anthropic';

  Map<String, dynamic>? get _defaultCacheControl {
    final cacheControl = config.cacheControl;
    if (cacheControl == null) return null;
    final type = cacheControl['type'];
    if (type is! String || type.trim().isEmpty) return null;
    return cacheControl;
  }

  Map<String, dynamic>? _cacheControlFromProviderOptions(
    ProviderOptions providerOptions,
  ) {
    if (providerOptions.isEmpty) return null;

    final typed = readProviderOptionMap(
          providerOptions,
          config.providerId,
          'cacheControl',
          fallbackProviderId: _providerOptionsFallbackId,
        ) ??
        readProviderOptionMap(
          providerOptions,
          config.providerId,
          'cache_control',
          fallbackProviderId: _providerOptionsFallbackId,
        );

    if (typed == null) return null;
    final type = typed['type'];
    if (type is! String || type.trim().isEmpty) return null;
    return typed;
  }

  Map<String, dynamic> buildRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    return buildRequest(messages, tools, stream).body;
  }

  /// Build request body for Anthropic's `messages/count_tokens` endpoint.
  ///
  /// This reuses the normal request compilation pipeline (messages + tools +
  /// system prompt + provider-native tools) but omits request-only fields
  /// like `max_tokens` and `stream`.
  Map<String, dynamic> buildCountTokensRequestBody(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) {
    final built = buildRequest(messages, tools, false);
    final body = built.body;

    final result = <String, dynamic>{
      'model': body['model'],
      'messages': body['messages'],
    };

    if (body.containsKey('system')) {
      result['system'] = body['system'];
    }

    if (body.containsKey('tools')) {
      result['tools'] = body['tools'];
    }

    if (body.containsKey('thinking')) {
      result['thinking'] = body['thinking'];
    }

    return result;
  }

  /// Build request body and tool name mapping for a single request.
  ///
  /// This enables collision-safe tool naming when provider-native tools are
  /// enabled (e.g. Anthropic web search).
  AnthropicBuiltRequest buildRequest(
    List<ChatMessage> messages,
    List<Tool>? tools,
    bool stream,
  ) {
    final processedTools = _processTools(messages, tools);
    final toolNameMapping = _createToolNameMapping(processedTools);

    final processedData = _processMessages(messages, toolNameMapping);

    if (processedData.anthropicMessages.isEmpty) {
      throw const InvalidRequestError(
          'At least one non-system message is required');
    }

    _validateMessageSequence(processedData.anthropicMessages);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': processedData.anthropicMessages,
      'max_tokens': config.maxTokens ?? 1024,
      'stream': stream,
    };

    _addSystemContent(body, processedData);
    _addTools(body, processedTools, toolNameMapping);
    _addOptionalParameters(body);

    final extraBodyFromConfig = config.extraBody;
    if (extraBodyFromConfig != null && extraBodyFromConfig.isNotEmpty) {
      body.addAll(extraBodyFromConfig);
    }

    final extraBody = body['extra_body'] as Map<String, dynamic>?;
    if (extraBody != null) {
      body.addAll(extraBody);
      body.remove('extra_body');
    }

    return AnthropicBuiltRequest(body: body, toolNameMapping: toolNameMapping);
  }

  /// Convert a Tool to Anthropic API format.
  Map<String, dynamic> convertTool(Tool tool) {
    try {
      final schema = tool.function.parameters.toJson();

      if (schema['type'] != 'object') {
        throw ArgumentError(
          'Anthropic tools require input_schema to be of type "object". '
          'Tool "${tool.function.name}" has type "${schema['type']}". '
          '\n\nTo fix this, update your tool definition:\n'
          'ParametersSchema(\n'
          '  schemaType: "object",  // <- Change this to "object"\n'
          '  properties: {...},\n'
          '  required: [...],\n'
          ')\n\n'
          'See: https://docs.anthropic.com/en/api/messages#tools',
        );
      }

      final inputSchema = Map<String, dynamic>.from(schema);
      if (!inputSchema.containsKey('properties')) {
        inputSchema['properties'] = <String, dynamic>{};
      }

      final result = <String, dynamic>{
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'No description provided',
        'input_schema': inputSchema,
      };

      if (tool.strict != null) {
        result['strict'] = tool.strict;
      }

      final examples = tool.inputExamples;
      if (examples != null && examples.isNotEmpty) {
        result['input_examples'] = examples;
      }

      final anthropicOptions = tool.providerOptions['anthropic'];
      if (anthropicOptions is Map<String, dynamic>) {
        final deferLoading = anthropicOptions['deferLoading'];
        if (deferLoading is bool) {
          result['defer_loading'] = deferLoading;
        }

        final allowedCallers = anthropicOptions['allowedCallers'];
        if (allowedCallers is List) {
          final callers = allowedCallers.whereType<String>().toList();
          if (callers.isNotEmpty) {
            result['allowed_callers'] = callers;
          }
        }
      }

      return result;
    } on InvalidRequestError {
      rethrow;
    } catch (e) {
      throw ArgumentError(
        'Failed to convert tool "${tool.function.name}" to Anthropic format: $e',
      );
    }
  }
}
