part of 'anthropic_compat_support.dart';

final class _AnthropicCompatRequestPlanner {
  const _AnthropicCompatRequestPlanner();

  AnthropicCompatRequestPlan buildRequestPlan({
    required List<ChatMessage> messages,
    required List<Tool>? tools,
    required List<Tool>? configTools,
    required core.ProviderInvocationOptions? providerOptions,
  }) {
    final analysis = analyzeAnthropicLegacyMessageExtensions(messages);
    final effectiveTools = <Tool>[
      ...analysis.messageTools,
      ...?(tools ?? configTools),
    ];

    if (effectiveTools.isNotEmpty && analysis.hasAmbiguousToolCacheControl) {
      throw UnsupportedError(
        'Anthropic compatibility cannot preserve multiple legacy tool cache policies in one bridged request.',
      );
    }

    final baseOptions = _resolveProviderOptions(providerOptions);
    final mergedToolCacheControl = _mergeToolCacheControl(
      baseOptions.toolsCacheControl,
      analysis.toolCacheControl,
    );

    return AnthropicCompatRequestPlan(
      effectiveTools: effectiveTools,
      providerOptions: baseOptions.copyWith(
        toolsCacheControl: mergedToolCacheControl,
      ),
    );
  }

  modern_anthropic.AnthropicGenerateTextOptions _resolveProviderOptions(
    core.ProviderInvocationOptions? options,
  ) {
    return core.resolveProviderInvocationOptions<
            modern_anthropic.AnthropicGenerateTextOptions>(
          options,
          parameterName: 'providerOptions',
          expectedTypeName: 'AnthropicGenerateTextOptions',
          usageContext: 'Anthropic compatibility requests',
        ) ??
        const modern_anthropic.AnthropicGenerateTextOptions();
  }

  modern_anthropic.AnthropicCacheControl? _mergeToolCacheControl(
    modern_anthropic.AnthropicCacheControl? base,
    AnthropicLegacyCacheControl? legacy,
  ) {
    if (legacy == null) {
      return base;
    }

    if (base != null && (base.type != legacy.type || base.ttl != legacy.ttl)) {
      throw UnsupportedError(
        'Anthropic compatibility cannot merge conflicting tool cache policies.',
      );
    }

    return modern_anthropic.AnthropicCacheControl(
      type: legacy.type,
      ttl: legacy.ttl,
    );
  }
}
