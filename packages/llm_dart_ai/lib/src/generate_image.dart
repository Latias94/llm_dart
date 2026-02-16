import 'package:llm_dart_core/llm_dart_core.dart';

import 'ai_errors.dart';
import 'types.dart';

/// Generate images using a provider-agnostic capability.
Future<GenerateImageResult> generateImage({
  required ImageGenerationCapability model,
  required ImageGenerationRequest request,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  final requestedN = (request.count ?? 1) <= 0 ? 1 : (request.count ?? 1);
  final maxImagesPerCall = model is ImageGenerationMaxImagesPerCallCapability
      ? (model as ImageGenerationMaxImagesPerCallCapability).maxImagesPerCall
      : requestedN;
  final effectiveMaxImagesPerCall =
      maxImagesPerCall <= 0 ? requestedN : maxImagesPerCall;

  final callCounts = <int>[];
  var remaining = requestedN;
  while (remaining > 0) {
    final next = remaining > effectiveMaxImagesPerCall
        ? effectiveMaxImagesPerCall
        : remaining;
    callCounts.add(next);
    remaining -= next;
  }

  Future<ImageGenerationResponse> runOne(int n) async {
    if (cancelToken?.isCancelled == true) {
      throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
    }

    final subRequest = ImageGenerationRequest(
      prompt: request.prompt,
      model: request.model,
      negativePrompt: request.negativePrompt,
      size: request.size,
      count: n,
      seed: request.seed,
      steps: request.steps,
      guidanceScale: request.guidanceScale,
      enhancePrompt: request.enhancePrompt,
      style: request.style,
      quality: request.quality,
      responseFormat: request.responseFormat,
      user: request.user,
    );

    if (effectiveCallOptions.isEmpty) {
      return model.generateImages(subRequest);
    }

    if (model is! ImageGenerationCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides (headers/body) for image generation. '
        'Implement `ImageGenerationCallOptionsCapability` (or use a provider that does).',
      );
    }

    return (model as ImageGenerationCallOptionsCapability)
        .generateImagesWithCallOptions(
      subRequest,
      callOptions: effectiveCallOptions,
    );
  }

  if (callCounts.length == 1) {
    final response = await runOne(callCounts.single);
    if (response.images.isEmpty) {
      throw NoImageGeneratedError(
        response: response,
        responses: response.responses,
      );
    }
    return GenerateImageResult(rawResponse: response);
  }

  final responses = <ImageGenerationResponse>[];
  for (final n in callCounts) {
    responses.add(await runOne(n));
  }

  final allImages = <GeneratedImage>[];
  final allWarnings = <LLMWarning>[];
  final allResponses = <ImageModelResponseMetadata>[];
  UsageInfo? totalUsage;
  Map<String, dynamic>? providerMetadata;
  String? mergedModel;
  String? mergedRevisedPrompt;

  for (final r in responses) {
    allImages.addAll(r.images);
    allWarnings.addAll(r.warnings);
    allResponses.addAll(r.responses);
    providerMetadata =
        _mergeProviderMetadata(providerMetadata, r.providerMetadata);
    mergedModel ??= r.model;
    mergedRevisedPrompt ??= r.revisedPrompt;
    if (r.usage != null) {
      totalUsage = totalUsage == null ? r.usage : (totalUsage! + r.usage!);
    }
  }

  if (allImages.isEmpty) {
    throw NoImageGeneratedError(
      response: responses.isEmpty ? null : responses.last,
      responses: allResponses,
    );
  }

  final merged = ImageGenerationResponse(
    images: List<GeneratedImage>.unmodifiable(allImages),
    model: mergedModel ?? request.model,
    revisedPrompt: mergedRevisedPrompt,
    usage: totalUsage,
    warnings: List<LLMWarning>.unmodifiable(allWarnings),
    responses: List<ImageModelResponseMetadata>.unmodifiable(allResponses),
    providerMetadata: providerMetadata,
  );

  return GenerateImageResult(rawResponse: merged);
}

Map<String, dynamic>? _mergeProviderMetadata(
  Map<String, dynamic>? a,
  Map<String, dynamic>? b,
) {
  if (a == null || a.isEmpty) return b;
  if (b == null || b.isEmpty) return a;

  final out = <String, dynamic>{...a};
  for (final entry in b.entries) {
    final key = entry.key;
    final bv = entry.value;
    final av = out[key];

    if (av is Map && bv is Map) {
      final merged = <String, dynamic>{...av.cast<String, dynamic>()};
      for (final inner in bv.entries) {
        merged[inner.key.toString()] = inner.value;
      }

      final existingImages = merged['images'];
      final newImages = (bv as Map)['images'];
      if (existingImages is List && newImages is List) {
        merged['images'] = [...existingImages, ...newImages];
      }

      out[key] = merged;
    } else {
      out[key] = bv;
    }
  }

  return out.isEmpty ? null : out;
}
