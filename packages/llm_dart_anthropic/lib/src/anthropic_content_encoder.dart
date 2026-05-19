import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_cache_control.dart';
import 'anthropic_file_source_encoder.dart';
import 'anthropic_prompt_limitations.dart';
import 'anthropic_tool_output_encoder.dart';

final class AnthropicContentEncoder {
  final AnthropicCacheControlEncoder cacheControlEncoder;
  final AnthropicFileSourceEncoder fileSourceEncoder;
  final AnthropicToolOutputEncoder toolOutputEncoder;

  const AnthropicContentEncoder({
    this.cacheControlEncoder = const AnthropicCacheControlEncoder(),
    this.fileSourceEncoder = const AnthropicFileSourceEncoder(),
    this.toolOutputEncoder = const AnthropicToolOutputEncoder(),
  });

  Map<String, Object?> encodeUserPart(PromptPart part) {
    if (part is TextPromptPart) {
      return encodeTextContent(
        part,
        path: 'user.text',
      );
    }

    if (part is ImagePromptPart) {
      return applyCacheControl(
        {
          'type': 'image',
          'source': fileSourceEncoder.encodeUserBinarySource(
            mediaType: fileSourceEncoder.normalizeImageMediaType(
              part.mediaType,
            ),
            data: part.data,
            path: 'user.image',
          ),
        },
        providerOptions: part.providerOptions,
        path: 'user.image',
      );
    }

    if (part is FilePromptPart) {
      return _encodeFilePromptPart(part);
    }

    throw unsupportedAnthropicPromptPart(role: 'user', part: part);
  }

  Map<String, Object?> encodeTextContent(
    TextPromptPart part, {
    required String path,
    String? text,
  }) {
    return applyCacheControl(
      {
        'type': 'text',
        'text': text ?? part.text,
      },
      providerOptions: part.providerOptions,
      path: path,
    );
  }

  Map<String, Object?> applyCacheControl(
    Map<String, Object?> block, {
    required ProviderPromptPartOptions? providerOptions,
    required String path,
  }) {
    return cacheControlEncoder.applyToBlock(
      block,
      providerOptions: providerOptions,
      path: path,
    );
  }

  Object? encodeToolOutput(
    ToolOutput output, {
    required String path,
  }) {
    return toolOutputEncoder.encode(
      output,
      path: path,
    );
  }

  Map<String, Object?> _encodeFilePromptPart(FilePromptPart part) {
    if (part.mediaType == 'application/pdf') {
      return applyCacheControl(
        {
          'type': 'document',
          'source': fileSourceEncoder.encodeUserBinarySource(
            mediaType: part.mediaType,
            data: part.data,
            path: 'user.document',
          ),
          if (part.filename != null) 'title': part.filename,
        },
        providerOptions: part.providerOptions,
        path: 'user.document',
      );
    }

    if (part.mediaType == 'text/plain') {
      return applyCacheControl(
        {
          'type': 'document',
          'source': fileSourceEncoder.encodeUserTextDocumentSource(
            data: part.data,
            path: 'user.document',
          ),
          if (part.filename != null) 'title': part.filename,
        },
        providerOptions: part.providerOptions,
        path: 'user.document',
      );
    }

    throw unsupportedAnthropicDocumentMediaType(part.mediaType);
  }
}
