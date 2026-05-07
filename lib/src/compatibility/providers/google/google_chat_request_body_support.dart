part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestBodySupport {
  final GoogleConfig config;
  late final _GoogleChatRequestBodySafetySupport _safetySupport;
  late final _GoogleChatRequestBodyToolSupport _toolSupport;
  late final _GoogleChatRequestBodyWebSearchSupport _webSearchSupport;

  _GoogleChatRequestBodySupport({
    required this.config,
    required GoogleChatMessageCodec messageCodec,
  }) {
    _safetySupport = _GoogleChatRequestBodySafetySupport(config: config);
    _toolSupport = _GoogleChatRequestBodyToolSupport(
      config: config,
      messageCodec: messageCodec,
    );
    _webSearchSupport = const _GoogleChatRequestBodyWebSearchSupport();
  }

  void applyDecorations(
    Map<String, dynamic> body,
    List<Tool>? tools,
  ) {
    _safetySupport.applySafetySettings(body);
    _toolSupport.applyTools(body, tools);
    _webSearchSupport.applyWebSearch(body, config.webSearchEnabled);
  }
}
