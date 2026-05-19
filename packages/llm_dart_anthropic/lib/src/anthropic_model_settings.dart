import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_api.dart';
import 'anthropic_tools.dart';

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
