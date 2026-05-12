import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_api.dart';
import 'anthropic_mcp_models.dart';
import 'anthropic_tools.dart';

final class AnthropicCacheControl {
  final String type;
  final String? ttl;

  const AnthropicCacheControl({
    required this.type,
    this.ttl,
  });

  const AnthropicCacheControl.ephemeral({
    this.ttl,
  }) : type = 'ephemeral';

  Map<String, Object?> toJson() {
    return {
      'type': type,
      if (ttl != null) 'ttl': ttl,
    };
  }
}

final class AnthropicPromptPartOptions implements ProviderPromptPartOptions {
  final AnthropicCacheControl? cacheControl;

  const AnthropicPromptPartOptions({
    this.cacheControl,
  });
}

final class AnthropicPromptPartOptionsJsonCodec
    implements ProviderPromptPartOptionsJsonCodec<AnthropicPromptPartOptions> {
  static const typeId = 'anthropic.promptPartOptions';

  const AnthropicPromptPartOptionsJsonCodec();

  @override
  String get type => typeId;

  @override
  bool canEncode(ProviderPromptPartOptions options) =>
      options is AnthropicPromptPartOptions;

  @override
  JsonMap encode(ProviderPromptPartOptions options) {
    final typed = options as AnthropicPromptPartOptions;
    return {
      if (typed.cacheControl != null)
        'cacheControl': typed.cacheControl!.toJson(),
    };
  }

  @override
  AnthropicPromptPartOptions decode(JsonMap json) {
    final cacheControlJson = json['cacheControl'];
    if (cacheControlJson == null) {
      return const AnthropicPromptPartOptions();
    }

    final cacheControl = asJsonMap(
      cacheControlJson,
      path: r'$.data.cacheControl',
    );
    return AnthropicPromptPartOptions(
      cacheControl: AnthropicCacheControl(
        type: asJsonString(cacheControl['type'],
            path: r'$.data.cacheControl.type'),
        ttl: asNullableJsonString(
          cacheControl['ttl'],
          path: r'$.data.cacheControl.ttl',
        ),
      ),
    );
  }
}

const anthropicPromptPartOptionsJsonCodec =
    AnthropicPromptPartOptionsJsonCodec();

final class AnthropicChatModelSettings implements ProviderModelOptions {
  final String anthropicVersion;
  final Map<String, String> headers;
  final List<String> betaFeatures;
  final List<AnthropicNativeTool> tools;
  final List<String> deferredToolNames;

  const AnthropicChatModelSettings({
    this.anthropicVersion = '2023-06-01',
    this.headers = const {},
    this.betaFeatures = const [],
    this.tools = const [],
    this.deferredToolNames = const [],
  });
}

final class AnthropicFilesSettings {
  final String anthropicVersion;
  final Map<String, String> headers;
  final List<String> betaFeatures;

  const AnthropicFilesSettings({
    this.anthropicVersion = anthropicDefaultVersion,
    this.headers = const {},
    this.betaFeatures = const [],
  });

  AnthropicFilesSettings copyWith({
    String? anthropicVersion,
    Map<String, String>? headers,
    List<String>? betaFeatures,
  }) {
    return AnthropicFilesSettings(
      anthropicVersion: anthropicVersion ?? this.anthropicVersion,
      headers: headers ?? this.headers,
      betaFeatures: betaFeatures ?? this.betaFeatures,
    );
  }
}

final class AnthropicGenerateTextOptions implements ProviderInvocationOptions {
  final bool? extendedThinking;
  final int? thinkingBudgetTokens;
  final bool? interleavedThinking;
  final String? serviceTier;
  final Map<String, Object?>? metadata;
  final String? container;
  final List<AnthropicMcpServer>? mcpServers;
  final List<AnthropicNativeTool>? tools;
  final List<String>? deferredToolNames;
  final AnthropicCacheControl? toolsCacheControl;

  const AnthropicGenerateTextOptions({
    this.extendedThinking,
    this.thinkingBudgetTokens,
    this.interleavedThinking,
    this.serviceTier,
    this.metadata,
    this.container,
    this.mcpServers,
    this.tools,
    this.deferredToolNames,
    this.toolsCacheControl,
  });

  AnthropicGenerateTextOptions copyWith({
    bool? extendedThinking,
    int? thinkingBudgetTokens,
    bool? interleavedThinking,
    String? serviceTier,
    Map<String, Object?>? metadata,
    String? container,
    List<AnthropicMcpServer>? mcpServers,
    List<AnthropicNativeTool>? tools,
    List<String>? deferredToolNames,
    AnthropicCacheControl? toolsCacheControl,
  }) {
    return AnthropicGenerateTextOptions(
      extendedThinking: extendedThinking ?? this.extendedThinking,
      thinkingBudgetTokens: thinkingBudgetTokens ?? this.thinkingBudgetTokens,
      interleavedThinking: interleavedThinking ?? this.interleavedThinking,
      serviceTier: serviceTier ?? this.serviceTier,
      metadata: metadata ?? this.metadata,
      container: container ?? this.container,
      mcpServers: mcpServers ?? this.mcpServers,
      tools: tools ?? this.tools,
      deferredToolNames: deferredToolNames ?? this.deferredToolNames,
      toolsCacheControl: toolsCacheControl ?? this.toolsCacheControl,
    );
  }
}
