part of 'openai_custom_part.dart';

OpenAICustomPart? _parseCustomPayload({
  required String kind,
  required Object? data,
  required ProviderMetadata? providerMetadata,
}) {
  final payload = asMap(data);
  if (payload == null) {
    return null;
  }

  return switch (kind) {
    OpenAIImageGenerationCallCustomPart.customKind =>
      OpenAIImageGenerationCallCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAIImageGenerationPartialCustomPart.customKind =>
      OpenAIImageGenerationPartialCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAIMcpListToolsCustomPart.customKind => OpenAIMcpListToolsCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAICodeInterpreterCallCustomPart.customKind =>
      OpenAICodeInterpreterCallCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAIToolSearchCallCustomPart.customKind => OpenAIToolSearchCallCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    OpenAIToolSearchOutputCustomPart.customKind =>
      OpenAIToolSearchOutputCustomPart(
        payload: payload,
        providerMetadata: providerMetadata,
      ),
    _ => null,
  };
}
