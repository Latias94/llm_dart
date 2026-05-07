part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestGenerationImageSupport {
  final GoogleConfig config;

  const _GoogleChatRequestGenerationImageSupport(this.config);

  void applyImageConfig(Map<String, dynamic> generationConfig) {
    if (config.enableImageGeneration == true) {
      if (config.responseModalities != null) {
        generationConfig['responseModalities'] = config.responseModalities;
      } else {
        generationConfig['responseModalities'] = ['TEXT', 'IMAGE'];
      }
      generationConfig['responseMimeType'] = 'text/plain';
    }
  }
}
