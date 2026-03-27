import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'anthropic_options.dart';
import 'anthropic_tools.dart';

final class AnthropicMessagesRequest {
  final Map<String, Object?> body;
  final List<String> betaFeatures;
  final List<ModelWarning> warnings;

  AnthropicMessagesRequest({
    required Map<String, Object?> body,
    List<String> betaFeatures = const [],
    List<ModelWarning> warnings = const [],
  })  : body = Map.unmodifiable(body),
        betaFeatures = List.unmodifiable(betaFeatures),
        warnings = List.unmodifiable(warnings);
}

final class AnthropicMessagesCodec {
  static const int _defaultMaxTokens = 1024;
  static const int _defaultThinkingBudgetTokens = 1024;
  static const String _interleavedThinkingBeta =
      'interleaved-thinking-2025-05-14';
  static const String _mcpClientBeta = 'mcp-client-2025-04-04';

  const AnthropicMessagesCodec();

  AnthropicMessagesRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required AnthropicChatModelSettings settings,
    required AnthropicGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    final warnings = <ModelWarning>[];
    final betaFeatures = <String>{};
    final blocks = _groupPrompt(prompt);
    final system = <Map<String, Object?>>[];
    final messages = <Map<String, Object?>>[];
    var sawConversationBlock = false;

    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      switch (block.type) {
        case _PromptBlockType.system:
          if (sawConversationBlock) {
            throw UnsupportedError(
              'Anthropic requests only support system messages before the first conversation block.',
            );
          }
          system.addAll(_encodeSystemBlock(block));
        case _PromptBlockType.user:
          sawConversationBlock = true;
          messages.add(_encodeUserBlock(block));
        case _PromptBlockType.assistant:
          sawConversationBlock = true;
          if (_encodeAssistantBlock(
                block,
                trimTrailingText: index == blocks.length - 1,
              )
              case final encodedAssistantBlock?) {
            messages.add(encodedAssistantBlock);
          }
      }
    }

    if (messages.isEmpty) {
      throw ArgumentError(
        'Anthropic requests require at least one non-system prompt message.',
      );
    }

    final extendedThinking = providerOptions.extendedThinking == true;
    final interleavedThinking = providerOptions.interleavedThinking == true;
    final mcpServers = providerOptions.mcpServers;
    final nativeTools = providerOptions.tools ?? settings.tools;
    var maxTokens = options.maxOutputTokens ?? _defaultMaxTokens;
    final temperature = _normalizeTemperature(
      options.temperature,
      warnings: warnings,
    );
    double? topP = options.topP;
    int? topK = options.topK;
    Map<String, Object?>? thinking;

    if (providerOptions.thinkingBudgetTokens != null && !extendedThinking) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.compatibility,
          field: 'thinkingBudgetTokens',
          message:
              'thinkingBudgetTokens is ignored when extendedThinking is not enabled.',
        ),
      );
    }

    if (extendedThinking) {
      var thinkingBudget =
          providerOptions.thinkingBudgetTokens ?? _defaultThinkingBudgetTokens;
      if (providerOptions.thinkingBudgetTokens == null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'thinkingBudgetTokens',
            message:
                'thinkingBudgetTokens is required when extendedThinking is enabled. Using the default budget of 1024 tokens.',
          ),
        );
      } else if (thinkingBudget < _defaultThinkingBudgetTokens) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'thinkingBudgetTokens',
            message:
                'Anthropic extended thinking requires a minimum budget of 1024 tokens. The budget has been raised to 1024.',
          ),
        );
        thinkingBudget = _defaultThinkingBudgetTokens;
      }

      if (temperature != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'temperature',
            message: 'temperature is not supported when thinking is enabled.',
          ),
        );
      }

      if (topP != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topP',
            message: 'topP is not supported when thinking is enabled.',
          ),
        );
        topP = null;
      }

      if (topK != null) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.unsupported,
            field: 'topK',
            message: 'topK is not supported when thinking is enabled.',
          ),
        );
        topK = null;
      }

      maxTokens += thinkingBudget;
      thinking = {
        'type': 'enabled',
        'budget_tokens': thinkingBudget,
      };
    } else if (temperature != null && topP != null) {
      warnings.add(
        const ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'topP',
          message: 'topP is ignored when temperature is set for Anthropic.',
        ),
      );
      topP = null;
    }

    if (interleavedThinking) {
      if (!extendedThinking) {
        warnings.add(
          const ModelWarning(
            type: ModelWarningType.compatibility,
            field: 'interleavedThinking',
            message:
                'interleavedThinking requires extendedThinking to be enabled. The beta header has not been added.',
          ),
        );
      } else {
        betaFeatures.add(_interleavedThinkingBeta);
      }
    }

    final toolConfiguration = _resolveToolConfiguration(
      tools: tools,
      nativeTools: nativeTools,
      toolChoice: toolChoice,
    );

    final body = <String, Object?>{
      'model': modelId,
      'messages': messages,
      'max_tokens': maxTokens,
      'stream': stream,
      if (system.isNotEmpty) 'system': system,
      if (!extendedThinking && temperature != null) 'temperature': temperature,
      if (options.stopSequences != null && options.stopSequences!.isNotEmpty)
        'stop_sequences': options.stopSequences,
      if (topP != null) 'top_p': topP,
      if (topK != null) 'top_k': topK,
      if (thinking != null) 'thinking': thinking,
      if (providerOptions.serviceTier != null)
        'service_tier': providerOptions.serviceTier,
      if (providerOptions.metadata != null &&
          providerOptions.metadata!.isNotEmpty)
        'metadata': _normalizeJsonObject(
          providerOptions.metadata!,
          path: 'metadata',
        ),
      if (providerOptions.container != null)
        'container': providerOptions.container,
      if (mcpServers != null && mcpServers.isNotEmpty)
        'mcp_servers': mcpServers.map((server) => server.toJson()).toList(),
      if (toolConfiguration.tools != null) 'tools': toolConfiguration.tools,
      if (toolConfiguration.toolChoice != null)
        'tool_choice': toolConfiguration.toolChoice,
    };

    if (mcpServers != null && mcpServers.isNotEmpty) {
      betaFeatures.add(_mcpClientBeta);
    }

    final sortedBetas = betaFeatures.toList(growable: false)..sort();

    return AnthropicMessagesRequest(
      body: body,
      betaFeatures: sortedBetas,
      warnings: warnings,
    );
  }

  _AnthropicToolConfiguration _resolveToolConfiguration({
    required List<FunctionToolDefinition> tools,
    required List<AnthropicNativeTool> nativeTools,
    required ToolChoice? toolChoice,
  }) {
    if ((tools.isEmpty && nativeTools.isEmpty) || toolChoice is NoneToolChoice) {
      return const _AnthropicToolConfiguration();
    }

    final encodedTools = <Map<String, Object?>>[
      for (final tool in tools)
        {
          'name': tool.name,
          if (tool.description != null) 'description': tool.description,
          'input_schema': tool.inputSchema.toJson(),
          if (tool.strict != null) 'strict': tool.strict,
        },
      for (final tool in nativeTools) tool.toJson(),
    ];

    final encodedToolChoice = switch (toolChoice) {
      null => null,
      AutoToolChoice() => const {
          'type': 'auto',
        },
      RequiredToolChoice() => const {
          'type': 'any',
        },
      SpecificToolChoice(toolName: final toolName) => {
          'type': 'tool',
          'name': toolName,
        },
      NoneToolChoice() => null,
    };

    return _AnthropicToolConfiguration(
      tools: encodedTools,
      toolChoice: encodedToolChoice,
    );
  }

  List<_PromptBlock> _groupPrompt(List<PromptMessage> prompt) {
    final blocks = <_PromptBlock>[];
    _PromptBlock? currentBlock;

    for (final message in prompt) {
      final type = switch (message) {
        SystemPromptMessage() => _PromptBlockType.system,
        AssistantPromptMessage() => _PromptBlockType.assistant,
        UserPromptMessage() || ToolPromptMessage() => _PromptBlockType.user,
      };

      if (currentBlock?.type != type) {
        currentBlock = _PromptBlock(type);
        blocks.add(currentBlock);
      }

      currentBlock!.messages.add(message);
    }

    return blocks;
  }

  List<Map<String, Object?>> _encodeSystemBlock(_PromptBlock block) {
    final content = <Map<String, Object?>>[];

    for (final message in block.messages) {
      if (message is! SystemPromptMessage) {
        throw StateError('Expected a system prompt block.');
      }

      for (final part in message.parts) {
        if (part is! TextPromptPart) {
          throw UnsupportedError(
            'Anthropic system prompt part ${part.runtimeType} is not supported yet.',
          );
        }

        content.add({
          'type': 'text',
          'text': part.text,
        });
      }
    }

    return content;
  }

  Map<String, Object?> _encodeUserBlock(_PromptBlock block) {
    final content = <Map<String, Object?>>[];

    for (final message in block.messages) {
      if (message case UserPromptMessage(:final parts)) {
        for (final part in parts) {
          content.add(_encodeUserPart(part));
        }
        continue;
      }

      if (message case ToolPromptMessage(:final parts)) {
        // Anthropic requires tool results to be replayed as user-role content.
        for (final part in parts) {
          content.addAll(_encodeToolParts(part));
        }
        continue;
      }

      throw StateError('Expected a user/tool prompt block.');
    }

    if (content.isEmpty) {
      throw ArgumentError('Anthropic user messages cannot be empty.');
    }

    return {
      'role': 'user',
      'content': content,
    };
  }

  Map<String, Object?>? _encodeAssistantBlock(
    _PromptBlock block, {
    required bool trimTrailingText,
  }) {
    final content = <Map<String, Object?>>[];

    for (var messageIndex = 0;
        messageIndex < block.messages.length;
        messageIndex++) {
      final message = block.messages[messageIndex];
      if (message is! AssistantPromptMessage) {
        throw StateError('Expected an assistant prompt block.');
      }

      for (var partIndex = 0; partIndex < message.parts.length; partIndex++) {
        final part = message.parts[partIndex];
        final isLastAssistantPart = trimTrailingText &&
            messageIndex == block.messages.length - 1 &&
            partIndex == message.parts.length - 1;

        if (part is TextPromptPart) {
          final text = isLastAssistantPart ? part.text.trimRight() : part.text;
          if (text.isEmpty) {
            continue;
          }

          content.add({
            'type': 'text',
            'text': text,
          });
          continue;
        }

        if (part is ToolCallPromptPart) {
          final input = _normalizeJsonValue(
                part.input,
                path: 'assistant.toolCall(${part.toolCallId}).input',
              ) ??
              const <String, Object?>{};

          if (part.providerExecuted) {
            if (part.toolName.startsWith('mcp.')) {
              final serverName = part.title?.trim();
              if (serverName == null || serverName.isEmpty) {
                throw UnsupportedError(
                  'Anthropic MCP tool replay requires a non-empty server title.',
                );
              }

              content.add({
                'type': 'mcp_tool_use',
                'id': part.toolCallId,
                'name': part.toolName.substring(4),
                'server_name': serverName,
                'input': input,
              });
              continue;
            }

            content.add({
              'type': 'server_tool_use',
              'id': part.toolCallId,
              'name': part.toolName,
              'input': input,
            });
            continue;
          }

          content.add({
            'type': 'tool_use',
            'id': part.toolCallId,
            'name': part.toolName,
            'input': input,
          });
          continue;
        }

        if (part is ToolApprovalRequestPromptPart) {
          continue;
        }

        if (part is ToolResultPromptPart) {
          continue;
        }

        if (part is ToolApprovalResponsePromptPart) {
          continue;
        }

        if (part is ReasoningPromptPart ||
            part is FilePromptPart ||
            part is ReasoningFilePromptPart ||
            part is CustomPromptPart) {
          continue;
        }

        throw UnsupportedError(
          'Anthropic assistant prompt part ${part.runtimeType} is not supported yet.',
        );
      }
    }

    if (content.isEmpty) {
      return null;
    }

    return {
      'role': 'assistant',
      'content': content,
    };
  }

  Map<String, Object?> _encodeUserPart(PromptPart part) {
    if (part is TextPromptPart) {
      return {
        'type': 'text',
        'text': part.text,
      };
    }

    if (part is ImagePromptPart) {
      return {
        'type': 'image',
        'source': _encodeBinarySource(
          mediaType: _normalizeImageMediaType(part.mediaType),
          uri: part.uri,
          bytes: part.bytes,
          path: 'user.image',
        ),
      };
    }

    if (part is FilePromptPart) {
      return _encodeFilePromptPart(part);
    }

    throw UnsupportedError(
      'Anthropic user prompt part ${part.runtimeType} is not supported yet.',
    );
  }

  Map<String, Object?> _encodeFilePromptPart(FilePromptPart part) {
    if (part.mediaType == 'application/pdf') {
      return {
        'type': 'document',
        'source': _encodeBinarySource(
          mediaType: part.mediaType,
          uri: part.uri,
          bytes: part.bytes,
          path: 'user.document',
        ),
        if (part.filename != null) 'title': part.filename,
      };
    }

    if (part.mediaType == 'text/plain') {
      return {
        'type': 'document',
        'source': _encodeTextDocumentSource(part),
        if (part.filename != null) 'title': part.filename,
      };
    }

    throw UnsupportedError(
      'Anthropic document media type ${part.mediaType} is not supported yet.',
    );
  }

  Iterable<Map<String, Object?>> _encodeToolParts(PromptPart part) sync* {
    if (part is ToolResultPromptPart) {
      if (part.toolName.startsWith('mcp.')) {
        yield {
          'type': 'mcp_tool_result',
          'tool_use_id': part.toolCallId,
          'content': _normalizeJsonValue(
                part.output,
                path: 'toolResult(${part.toolCallId}).output',
              ) ??
              const <String, Object?>{},
          if (part.isError) 'is_error': true,
        };
        return;
      }

      yield {
        'type': 'tool_result',
        'tool_use_id': part.toolCallId,
        'content': _encodeToolOutput(
          part.output,
          path: 'toolResult(${part.toolCallId}).output',
        ),
        if (part.isError) 'is_error': true,
      };
      return;
    }

    if (part is ToolApprovalResponsePromptPart) {
      return;
    }

    throw UnsupportedError(
      'Anthropic tool prompt part ${part.runtimeType} is not supported yet.',
    );
  }

  Map<String, Object?> _encodeBinarySource({
    required String mediaType,
    required Uri? uri,
    required List<int>? bytes,
    required String path,
  }) {
    if (bytes != null) {
      return {
        'type': 'base64',
        'media_type': mediaType,
        'data': base64Encode(bytes),
      };
    }

    if (uri != null && _isHttpUri(uri)) {
      return {
        'type': 'url',
        'url': uri.toString(),
      };
    }

    throw UnsupportedError(
      'Anthropic $path requires in-memory bytes or an HTTP/HTTPS URI.',
    );
  }

  Map<String, Object?> _encodeTextDocumentSource(FilePromptPart part) {
    if (part.bytes != null) {
      return {
        'type': 'text',
        'media_type': 'text/plain',
        'data': utf8.decode(part.bytes!),
      };
    }

    if (part.uri != null && _isHttpUri(part.uri!)) {
      return {
        'type': 'url',
        'url': part.uri.toString(),
      };
    }

    throw UnsupportedError(
      'Anthropic text documents require UTF-8 bytes or an HTTP/HTTPS URI.',
    );
  }

  String _normalizeImageMediaType(String mediaType) {
    return mediaType == 'image/*' ? 'image/jpeg' : mediaType;
  }

  double? _normalizeTemperature(
    double? value, {
    required List<ModelWarning> warnings,
  }) {
    if (value == null) {
      return null;
    }

    if (value > 1) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'temperature',
          message:
              '$value exceeds Anthropic maximum temperature of 1.0. It has been clamped to 1.0.',
        ),
      );
      return 1;
    }

    if (value < 0) {
      warnings.add(
        ModelWarning(
          type: ModelWarningType.unsupported,
          field: 'temperature',
          message:
              '$value is below Anthropic minimum temperature of 0. It has been clamped to 0.',
        ),
      );
      return 0;
    }

    return value;
  }

  Map<String, Object?> _normalizeJsonObject(
    Map<String, Object?> value, {
    required String path,
  }) {
    final normalized = _normalizeJsonValue(value, path: path);
    if (normalized case final Map<String, Object?> map) {
      return map;
    }

    throw UnsupportedError('Expected a JSON object at $path.');
  }

  Object? _normalizeJsonValue(
    Object? value, {
    required String path,
  }) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is Map) {
      final normalized = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw UnsupportedError('Expected a string key at $path.');
        }

        normalized[key] = _normalizeJsonValue(
          entry.value,
          path: '$path.$key',
        );
      }
      return normalized;
    }

    if (value is List) {
      return [
        for (var index = 0; index < value.length; index++)
          _normalizeJsonValue(
            value[index],
            path: '$path[$index]',
          ),
      ];
    }

    throw UnsupportedError(
      'Expected a JSON-safe value at $path, but received ${value.runtimeType}.',
    );
  }

  String _encodeToolOutput(
    Object? output, {
    required String path,
  }) {
    if (output == null) {
      return 'null';
    }

    if (output is String) {
      return output;
    }

    return jsonEncode(
      _normalizeJsonValue(output, path: path),
    );
  }

  bool _isHttpUri(Uri uri) {
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}

enum _PromptBlockType {
  system,
  user,
  assistant,
}

final class _PromptBlock {
  final _PromptBlockType type;
  final List<PromptMessage> messages = [];

  _PromptBlock(this.type);
}

final class _AnthropicToolConfiguration {
  final List<Map<String, Object?>>? tools;
  final Map<String, Object?>? toolChoice;

  const _AnthropicToolConfiguration({
    this.tools,
    this.toolChoice,
  });
}
