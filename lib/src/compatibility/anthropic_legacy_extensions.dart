import 'dart:convert';

import '../../models/chat_models.dart';
import '../../models/tool_models.dart';

final class AnthropicLegacyCacheControl {
  final String type;
  final String? ttl;

  const AnthropicLegacyCacheControl({
    required this.type,
    this.ttl,
  });

  const AnthropicLegacyCacheControl.ephemeral({
    this.ttl,
  }) : type = 'ephemeral';

  Map<String, Object?> toJson() {
    return {
      'type': type,
      if (ttl != null) 'ttl': ttl,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is AnthropicLegacyCacheControl &&
        other.type == type &&
        other.ttl == ttl;
  }

  @override
  int get hashCode => Object.hash(type, ttl);
}

sealed class AnthropicLegacyPromptBlock {
  final AnthropicLegacyCacheControl? cacheControl;

  const AnthropicLegacyPromptBlock({
    this.cacheControl,
  });
}

final class AnthropicLegacyTextBlock extends AnthropicLegacyPromptBlock {
  final String text;

  const AnthropicLegacyTextBlock({
    required this.text,
    super.cacheControl,
  });
}

final class AnthropicLegacyImageBlock extends AnthropicLegacyPromptBlock {
  final String mediaType;
  final Uri? uri;
  final List<int>? bytes;

  const AnthropicLegacyImageBlock({
    required this.mediaType,
    this.uri,
    this.bytes,
    super.cacheControl,
  });
}

final class AnthropicLegacyDocumentBlock extends AnthropicLegacyPromptBlock {
  final String mediaType;
  final String? title;
  final Uri? uri;
  final List<int>? bytes;

  const AnthropicLegacyDocumentBlock({
    required this.mediaType,
    this.title,
    this.uri,
    this.bytes,
    super.cacheControl,
  });
}

final class AnthropicLegacyToolUseBlock extends AnthropicLegacyPromptBlock {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;

  const AnthropicLegacyToolUseBlock({
    required this.toolCallId,
    required this.toolName,
    this.input,
    required this.providerExecuted,
    required this.isDynamic,
    this.title,
  });
}

final class AnthropicLegacyToolResultBlock extends AnthropicLegacyPromptBlock {
  final String blockType;
  final String toolCallId;
  final Object? output;
  final bool isError;
  final String? customKind;
  final Map<String, Object?>? rawBlock;

  const AnthropicLegacyToolResultBlock({
    required this.blockType,
    required this.toolCallId,
    this.output,
    required this.isError,
    this.customKind,
    this.rawBlock,
  });
}

final class AnthropicLegacyMessageAnalysis {
  final List<Tool> messageTools;
  final List<AnthropicLegacyPromptBlock> promptBlocks;
  final AnthropicLegacyCacheControl? cacheControl;

  const AnthropicLegacyMessageAnalysis({
    this.messageTools = const [],
    this.promptBlocks = const [],
    this.cacheControl,
  });
}

final class AnthropicLegacyExtensionAnalysis {
  final List<AnthropicLegacyMessageAnalysis> messageAnalyses;

  const AnthropicLegacyExtensionAnalysis({
    this.messageAnalyses = const [],
  });

  List<Tool> get messageTools {
    return [
      for (final analysis in messageAnalyses) ...analysis.messageTools,
    ];
  }

  List<AnthropicLegacyCacheControl> get cacheControls {
    return [
      for (final analysis in messageAnalyses)
        if (analysis.cacheControl != null) analysis.cacheControl!,
    ];
  }

  bool get hasAmbiguousToolCacheControl {
    return cacheControls.toSet().length > 1;
  }

