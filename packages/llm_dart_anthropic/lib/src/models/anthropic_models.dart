import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

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

enum AnthropicCacheTtl {
  fiveMinutes(300, '5m'),
  oneHour(3600, '1h');

  const AnthropicCacheTtl(this.seconds, this.value);
  final int seconds;
  final String value;

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

class AnthropicTextBlock implements ContentBlock {
  final AnthropicCacheControl? cacheControl;
  String? _text;

  AnthropicTextBlock({this.cacheControl, String? text}) : _text = text;

  void setText(String text) {
    _text = text;
  }

  @override
  String get displayText => _text ?? '';

  @override
  String get providerId => 'anthropic';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': _text ?? '',
        if (cacheControl != null) 'cache_control': cacheControl!.toJson(),
      };
}

class AnthropicToolsBlock implements ContentBlock {
  final List<Tool> tools;

  AnthropicToolsBlock(this.tools);

  @override
  String get displayText => '[${tools.length} tools defined]';

  @override
  String get providerId => 'anthropic';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tools',
        'tools': tools.map((tool) => tool.toJson()).toList(),
      };
}

class AnthropicMessageBuilder {
  final MessageBuilder _builder;
  bool _cacheEnabled = false;
  AnthropicCacheTtl? _cacheTtl;

  AnthropicMessageBuilder._(this._builder);

  AnthropicMessageBuilder cache({AnthropicCacheTtl? ttl}) {
    _cacheEnabled = true;
    _cacheTtl = ttl;
    return this;
  }

  AnthropicMessageBuilder contentBlock(Map<String, dynamic> blockData) {
    final type = blockData['type'] as String;

    switch (type) {
      case 'text':
        final text = blockData['text'] as String;
        final cacheData = blockData['cache_control'] as Map<String, dynamic>?;

        if (cacheData != null && cacheData['type'] == 'ephemeral') {
          final ttlString = cacheData['ttl'] as String?;
          final ttl = AnthropicCacheTtl.fromString(ttlString);
          cache(ttl: ttl);
          _builder.text(text);
          return this;
        } else {
          _builder.text(text);
          return this;
        }
      case 'tools':
        final toolsData = blockData['tools'] as List<dynamic>? ?? [];
        final cacheData = blockData['cache_control'] as Map<String, dynamic>?;

        final tools = <Tool>[];
        for (final toolData in toolsData) {
          if (toolData is Map<String, dynamic>) {
            final function = toolData['function'] as Map<String, dynamic>;
            tools.add(Tool(
              toolType: toolData['type'] as String? ?? 'function',
              function: FunctionTool(
                name: function['name'] as String,
                description: function['description'] as String,
                parameters: ParametersSchema.fromJson(
                  function['parameters'] as Map<String, dynamic>,
                ),
              ),
            ));
          }
        }

        if (cacheData != null && cacheData['type'] == 'ephemeral') {
          final ttlString = cacheData['ttl'] as String?;
          final ttl = AnthropicCacheTtl.fromString(ttlString);
          cache(ttl: ttl);
          _builder.tools(tools);
          return this;
        } else {
          _builder.tools(tools);
          return this;
        }
      default:
        _builder.text(blockData['text']?.toString() ?? '');
        return this;
    }
  }

  AnthropicMessageBuilder contentBlocks(List<Map<String, dynamic>> blocks) {
    for (final block in blocks) {
      contentBlock(block);
    }
    return this;
  }
}

extension AnthropicMessageBuilderExtension on MessageBuilder {
  MessageBuilder anthropicConfig(
    void Function(AnthropicMessageBuilder) configure,
  ) {
    final anthropicBuilder = AnthropicMessageBuilder._(this);
    configure(anthropicBuilder);

    if (anthropicBuilder._cacheEnabled) {
      // Attach Anthropic provider options for cacheControl so that
      // the new ModelMessage-based pipeline can read it directly.
      final cacheControl = AnthropicCacheControl.ephemeral(
        ttl: anthropicBuilder._cacheTtl?.value,
      );
      setProviderOptions('anthropic', {
        'cacheControl': cacheControl.toJson(),
      });

      final cacheMarker = AnthropicTextBlock(
        text: '',
        cacheControl: AnthropicCacheControl.ephemeral(
          ttl: anthropicBuilder._cacheTtl?.value,
        ),
      );
      addBlock(cacheMarker);
    }
    return this;
  }
}

class AnthropicModels implements ModelListingCapability {
  final dynamic client;
  final dynamic config;

  AnthropicModels(this.client, this.config);

  String get modelsEndpoint => 'models';

  @override
  Future<List<AIModel>> models({CancellationToken? cancelToken}) async {
    return listModels(cancelToken: cancelToken);
  }

  Future<List<AIModel>> listModels({
    String? beforeId,
    String? afterId,
    int limit = 20,
    CancellationToken? cancelToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (beforeId != null) queryParams['before_id'] = beforeId;
      if (afterId != null) queryParams['after_id'] = afterId;
      if (limit != 20) queryParams['limit'] = limit;

      final endpoint = queryParams.isEmpty
          ? modelsEndpoint
          : '$modelsEndpoint?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final responseData = await client.getJson(
        endpoint,
        cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
      );
      final data = responseData['data'] as List?;

      if (data == null) return [];

      return data
          .map(
            (modelData) => AIModel.fromJson(modelData as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      client.logger.warning('Failed to list models: $e');
      return [];
    }
  }

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
