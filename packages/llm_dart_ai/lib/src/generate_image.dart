import 'package:llm_dart_core/llm_dart_core.dart';

import 'ai_errors.dart';
import 'types.dart';

/// Generate images using a provider-agnostic capability (AI SDK-style).
///
/// This mirrors the Vercel AI SDK `generateImage` surface:
/// - prompt can be plain text, or
/// - prompt can include input images + optional mask for editing.
Future<GenerateImageResult> generateImage({
  required ImageGenerationCapability model,
  required GenerateImagePrompt prompt,
  String? modelId,
  int n = 1,
  int? maxImagesPerCall,
  String? size,
  String? aspectRatio,
  int? seed,
  ProviderOptions providerOptions = const {},
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final orchestrationWarnings = <LLMWarning>[];
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  final requestedN = n <= 0 ? 1 : n;
  final declaredMaxImagesPerCall = model
          is ImageGenerationMaxImagesPerCallCapability
      ? (model as ImageGenerationMaxImagesPerCallCapability).maxImagesPerCall
      : requestedN;
  final effectiveMaxImagesPerCall =
      (maxImagesPerCall ?? declaredMaxImagesPerCall) <= 0
          ? requestedN
          : (maxImagesPerCall ?? declaredMaxImagesPerCall);

  final callCounts = <int>[];
  var remaining = requestedN;
  while (remaining > 0) {
    final next = remaining > effectiveMaxImagesPerCall
        ? effectiveMaxImagesPerCall
        : remaining;
    callCounts.add(next);
    remaining -= next;
  }

  ImageGenerationResponse mergeResponses(
      List<ImageGenerationResponse> responses) {
    final allImages = <GeneratedImage>[];
    final allWarnings = <LLMWarning>[...orchestrationWarnings];
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

    return ImageGenerationResponse(
      images: List<GeneratedImage>.unmodifiable(allImages),
      model: mergedModel ?? modelId,
      revisedPrompt: mergedRevisedPrompt,
      usage: totalUsage,
      warnings: List<LLMWarning>.unmodifiable(allWarnings),
      responses: List<ImageModelResponseMetadata>.unmodifiable(allResponses),
      providerMetadata: providerMetadata,
    );
  }

  Future<ImageGenerationResponse> runOne({
    required int n,
    required GenerateImagePrompt prompt,
  }) async {
    if (cancelToken?.isCancelled == true) {
      throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
    }

    Future<T> run<T>(
      Future<T> Function(ImageGenerationCallOptionsCapability cap) withOptions,
      Future<T> Function() plain,
    ) async {
      if (effectiveCallOptions.isEmpty) return plain();

      if (model is! ImageGenerationCallOptionsCapability) {
        throw const InvalidRequestError(
          'This model does not support call-level overrides (headers/body) for image generation. '
          'Implement `ImageGenerationCallOptionsCapability` (or use a provider that does).',
        );
      }

      return withOptions(model as ImageGenerationCallOptionsCapability);
    }

    switch (prompt) {
      case GenerateImageTextPrompt(:final text):
        final request = ImageGenerationRequest(
          prompt: text,
          model: modelId,
          aspectRatio: aspectRatio,
          size: size,
          count: n,
          seed: seed,
          providerOptions: providerOptions,
        );
        return run(
          (cap) => cap.generateImagesWithCallOptions(
            request,
            callOptions: effectiveCallOptions,
          ),
          () => model.generateImages(request),
        );

      case GenerateImageImagesPrompt(
          :final images,
          :final text,
          :final mask,
        ):
        if (images.isEmpty) {
          throw const InvalidArgumentError(
            argument: 'prompt.images',
            message: 'prompt.images must not be empty.',
          );
        }

        if (!model.supportsImageEditing) {
          throw const InvalidRequestError(
            'This model does not support image editing.',
          );
        }

        final warnings = <LLMWarning>[];
        if (images.length > 1) {
          warnings.add(const LLMOtherWarning(
            'This model only supports a single input image. Additional images are ignored.',
          ));
        }

        final request = ImageEditRequest(
          image: images.first,
          prompt: (text ?? '').trim(),
          mask: mask,
          model: modelId,
          count: n,
          size: size,
          aspectRatio: aspectRatio,
          providerOptions: providerOptions,
        );

        final response = await run(
          (cap) => cap.editImageWithCallOptions(
            request,
            callOptions: effectiveCallOptions,
          ),
          () => model.editImage(request),
        );

        if (warnings.isEmpty) return response;
        return ImageGenerationResponse(
          images: response.images,
          model: response.model,
          revisedPrompt: response.revisedPrompt,
          usage: response.usage,
          warnings: [...response.warnings, ...warnings],
          responses: response.responses,
          providerMetadata: response.providerMetadata,
        );
    }
  }

  if (callCounts.length == 1) {
    final response = await runOne(n: callCounts.single, prompt: prompt);
    if (response.images.isEmpty) {
      throw NoImageGeneratedError(
        response: response,
        responses: response.responses,
      );
    }
    if (orchestrationWarnings.isEmpty) {
      return GenerateImageResult(rawResponse: response);
    }

    final merged = ImageGenerationResponse(
      images: response.images,
      model: response.model ?? modelId,
      revisedPrompt: response.revisedPrompt,
      usage: response.usage,
      warnings: List<LLMWarning>.unmodifiable([
        ...orchestrationWarnings,
        ...response.warnings,
      ]),
      responses: response.responses,
      providerMetadata: response.providerMetadata,
    );

    return GenerateImageResult(rawResponse: merged);
  }

  if (cancelToken?.isCancelled == true) {
    throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
  }

  final responses = await Future.wait<ImageGenerationResponse>(
    callCounts.map((count) => runOne(n: count, prompt: prompt)),
    eagerError: true,
  );

  final merged = mergeResponses(responses);

  if (merged.images.isEmpty) {
    throw NoImageGeneratedError(
      response: responses.isEmpty ? null : responses.last,
      responses: merged.responses,
    );
  }

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