  AnthropicLegacyCacheControl? get toolCacheControl {
    if (cacheControls.isEmpty || hasAmbiguousToolCacheControl) {
      return null;
    }

    return cacheControls.first;
  }
}

AnthropicLegacyExtensionAnalysis analyzeAnthropicLegacyMessageExtensions(
  List<ChatMessage> messages,
) {
  return AnthropicLegacyExtensionAnalysis(
    messageAnalyses: [
      for (var index = 0; index < messages.length; index++)
        analyzeAnthropicLegacyMessage(
          messages[index],
          messageIndex: index,
        ),
    ],
  );
}

AnthropicLegacyMessageAnalysis analyzeAnthropicLegacyMessage(
  ChatMessage message, {
  required int messageIndex,
}) {
  if (message.extensions.isEmpty) {
    return const AnthropicLegacyMessageAnalysis();
  }

  if (message.extensions.length != 1 ||
      !message.extensions.containsKey('anthropic')) {
    throw UnsupportedError(
      'Anthropic compatibility only supports the "anthropic" message extension.',
    );
  }

  if (message.messageType is! TextMessage) {
    throw UnsupportedError(
      'Anthropic compatibility only supports legacy message extensions on text messages.',
    );
  }

  final anthropicData = _asMap(
    message.extensions['anthropic'],
    path: 'messages[$messageIndex].extensions.anthropic',
  );
  final extraKeys = anthropicData.keys.where((key) => key != 'contentBlocks');
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports anthropic.contentBlocks in message extensions.',
    );
  }

  final contentBlocks = anthropicData['contentBlocks'];
  if (contentBlocks == null) {
    if (message.role != ChatRole.system && message.content.isEmpty) {
      throw UnsupportedError(
        'Anthropic compatibility requires non-system legacy messages with extensions to keep non-empty text content.',
      );
    }

    return const AnthropicLegacyMessageAnalysis();
  }

  if (contentBlocks is! List) {
    throw UnsupportedError(
      'Anthropic contentBlocks must be a list.',
    );
  }

  final messageTools = <Tool>[];
  final promptBlocks = <AnthropicLegacyPromptBlock>[];
  AnthropicLegacyCacheControl? cacheControl;

  for (var blockIndex = 0; blockIndex < contentBlocks.length; blockIndex++) {
    final block = _asMap(
      contentBlocks[blockIndex],
      path:
          'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
    );

    if (_isAnthropicCacheMarker(block)) {
      final parsedCacheControl = _parseCacheControl(
        block['cache_control'],
        path:
            'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex].cache_control',
      );

      if (cacheControl != null && cacheControl != parsedCacheControl) {
        throw UnsupportedError(
          'Anthropic compatibility does not support multiple cache policies in one legacy message.',
        );
      }

      cacheControl = parsedCacheControl;
      continue;
    }

    if (block['type'] == 'tools') {
      if (block.containsKey('cache_control')) {
        throw UnsupportedError(
          'Anthropic compatibility expects tool cache metadata to be carried by the cache marker block, not the tools block itself.',
        );
      }

      messageTools.addAll(
        _parseToolsBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'text') {
      promptBlocks.add(
        _parseTextBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'image') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw image blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseImageBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'document') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw document blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseDocumentBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'tool_use' || block['type'] == 'server_tool_use') {
      if (message.role != ChatRole.assistant) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw tool-use blocks on assistant messages.',
        );
      }

      promptBlocks.add(
        _parseToolUseBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'mcp_tool_use') {
      if (message.role != ChatRole.assistant) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw MCP tool-use blocks on assistant messages.',
        );
      }

      promptBlocks.add(
        _parseMcpToolUseBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw tool-result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'mcp_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw MCP tool-result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseMcpToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'web_search_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw web-search tool-result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseProviderNativeToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
          expectedType: 'web_search_tool_result',
          expectedContentType: List,
          customKind: 'anthropic.result.web_search',
        ),
      );
      continue;
    }

    if (block['type'] == 'web_fetch_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw web-fetch tool-result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseProviderNativeToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
          expectedType: 'web_fetch_tool_result',
          expectedContentType: Map,
          customKind: 'anthropic.result.web_fetch',
        ),
      );
      continue;
    }

    if (block['type'] == 'code_execution_tool_result' ||
        block['type'] == 'bash_code_execution_tool_result' ||
        block['type'] == 'text_editor_code_execution_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw ${block['type']} blocks on user messages.',
        );
      }

      _throwBridgeIncompatibleExecutionResultBlock(
        _parseRequiredString(
          block['type'],
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex].type',
        ),
      );
    }

    if (block['type'] == 'tool_search_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw tool_search_tool_result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseProviderNativeToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
          expectedType: 'tool_search_tool_result',
          expectedContentType: Map,
          customKind: 'anthropic.result.tool_search',
        ),
      );
      continue;
    }

    throw UnsupportedError(
      'Anthropic compatibility only supports raw text/image/document/tool replay blocks, cache markers, and tools blocks inside legacy message extensions.',
    );
  }

  if (message.role != ChatRole.system && message.content.isEmpty) {
    if (promptBlocks.isEmpty &&
        (cacheControl != null || messageTools.isNotEmpty)) {
      throw UnsupportedError(
        'Anthropic compatibility requires non-system legacy messages with extensions to keep non-empty text content.',
      );
    }

    if (promptBlocks.isEmpty) {
      throw UnsupportedError(
        'Anthropic compatibility requires non-system legacy messages with extensions to produce non-empty prompt content.',
      );
    }
  }

  return AnthropicLegacyMessageAnalysis(
    messageTools: messageTools,
    promptBlocks: promptBlocks,
    cacheControl: cacheControl,
  );
}

