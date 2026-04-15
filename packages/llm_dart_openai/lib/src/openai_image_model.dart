import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_image_editing.dart';
import 'openai_model_describer.dart';
import 'openai_multipart_body.dart';
import 'openai_non_text_model_support.dart';
import 'openai_options.dart';

part 'openai_image_request_builder.dart';
part 'openai_image_response_decoder.dart';
part 'openai_image_support.dart';

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
  })  : settings = resolveOpenAIModelSettings(
          settings,
          parameterName: 'settings',
          expectedTypeName:
              'OpenAIImageModelSettings for OpenAI-family image models',
        ),
        baseUrl = baseUrl ?? profile.defaultBaseUrl;

  @override
  String get providerId => profile.providerId;

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOpenAIImageModel(
      modelId,
      profile: profile,
    );
  }

  Uri get imageGenerationUri => Uri.parse('$baseUrl/images/generations');
  Uri get imageEditUri => Uri.parse('$baseUrl/images/edits');

  Map<String, String> get defaultHeaders => buildOpenAIFamilyDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        organization: settings.organization,
        project: settings.project,
        headers: settings.headers,
      );

  @override
  Future<ImageGenerationResult> generate(ImageGenerationRequest request) async {
    final options = _resolveProviderOptions(
      request.callOptions,
      parameterName: 'request.callOptions.providerOptions',
    );
    final response = await transport.send(
      _buildGenerationTransportRequest(
        request,
        options: options,
      ),
    );

    return _decodeResponse(
      response.body,
      requestedResponseFormat: _shouldIncludeResponseFormat(modelId)
          ? (options?.responseFormat ?? OpenAIImageResponseFormat.base64Json)
          : null,
    );
  }

  Future<ImageGenerationResult> edit(OpenAIImageEditRequest request) async {
    final options = _resolveProviderOptions(
      request.callOptions,
      parameterName: 'request.callOptions.providerOptions',
    );
    _validateEditRequest(request, options);

    final response = await transport.send(
      _buildEditTransportRequest(
        request,
        options: options,
      ),
    );

    return _decodeResponse(
      response.body,
      requestedResponseFormat: options?.responseFormat,
    );
  }
}
