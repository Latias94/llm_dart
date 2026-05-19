import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_image_edit_request.dart';
import 'google_image_editing.dart';
import 'google_image_generation_request.dart';
import 'google_image_model_capabilities.dart';
import 'google_image_model_options_resolution.dart';
import 'google_image_model_response.dart';
import 'google_image_model_transport.dart';
import 'google_model_describer.dart';
import 'google_options.dart';

final class GoogleImageModel implements ImageModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final GoogleImageModelSettings settings;

  @override
  final String modelId;

  GoogleImageModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings = const GoogleImageModelSettings(),
  })  : settings = resolveGoogleImageModelSettings(settings),
        baseUrl = baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get providerId => 'google';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeGoogleImageModel(
      modelId,
      settings: settings,
    );
  }

  bool get isGeminiImageModel => isGoogleGeminiImageModel(modelId);

  @override
  int get maxImagesPerCall => resolveGoogleImageMaxImagesPerCall(
        modelId: modelId,
        settings: settings,
      );

  Uri get predictUri => resolveGoogleImageRouteUri(
        baseUrl: baseUrl,
        modelId: modelId,
        route: GoogleImageRequestRoute.predict,
      );

  Uri get generateContentUri => resolveGoogleImageRouteUri(
        baseUrl: baseUrl,
        modelId: modelId,
        route: GoogleImageRequestRoute.generateContent,
      );

  @override
  Future<ImageGenerationResult> doGenerate(
    ImageGenerationRequest request,
  ) async {
    if (request.files.isNotEmpty || request.mask != null) {
      return _doEditFromCommonRequest(request);
    }

    final options = resolveGoogleImageProviderOptions(request.callOptions);
    validateGoogleImageGenerationRequest(
      request: request,
      options: options,
      isGeminiImageModel: isGeminiImageModel,
      maxImagesPerCall: maxImagesPerCall,
      settings: settings,
    );
    final route = isGeminiImageModel
        ? GoogleImageRequestRoute.generateContent
        : GoogleImageRequestRoute.predict;
    final body = buildGoogleImageGenerationRequestBody(
      request: request,
      options: options,
      isGeminiImageModel: isGeminiImageModel,
      settings: settings,
    );

    final response = await transport.send(
      buildGoogleImageTransportRequest(
        baseUrl: baseUrl,
        modelId: modelId,
        route: route,
        callOptions: request.callOptions,
        body: body,
        apiKey: apiKey,
        settings: settings,
      ),
    );

    return decodeGoogleImageResponse(
      body: response.body,
      modelId: modelId,
      route: route,
      headers: response.headers,
    );
  }

  Future<ImageGenerationResult> edit(GoogleImageEditRequest request) async {
    validateGoogleImageEditSupport(isGeminiImageModel: isGeminiImageModel);
    final options = resolveGoogleImageProviderOptions(request.callOptions);
    validateGoogleImageEditRequest(request, options);
    final body = buildGoogleGeminiImageEditRequestBody(
      request,
      options: options,
      settings: settings,
    );

    final response = await transport.send(
      buildGoogleImageTransportRequest(
        baseUrl: baseUrl,
        modelId: modelId,
        route: GoogleImageRequestRoute.generateContent,
        callOptions: request.callOptions,
        body: body,
        apiKey: apiKey,
        settings: settings,
      ),
    );

    return decodeGoogleImageResponse(
      body: response.body,
      modelId: modelId,
      route: GoogleImageRequestRoute.generateContent,
      headers: response.headers,
    );
  }

  Future<ImageGenerationResult> createVariation(
    GoogleImageVariationRequest request,
  ) {
    return edit(buildGoogleImageEditRequestFromVariation(request));
  }

  Future<ImageGenerationResult> _doEditFromCommonRequest(
    ImageGenerationRequest request,
  ) {
    return edit(
      buildGoogleImageEditRequestFromCommon(
        request: request,
        isGeminiImageModel: isGeminiImageModel,
      ),
    );
  }
}
