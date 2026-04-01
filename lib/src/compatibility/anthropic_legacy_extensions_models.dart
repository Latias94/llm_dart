part of 'anthropic_legacy_extensions.dart';

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

const Set<String> _supportedImageMediaTypes = {
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
};
