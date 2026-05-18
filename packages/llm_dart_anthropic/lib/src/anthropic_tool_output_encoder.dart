import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_cache_control.dart';
import 'anthropic_file_source_encoder.dart';

final class AnthropicToolOutputEncoder {
  final AnthropicCacheControlEncoder cacheControlEncoder;
  final AnthropicFileSourceEncoder fileSourceEncoder;

  const AnthropicToolOutputEncoder({
    this.cacheControlEncoder = const AnthropicCacheControlEncoder(),
    this.fileSourceEncoder = const AnthropicFileSourceEncoder(),
  });

  Object? encode(
    ToolOutput output, {
    required String path,
  }) {
    if (output is ExecutionDeniedToolOutput) {
      return output.reason ?? 'Tool execution denied';
    }

    if (output is ContentToolOutput) {
      return _encodeContentOutput(
        output.parts,
        path: path,
      );
    }

    final value = output.value;
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      return value;
    }

    return jsonEncode(
      normalizeJsonValue(value, path: path),
    );
  }

  List<Object?> _encodeContentOutput(
    List<ToolOutputContentPart> parts, {
    required String path,
  }) {
    return [
      for (var index = 0; index < parts.length; index++)
        _encodeContentPart(
          parts[index],
          path: '$path.parts[$index]',
        ),
    ];
  }

  Object _encodeContentPart(
    ToolOutputContentPart part, {
    required String path,
  }) {
    return switch (part) {
      TextToolOutputContentPart(
        :final text,
        :final providerOptions,
      ) =>
        _encodeTextBlock(
          text,
          providerOptions: providerOptions,
          path: path,
        ),
      JsonToolOutputContentPart(
        :final value,
        :final providerOptions,
      ) =>
        _encodeTextBlock(
          jsonEncode(normalizeJsonValue(value, path: '$path.value')),
          providerOptions: providerOptions,
          path: path,
        ),
      FileToolOutputContentPart(
        :final mediaType,
        :final filename,
        :final data,
        :final providerOptions,
      ) =>
        _encodeFileBlock(
          mediaType: mediaType,
          filename: filename,
          data: data,
          providerOptions: providerOptions,
          path: path,
        ),
      CustomToolOutputContentPart(
        :final kind,
        :final data,
        :final providerOptions,
      ) =>
        _encodeTextBlock(
          jsonEncode(
            normalizeJsonValue(
              {
                'type': 'custom',
                'kind': kind,
                if (data != null) 'data': data,
              },
              path: '$path.data',
            ),
          ),
          providerOptions: providerOptions,
          path: path,
        ),
    };
  }

  Map<String, Object?> _encodeTextBlock(
    String text, {
    required ProviderPromptPartOptions? providerOptions,
    required String path,
  }) {
    return cacheControlEncoder.applyToBlock(
      {
        'type': 'text',
        'text': text,
      },
      providerOptions: providerOptions,
      path: path,
    );
  }

  Map<String, Object?> _encodeFileBlock({
    required String mediaType,
    required String? filename,
    required FileData data,
    required ProviderPromptPartOptions? providerOptions,
    required String path,
  }) {
    return cacheControlEncoder.applyToBlock(
      fileSourceEncoder.encodeToolOutputFileBlock(
        mediaType: mediaType,
        filename: filename,
        data: data,
        path: path,
      ),
      providerOptions: providerOptions,
      path: path,
    );
  }
}
