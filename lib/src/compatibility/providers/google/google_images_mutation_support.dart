part of 'images.dart';

final class _GoogleImagesMutationSupport {
  static const _requestSupport = _GoogleImagesMutationRequestSupport();
  const _GoogleImagesMutationSupport();

  Future<ImageGenerationResponse> editImage({
    required GoogleClient client,
    required GoogleConfig config,
    required Logger logger,
    required GoogleImageSupport support,
    required ImageEditRequest request,
  }) async {
    return _requestSupport.editImage(
      client: client,
      config: config,
      logger: logger,
      support: support,
      request: request,
    );
  }

  Future<ImageGenerationResponse> createVariation({
    required GoogleClient client,
    required GoogleConfig config,
    required Logger logger,
    required GoogleImageSupport support,
    required ImageVariationRequest request,
  }) async {
    return _requestSupport.createVariation(
      client: client,
      config: config,
      logger: logger,
      support: support,
      request: request,
    );
  }
}
