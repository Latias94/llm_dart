import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_image_edit_body.dart';
import 'openai_image_edit_request.dart';
import 'openai_image_editing.dart';
import 'openai_image_generation_body.dart';
import 'openai_image_generation_request.dart';
import 'openai_image_model_capabilities.dart';
import 'openai_image_model_options_resolution.dart';
import 'openai_image_model_response.dart';
import 'openai_image_model_transport.dart';
import 'openai_image_types.dart';
import 'openai_model_describer.dart';
import 'openai_model_settings.dart';

final class OpenAIImageModel implements ImageModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIImageModelSettings settings;

  @override
  final String modelId;

  OpenAIImageModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    String? baseUrl,
    ProviderModelOptions settings = const OpenAIImageModelSettings(),
  })  : settings = resolveOpenAIImageModelSettings(settings),
        baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile);

  @override
  String get providerId => profile.providerId;

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOpenAIImageModel(
      modelId,
      profile: profile,
    );
  }

  @override
  int get maxImagesPerCall => resolveOpenAIImageMaxImagesPerCall(modelId);

  Uri get imageGenerationUri => resolveOpenAIImageRouteUri(
        baseUrl: baseUrl,
        route: OpenAIImageRequestRoute.generation,
      );
  Uri get imageEditUri => resolveOpenAIImageRouteUri(
        baseUrl: baseUrl,
        route: OpenAIImageRequestRoute.edit,
      );

  Map<String, String> get defaultHeaders => buildOpenAIImageDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        settings: settings,
      );

  @override
  Future<ImageGenerationResult> doGenerate(
    ImageGenerationRequest request,
  ) async {
    if (request.files.isNotEmpty || request.mask != null) {
      return _doEditFromCommonRequest(request);
    }

    final options = resolveOpenAIImageProviderOptions(request.callOptions);
    validateOpenAIImageGenerationRequest(
      modelId: modelId,
      request: request,
      options: options,
      maxImagesPerCall: maxImagesPerCall,
    );
    final body = buildOpenAIImageGenerationRequestBody(
      modelId: modelId,
      request: request,
      options: options,
    );

    final response = await transport.send(
      buildOpenAIImageTransportRequest(
        baseUrl: baseUrl,
        route: OpenAIImageRequestRoute.generation,
        callOptions: request.callOptions,
        body: body,
        defaultHeaders: defaultHeaders,
        contentType: 'application/json',
      ),
    );

    return decodeOpenAIImageResponse(
      body: response.body,
      modelId: modelId,
      headers: response.headers,
      requestedResponseFormat: shouldIncludeOpenAIImageResponseFormat(modelId)
          ? (options?.responseFormat ?? OpenAIImageResponseFormat.base64Json)
          : null,
    );
  }

  Future<ImageGenerationResult> edit(OpenAIImageEditRequest request) async {
    final options = resolveOpenAIImageProviderOptions(request.callOptions);
    validateOpenAIImageEditRequest(
      request,
      options,
      modelId: modelId,
      maxImagesPerCall: maxImagesPerCall,
    );
    final body = buildOpenAIImageEditRequestBody(
      modelId: modelId,
      request: request,
      options: options,
    );

    final response = await transport.send(
      buildOpenAIImageTransportRequest(
        baseUrl: baseUrl,
        route: OpenAIImageRequestRoute.edit,
        callOptions: request.callOptions,
        body: body.bytes,
        defaultHeaders: defaultHeaders,
        contentType: body.contentType,
      ),
    );

    return decodeOpenAIImageResponse(
      body: response.body,
      modelId: modelId,
      headers: response.headers,
      requestedResponseFormat: options?.responseFormat,
    );
  }

  Future<ImageGenerationResult> _doEditFromCommonRequest(
    ImageGenerationRequest request,
  ) {
    return edit(buildOpenAIImageEditRequestFromCommon(request));
  }
}
