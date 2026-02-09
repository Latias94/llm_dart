part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

class ProcessedMessages {
  final List<Map<String, dynamic>> anthropicMessages;
  final List<Map<String, dynamic>> systemContentBlocks;
  final List<String> systemMessages;

  ProcessedMessages({
    required this.anthropicMessages,
    required this.systemContentBlocks,
    required this.systemMessages,
  });
}

class SystemMessageResult {
  final List<Map<String, dynamic>> contentBlocks;
  final List<String> plainMessages;

  SystemMessageResult({
    required this.contentBlocks,
    required this.plainMessages,
  });
}

class ProcessedTools {
  final List<Tool> tools;
  final Map<String, dynamic>? cacheControl;

  ProcessedTools({
    required this.tools,
    this.cacheControl,
  });
}

class ToolExtractionResult {
  final List<Tool> tools;
  final Map<String, dynamic>? cacheControl;

  ToolExtractionResult({
    required this.tools,
    this.cacheControl,
  });
}

class _AnthropicDocumentPartOptions {
  final bool citationsEnabled;
  final String? title;
  final String? context;

  const _AnthropicDocumentPartOptions({
    required this.citationsEnabled,
    required this.title,
    required this.context,
  });
}

extension _AnthropicRequestBuilderDocumentOptions on AnthropicRequestBuilder {
  _AnthropicDocumentPartOptions _documentOptionsFromProviderOptions(
    ProviderOptions providerOptions,
  ) {
    final title = readProviderOption<String>(
      providerOptions,
      config.providerId,
      'title',
      fallbackProviderId: _providerOptionsFallbackId,
    );

    final context = readProviderOption<String>(
      providerOptions,
      config.providerId,
      'context',
      fallbackProviderId: _providerOptionsFallbackId,
    );

    bool citationsEnabled = false;

    final citations = readProviderOptionMap(
      providerOptions,
      config.providerId,
      'citations',
      fallbackProviderId: _providerOptionsFallbackId,
    );
    if (citations != null) {
      citationsEnabled = citations['enabled'] == true;
    } else {
      final directEnabled = readProviderOption<bool>(
        providerOptions,
        config.providerId,
        'citationsEnabled',
        fallbackProviderId: _providerOptionsFallbackId,
      );
      final directEnabledSnake = readProviderOption<bool>(
        providerOptions,
        config.providerId,
        'citations_enabled',
        fallbackProviderId: _providerOptionsFallbackId,
      );
      citationsEnabled = directEnabled == true || directEnabledSnake == true;
    }

    return _AnthropicDocumentPartOptions(
      citationsEnabled: citationsEnabled,
      title: title,
      context: context,
    );
  }
}
