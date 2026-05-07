part of 'anthropic_compat_support.dart';

final class _AnthropicCompatPromptPartConverter {
  const _AnthropicCompatPromptPartConverter();

  core.PromptPart convertAssistantPromptPart(
    AnthropicLegacyPromptBlock block, {
    required Map<String, _AnthropicCompatToolDescriptor> toolDescriptors,
  }) {
    if (block is AnthropicLegacyToolUseBlock) {
      final toolPart = core.ToolCallPromptPart(
        toolCallId: block.toolCallId,
        toolName: block.toolName,
        input: block.input,
        providerExecuted: block.providerExecuted,
        isDynamic: block.isDynamic,
        title: block.title,
      );
      toolDescriptors[block.toolCallId] = _AnthropicCompatToolDescriptor(
        toolName: block.toolName,
      );
      return toolPart;
    }

    return convertPromptPart(block);
  }

  core.PromptPart convertPromptPart(AnthropicLegacyPromptBlock block) {
    final metadata = _cacheMetadata(block.cacheControl);

    return switch (block) {
      AnthropicLegacyTextBlock(:final text) => core.TextPromptPart(
          text,
          providerMetadata: metadata,
        ),
      AnthropicLegacyImageBlock(
        :final mediaType,
        :final uri,
        :final bytes,
      ) =>
        core.ImagePromptPart(
          mediaType: mediaType,
          data: bytes != null
              ? core.FileBytesData(bytes)
              : core.FileUrlData(
                  uri ??
                      (throw ArgumentError.value(
                        block,
                        'block',
                        'Anthropic image blocks require bytes or a URI.',
                      )),
                ),
          providerMetadata: metadata,
        ),
      AnthropicLegacyDocumentBlock(
        :final mediaType,
        :final title,
        :final uri,
        :final bytes,
      ) =>
        core.FilePromptPart(
          mediaType: mediaType,
          filename: title,
          data: bytes != null
              ? core.FileBytesData(bytes)
              : core.FileUrlData(
                  uri ??
                      (throw ArgumentError.value(
                        block,
                        'block',
                        'Anthropic document blocks require bytes or a URI.',
                      )),
                ),
          providerMetadata: metadata,
        ),
      AnthropicLegacyToolUseBlock() ||
      AnthropicLegacyToolResultBlock() =>
        throw UnsupportedError(
          'Anthropic tool replay blocks require role-aware conversion.',
        ),
    };
  }

  core.ProviderMetadata? _cacheMetadata(
    AnthropicLegacyCacheControl? cacheControl,
  ) {
    if (cacheControl == null) {
      return null;
    }

    return core.ProviderMetadata({
      'anthropic': {
        'cacheControl': cacheControl.toJson(),
      },
    });
  }
}
