part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestGenerationSupport {
  final GoogleConfig config;
  late final _GoogleChatRequestGenerationSamplingSupport _samplingSupport;
  late final _GoogleChatRequestGenerationSchemaSupport _schemaSupport;
  late final _GoogleChatRequestGenerationThinkingSupport _thinkingSupport;
  late final _GoogleChatRequestGenerationImageSupport _imageSupport;

  _GoogleChatRequestGenerationSupport({
    required this.config,
  }) {
    _samplingSupport = _GoogleChatRequestGenerationSamplingSupport(config);
    _schemaSupport = _GoogleChatRequestGenerationSchemaSupport(config);
    _thinkingSupport = _GoogleChatRequestGenerationThinkingSupport(config);
    _imageSupport = _GoogleChatRequestGenerationImageSupport(config);
  }

  Map<String, dynamic> buildGenerationConfig({
    required bool stream,
  }) {
    final generationConfig = <String, dynamic>{};

    _samplingSupport.applySamplingConfig(generationConfig);
    _schemaSupport.applySchemaConfig(generationConfig);
    _thinkingSupport.applyThinkingConfig(
      generationConfig,
      stream: stream,
    );
    _imageSupport.applyImageConfig(generationConfig);

    return generationConfig;
  }
}
