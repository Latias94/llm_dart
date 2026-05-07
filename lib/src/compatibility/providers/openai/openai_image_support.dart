import 'dart:convert';

import 'package:llm_dart_transport/dio.dart';

import '../../../../core/llm_error.dart';
import '../../../../models/image_models.dart';
import '../../../../providers/openai/config.dart';

part 'openai_image_form_support.dart';
part 'openai_image_request_support.dart';
part 'openai_image_response_support.dart';

/// Provider-local request and response shaping for OpenAI image compatibility.
final class OpenAIImageSupport {
  static const _requestSupport = _OpenAIImageRequestSupport();
  static const _formSupport = _OpenAIImageFormSupport();
  static const _responseSupport = _OpenAIImageResponseSupport();

  const OpenAIImageSupport();

  Map<String, dynamic> buildGenerationRequest(
    ImageGenerationRequest request, {
    required OpenAIConfig config,
  }) {
    return _requestSupport.buildGenerationRequest(
      request,
      config: config,
    );
  }

  FormData buildEditFormData(ImageEditRequest request) {
    return _formSupport.buildEditFormData(request);
  }

  FormData buildVariationFormData(ImageVariationRequest request) {
    return _formSupport.buildVariationFormData(request);
  }

  ImageGenerationResponse parseImageResponse(
    Map<String, dynamic> responseData, {
    required String? model,
    required String providerLabel,
  }) {
    return _responseSupport.parseImageResponse(
      responseData,
      model: model,
      providerLabel: providerLabel,
    );
  }
}
