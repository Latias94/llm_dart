part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestConfigSupport {
  final _GoogleChatRequestGenerationSupport generationSupport;
  final _GoogleChatRequestBodySupport bodySupport;

  _GoogleChatRequestConfigSupport({
    required this.config,
    required this.messageCodec,
  })  : generationSupport = _GoogleChatRequestGenerationSupport(config: config),
        bodySupport = _GoogleChatRequestBodySupport(
          config: config,
          messageCodec: messageCodec,
        );

  final GoogleConfig config;
  final GoogleChatMessageCodec messageCodec;

  Map<String, dynamic> buildBodyWithConfig(
    List<Map<String, dynamic>> contents,
    List<Tool>? tools, {
    required bool stream,
  }) {
    final body = <String, dynamic>{'contents': contents};
    final generationConfig = generationSupport.buildGenerationConfig(
      stream: stream,
    );

    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    bodySupport.applyDecorations(body, tools);

    return body;
  }
}