bool _isAnthropicCacheMarker(Map<String, Object?> block) {
  return block['type'] == 'text' &&
      block['text'] == '' &&
      block['cache_control'] != null;
}

AnthropicLegacyTextBlock _parseTextBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'text' && key != 'cache_control',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/text/cache_control in raw text blocks.',
    );
  }

  final text = block['text'];
  if (text is! String) {
    throw UnsupportedError(
      'Anthropic text block at $path requires a string text field.',
    );
  }

  return AnthropicLegacyTextBlock(
    text: text,
    cacheControl: block['cache_control'] == null
        ? null
        : _parseCacheControl(
            block['cache_control'],
            path: '$path.cache_control',
          ),
  );
}

AnthropicLegacyImageBlock _parseImageBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'source' && key != 'cache_control',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/source/cache_control in raw image blocks.',
    );
  }

  final source = _asMap(
    block['source'],
    path: '$path.source',
  );
  final sourceType = source['type'];
  if (sourceType is! String || sourceType.isEmpty) {
    throw UnsupportedError(
      'Anthropic image source at $path.source requires a type.',
    );
  }

  final cacheControl = block['cache_control'] == null
      ? null
      : _parseCacheControl(
          block['cache_control'],
          path: '$path.cache_control',
        );

  switch (sourceType) {
    case 'base64':
      final mediaType = _parseRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (!_supportedImageMediaTypes.contains(mediaType)) {
        throw UnsupportedError(
          'Anthropic compatibility only supports JPEG, PNG, GIF, and WebP raw image blocks.',
        );
      }

      final data = _parseRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyImageBlock(
        mediaType: mediaType,
        bytes: _decodeBase64(
          data,
          path: '$path.source.data',
        ),
        cacheControl: cacheControl,
      );
    case 'url':
      return AnthropicLegacyImageBlock(
        mediaType: 'image/*',
        uri: _parseHttpUri(
          source['url'],
          path: '$path.source.url',
        ),
        cacheControl: cacheControl,
      );
    default:
      throw UnsupportedError(
        'Anthropic compatibility only supports base64 and url raw image sources.',
      );
  }
}

AnthropicLegacyDocumentBlock _parseDocumentBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) =>
        key != 'type' &&
        key != 'source' &&
        key != 'title' &&
        key != 'cache_control',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/source/title/cache_control in raw document blocks.',
    );
  }

  final source = _asMap(
    block['source'],
    path: '$path.source',
  );
  final sourceType = source['type'];
  if (sourceType is! String || sourceType.isEmpty) {
    throw UnsupportedError(
      'Anthropic document source at $path.source requires a type.',
    );
  }

  final title = block['title'];
  if (title != null && (title is! String || title.isEmpty)) {
    throw UnsupportedError(
      'Anthropic document title at $path.title must be a non-empty string when provided.',
    );
  }

  final cacheControl = block['cache_control'] == null
      ? null
      : _parseCacheControl(
          block['cache_control'],
          path: '$path.cache_control',
        );

  switch (sourceType) {
    case 'base64':
      final mediaType = _parseRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (mediaType != 'application/pdf') {
        throw UnsupportedError(
          'Anthropic compatibility only supports base64 PDF raw document blocks.',
        );
      }

      final data = _parseRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyDocumentBlock(
        mediaType: mediaType,
        title: title as String?,
        bytes: _decodeBase64(
          data,
          path: '$path.source.data',
        ),
        cacheControl: cacheControl,
      );
    case 'text':
      final mediaType = _parseRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (mediaType != 'text/plain') {
        throw UnsupportedError(
          'Anthropic compatibility only supports text/plain raw text-document blocks.',
        );
      }

      final data = _parseRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyDocumentBlock(
        mediaType: mediaType,
        title: title as String?,
        bytes: utf8.encode(data),
        cacheControl: cacheControl,
      );
    default:
      throw UnsupportedError(
        'Anthropic compatibility only supports base64 PDF and text/plain raw document sources.',
      );
  }
}

