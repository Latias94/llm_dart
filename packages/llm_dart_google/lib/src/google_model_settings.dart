import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_safety_settings.dart';
import 'google_tools.dart';

final class GoogleChatModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;
  final List<GoogleSafetySetting> safetySettings;
  final List<GoogleNativeTool> tools;
  final bool includeServerSideToolInvocations;

  const GoogleChatModelSettings({
    this.headers = const {},
    this.safetySettings = const [],
    this.tools = const [],
    this.includeServerSideToolInvocations = false,
  });
}

final class GoogleEmbeddingModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;

  const GoogleEmbeddingModelSettings({
    this.headers = const {},
  });
}

final class GoogleImageModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;
  final int? maxImagesPerCall;
  final List<GoogleSafetySetting> safetySettings;

  const GoogleImageModelSettings({
    this.headers = const {},
    this.maxImagesPerCall,
    this.safetySettings = const [],
  });
}

final class GoogleSpeechModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;
  final String defaultVoice;

  const GoogleSpeechModelSettings({
    this.headers = const {},
    this.defaultVoice = 'Kore',
  });
}
