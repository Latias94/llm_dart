import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_image_types.dart';

final class OpenAIImageOptions implements ProviderInvocationOptions {
  final OpenAIImageStyle? style;
  final OpenAIImageQuality? quality;
  final OpenAIImageBackground? background;
  final OpenAIImageModeration? moderation;
  final OpenAIImageOutputFormat? outputFormat;
  final int? outputCompression;
  final OpenAIImageResponseFormat? responseFormat;
  final String? user;

  const OpenAIImageOptions({
    this.style,
    this.quality,
    this.background,
    this.moderation,
    this.outputFormat,
    this.outputCompression,
    this.responseFormat,
    this.user,
  });
}