AnthropicLegacyToolUseBlock _parseToolUseBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'id' && key != 'name' && key != 'input',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/id/name/input in raw tool-use blocks.',
    );
  }

  final type = _parseRequiredString(
    block['type'],
    path: '$path.type',
  );

  return AnthropicLegacyToolUseBlock(
    toolCallId: _parseRequiredString(
      block['id'],
      path: '$path.id',
    ),
    toolName: _parseRequiredString(
      block['name'],
      path: '$path.name',
    ),
    input: _normalizeJsonPayload(
      block['input'],
      path: '$path.input',
    ),
    providerExecuted: type == 'server_tool_use',
    isDynamic: type == 'server_tool_use',
  );
}

AnthropicLegacyToolUseBlock _parseMcpToolUseBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) =>
        key != 'type' &&
        key != 'id' &&
        key != 'name' &&
        key != 'server_name' &&
        key != 'input',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/id/name/server_name/input in raw MCP tool-use blocks.',
    );
  }

  return AnthropicLegacyToolUseBlock(
    toolCallId: _parseRequiredString(
      block['id'],
      path: '$path.id',
    ),
    toolName: 'mcp.${_parseRequiredString(block['name'], path: '$path.name')}',
    title: _parseRequiredString(
      block['server_name'],
      path: '$path.server_name',
    ),
    input: _normalizeJsonPayload(
      block['input'],
      path: '$path.input',
    ),
    providerExecuted: true,
    isDynamic: true,
  );
}

AnthropicLegacyToolResultBlock _parseToolResultBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) =>
        key != 'type' &&
        key != 'tool_use_id' &&
        key != 'content' &&
        key != 'is_error',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/tool_use_id/content/is_error in raw tool-result blocks.',
    );
  }

  final content = block['content'];
  if (content != null && content is! String) {
    throw UnsupportedError(
      'Anthropic compatibility only supports string tool_result content when replaying raw legacy blocks.',
    );
  }

  final isError = block['is_error'];
  if (isError != null && isError is! bool) {
    throw UnsupportedError(
      'Anthropic tool_result is_error at $path.is_error must be a boolean when provided.',
    );
  }

  return AnthropicLegacyToolResultBlock(
    blockType: 'tool_result',
    toolCallId: _parseRequiredString(
      block['tool_use_id'],
      path: '$path.tool_use_id',
    ),
    output: content,
    isError: isError == true,
  );
}

AnthropicLegacyToolResultBlock _parseMcpToolResultBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) =>
        key != 'type' &&
        key != 'tool_use_id' &&
        key != 'content' &&
        key != 'is_error',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/tool_use_id/content/is_error in raw MCP tool-result blocks.',
    );
  }

  final isError = block['is_error'];
  if (isError != null && isError is! bool) {
    throw UnsupportedError(
      'Anthropic mcp_tool_result is_error at $path.is_error must be a boolean when provided.',
    );
  }

  final output = _normalizeJsonPayload(
    block['content'],
    path: '$path.content',
  );
  if (output == null) {
    throw UnsupportedError(
      'Anthropic compatibility requires non-null content for raw MCP tool-result blocks.',
    );
  }

  return AnthropicLegacyToolResultBlock(
    blockType: 'mcp_tool_result',
    toolCallId: _parseRequiredString(
      block['tool_use_id'],
      path: '$path.tool_use_id',
    ),
    output: output,
    isError: isError == true,
  );
}

AnthropicLegacyToolResultBlock _parseProviderNativeToolResultBlock(
  Map<String, Object?> block, {
  required String path,
  required String expectedType,
  required Type expectedContentType,
  required String customKind,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'tool_use_id' && key != 'content',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/tool_use_id/content in raw $expectedType blocks.',
    );
  }

  final content = _normalizeJsonPayload(
    block['content'],
    path: '$path.content',
  );
  final hasExpectedContentShape = expectedContentType == List
      ? content is List
      : expectedContentType == Map
          ? content is Map<String, Object?>
          : false;
  if (content == null || !hasExpectedContentShape) {
    throw UnsupportedError(
      'Anthropic compatibility only supports $expectedContentType content in raw $expectedType blocks.',
    );
  }

  return AnthropicLegacyToolResultBlock(
    blockType: expectedType,
    toolCallId: _parseRequiredString(
      block['tool_use_id'],
      path: '$path.tool_use_id',
    ),
    output: content,
    isError: false,
    customKind: customKind,
    rawBlock: _asMap(
      _normalizeJsonPayload(
        block,
        path: path,
      ),
      path: path,
    ),
  );
}

