import '../../core/capability.dart';
import '../../models/chat_models.dart';
import 'client.dart';
import 'config.dart';

/// Anthropic cache control
class AnthropicCacheControl {
  final String type;
  final String? ttl;

  const AnthropicCacheControl.ephemeral({this.ttl}) : type = 'ephemeral';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type};
    if (ttl != null) {
      json['ttl'] = ttl;
    }
    return json;
  }
}

/// Cache TTL options for Anthropic
enum AnthropicCacheTtl {
  fiveMinutes(300, '5m'),
  oneHour(3600, '1h');

  const AnthropicCacheTtl(this.seconds, this.value);
  final int seconds;
  final String value;

  /// Create from string value
  static AnthropicCacheTtl? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case '5m':
        return AnthropicCacheTtl.fiveMinutes;
      case '1h':
        return AnthropicCacheTtl.oneHour;
      default:
        return null;
    }
  }
}

/// Anthropic-specific text block with caching support
class AnthropicTextBlock implements ContentBlock {
  final String text;
  final AnthropicCacheControl? cacheControl;

  AnthropicTextBlock(this.text, {this.cacheControl});

  @override
  String get displayText => text;

  @override
  String get providerId => 'anthropic';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': text,
        if (cacheControl != null) 'cache_control': cacheControl!.toJson(),
      };
}

/// Anthropic message builder for provider-specific features
class AnthropicMessageBuilder {
  final MessageBuilder _builder;

  const AnthropicMessageBuilder._(this._builder);

  /// Cached text with TTL
  AnthropicMessageBuilder cachedText(String text, {AnthropicCacheTtl? ttl}) {
    final cacheControl = AnthropicCacheControl.ephemeral(
      ttl: ttl?.value,
    );

    _builder.addBlock(AnthropicTextBlock(text, cacheControl: cacheControl));
    return this;
  }

  /// Direct content block
  AnthropicMessageBuilder contentBlock(Map<String, dynamic> blockData) {
    final type = blockData['type'] as String;

    switch (type) {
      case 'text':
        final text = blockData['text'] as String;
        final cacheData = blockData['cache_control'] as Map<String, dynamic>?;

        if (cacheData != null && cacheData['type'] == 'ephemeral') {
          final ttlString = cacheData['ttl'] as String?;
          final ttl = AnthropicCacheTtl.fromString(ttlString);
          return cachedText(text, ttl: ttl);
        } else {
          _builder.text(text);
          return this;
        }

      default:
        _builder.text(blockData['text']?.toString() ?? '');
        return this;
    }
  }

  /// Multiple content blocks
  AnthropicMessageBuilder contentBlocks(List<Map<String, dynamic>> blocks) {
    for (final block in blocks) {
      contentBlock(block);
    }
    return this;
  }
}

/// Extension to add Anthropic-specific functionality to MessageBuilder
extension AnthropicMessageBuilderExtension on MessageBuilder {
  /// Configure Anthropic-specific features
  MessageBuilder anthropicConfig(
      void Function(AnthropicMessageBuilder) configure) {
    final anthropicBuilder = AnthropicMessageBuilder._(this);
    configure(anthropicBuilder);
    return this;
  }
}

/// Anthropic Models capability implementation
///
/// This module handles model listing functionality for Anthropic providers.
/// Reference: https://docs.anthropic.com/en/api/models-list
class AnthropicModels implements ModelListingCapability {
  final AnthropicClient client;
  final AnthropicConfig config;

  AnthropicModels(this.client, this.config);

  String get modelsEndpoint => 'models';

  @override
  Future<List<AIModel>> models() async {
    return listModels();
  }

  /// List available models from Anthropic API
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/models-list
  ///
  /// Supports pagination with [beforeId], [afterId], and [limit] parameters.
  /// Returns a list of available models with their metadata.
  Future<List<AIModel>> listModels({
    String? beforeId,
    String? afterId,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (beforeId != null) queryParams['before_id'] = beforeId;
      if (afterId != null) queryParams['after_id'] = afterId;
      if (limit != 20) queryParams['limit'] = limit;

      final endpoint = queryParams.isEmpty
          ? modelsEndpoint
          : '$modelsEndpoint?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final responseData = await client.getJson(endpoint);
      final data = responseData['data'] as List?;

      if (data == null) return [];

      return data
          .map((modelData) =>
              AIModel.fromJson(modelData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      client.logger.warning('Failed to list models: $e');
      return [];
    }
  }

  /// Get information about a specific model
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/models
  ///
  /// Returns detailed information about a specific model including its
  /// capabilities, creation date, and display name.
  Future<AIModel?> getModel(String modelId) async {
    try {
      final responseData = await client.getJson('$modelsEndpoint/$modelId');
      return AIModel.fromJson(responseData);
    } catch (e) {
      client.logger.warning('Failed to get model $modelId: $e');
      return null;
    }
  }
}
