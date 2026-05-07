part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestBodySafetySupport {
  final GoogleConfig config;

  const _GoogleChatRequestBodySafetySupport({
    required this.config,
  });

  void applySafetySettings(Map<String, dynamic> body) {
    final effectiveSafetySettings =
        config.safetySettings ?? GoogleConfig.defaultSafetySettings;
    if (effectiveSafetySettings.isNotEmpty) {
      body['safetySettings'] =
          effectiveSafetySettings.map((setting) => setting.toJson()).toList();
    }
  }
}