Never _throwBridgeIncompatibleExecutionResultBlock(String blockType) {
  throw UnsupportedError(
    'Anthropic compatibility does not bridge raw $blockType blocks in legacy message extensions yet. '
    'Use the provider-owned anthropic.result.code_execution replay path in the new Anthropic API, or keep this request on the old Anthropic provider path.',
  );
}

AnthropicLegacyCacheControl _parseCacheControl(
  Object? value, {
  required String path,
}) {
  final map = _asMap(value, path: path);
  final type = map['type'];
  if (type is! String || type.isEmpty) {
    throw UnsupportedError('Anthropic cache control at $path requires a type.');
  }

  if (type != 'ephemeral') {
    throw UnsupportedError(
      'Anthropic compatibility only supports ephemeral cache controls today.',
    );
  }

  final ttl = map['ttl'];
  if (ttl != null && (ttl is! String || ttl.isEmpty)) {
    throw UnsupportedError(
      'Anthropic cache control ttl at $path must be a non-empty string when provided.',
    );
  }

  return AnthropicLegacyCacheControl.ephemeral(
    ttl: ttl as String?,
  );
}

String _parseRequiredString(
  Object? value, {
  required String path,
}) {
  if (value is! String || value.isEmpty) {
    throw UnsupportedError(
      'Expected a non-empty string at $path.',
    );
  }

  return value;
}

Uri _parseHttpUri(
  Object? value, {
  required String path,
}) {
  final raw = _parseRequiredString(
    value,
    path: path,
  );
  final uri = Uri.tryParse(raw);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    throw UnsupportedError(
      'Expected an HTTP or HTTPS URI at $path.',
    );
  }

  return uri;
}

List<int> _decodeBase64(
  String value, {
  required String path,
}) {
  try {
    return base64Decode(value);
  } catch (_) {
    throw UnsupportedError(
      'Expected valid base64 data at $path.',
    );
  }
}

Object? _normalizeJsonPayload(
  Object? value, {
  required String path,
}) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }

  if (value is List) {
    return [
      for (var index = 0; index < value.length; index++)
        _normalizeJsonPayload(
          value[index],
          path: '$path[$index]',
        ),
    ];
  }

  if (value is Map) {
    final normalized = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw UnsupportedError('Expected a string key at $path.');
      }

      normalized[entry.key as String] = _normalizeJsonPayload(
        entry.value,
        path: '$path.${entry.key}',
      );
    }
    return normalized;
  }

  throw UnsupportedError(
    'Expected a JSON-safe value at $path, but received ${value.runtimeType}.',
  );
}

const Set<String> _supportedImageMediaTypes = {
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
};

List<Tool> _parseToolsBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final rawTools = block['tools'];
  if (rawTools is! List) {
    throw UnsupportedError(
        'Anthropic tools block at $path must contain a tools list.');
  }

  final tools = <Tool>[];
  for (var index = 0; index < rawTools.length; index++) {
    final rawTool = rawTools[index];
    final toolMap = _asMap(rawTool, path: '$path.tools[$index]');
    final tool = Tool.fromJson(
      toolMap.map(
        (key, value) => MapEntry(key, _toDynamic(value)),
      ),
    );

    if (tool.toolType != 'function') {
      throw UnsupportedError(
        'Anthropic compatibility only supports function tools in legacy message extensions.',
      );
    }

    tools.add(tool);
  }

  return tools;
}

Map<String, Object?> _asMap(
  Object? value, {
  required String path,
}) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, nestedValue) {
        if (key is! String) {
          throw UnsupportedError('Expected a string key at $path.');
        }

        return MapEntry(key, _toObject(nestedValue));
      },
    );
  }

  throw UnsupportedError('Expected a map at $path.');
}

Object? _toObject(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }

  if (value is List) {
    return value.map(_toObject).toList(growable: false);
  }

  if (value is Map) {
    return value.map(
      (key, nestedValue) {
        if (key is! String) {
          throw UnsupportedError(
              'Expected a string key in Anthropic legacy metadata.');
        }

        return MapEntry(key, _toObject(nestedValue));
      },
    );
  }

  return value.toString();
}

dynamic _toDynamic(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }

  if (value is List) {
    return value.map(_toDynamic).toList(growable: false);
  }

  if (value is Map<String, Object?>) {
    return value.map(
      (key, nestedValue) => MapEntry(key, _toDynamic(nestedValue)),
    );
  }

  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _toDynamic(nestedValue),
      ),
    );
  }

  return value.toString();
}
