import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_options.dart';

final class AnthropicCacheControlEncoder {
  const AnthropicCacheControlEncoder();

  Map<String, Object?> applyToBlock(
    Map<String, Object?> block, {
    required ProviderPromptPartOptions? providerOptions,
    required String path,
  }) {
    final cacheControl = encodeProviderOptions(
      providerOptions,
      path: '$path.providerOptions',
    );
    if (cacheControl == null) {
      return block;
    }

    return {
      ...block,
      'cache_control': cacheControl,
    };
  }

  Map<String, Object?>? encodeProviderOptions(
    ProviderPromptPartOptions? providerOptions, {
    required String path,
  }) {
    final options =
        resolveProviderPromptPartOptions<AnthropicPromptPartOptions>(
      providerOptions,
      parameterName: path,
      expectedTypeName: 'AnthropicPromptPartOptions',
      usageContext: 'Anthropic prompt parts',
    );
    final cacheControl = options?.cacheControl;
    if (cacheControl == null) {
      return null;
    }

    return normalizeCacheControl(
      cacheControl.toJson(),
      path: '$path.cacheControl',
    );
  }

  Map<String, Object?> normalizeCacheControl(
    Object? value, {
    required String path,
  }) {
    final normalized = normalizeJsonValue(
      value,
      path: path,
    );
    if (normalized is! Map<String, Object?>) {
      throw UnsupportedError('Expected a cache control object at $path.');
    }

    final type = normalized['type'];
    if (type is! String || type.isEmpty) {
      throw UnsupportedError('Expected a cache control type at $path.');
    }

    final ttl = normalized['ttl'];
    if (ttl != null && (ttl is! String || ttl.isEmpty)) {
      throw UnsupportedError(
        'Expected a non-empty cache control ttl string at $path.',
      );
    }

    return {
      'type': type,
      if (ttl != null) 'ttl': ttl,
    };
  }
}
