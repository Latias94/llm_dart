import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_image_types.dart';
import '../provider/openai_provider_options_namespaces.dart';

final class OpenAIImageOptions
    implements ProviderInvocationOptionsBagProjection {
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

  @override
  ProviderOptionsBag toProviderOptionsBag() {
    return ProviderOptionsBag.forProvider(openAIProviderOptionsNamespace, {
          'style': style?.value,
          'quality': quality?.value,
          'background': background?.value,
          'moderation': moderation?.value,
          'output_format': outputFormat?.value,
          'output_compression': outputCompression,
          'response_format': responseFormat?.value,
          'user': user,
        }) ??
        ProviderOptionsBag.empty;
  }
}
