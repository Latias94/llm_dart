import 'package:llm_dart_core/llm_dart_core.dart';

import 'ai_errors.dart';
import 'types.dart';

/// Experimental: generate videos using a provider-agnostic capability.
///
/// This is aligned with Vercel AI SDK's `experimental_generateVideo` surface.
///
/// Parity notes:
/// - If the model declares [ExperimentalVideoGenerationMaxVideosPerCallCapability],
///   this helper splits `n` into multiple calls and aggregates the results.
/// - URL-based videos are downloaded eagerly (via [download] or [createDownload])
///   so the final result contains portable binary payloads by default.
Future<ExperimentalGenerateVideoResult> experimentalGenerateVideo({
  required ExperimentalVideoGenerationCapability model,
  required ExperimentalVideoGenerationRequest request,
  DownloadFn? download,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  final maxVideosPerCall =
      model is ExperimentalVideoGenerationMaxVideosPerCallCapability
          ? (model as ExperimentalVideoGenerationMaxVideosPerCallCapability)
              .maxVideosPerCall
          : request.n;

  final effectiveMaxVideosPerCall =
      maxVideosPerCall <= 0 ? request.n : maxVideosPerCall;

  final callCounts = <int>[];
  var remaining = request.n;
  while (remaining > 0) {
    final next = remaining > effectiveMaxVideosPerCall
        ? effectiveMaxVideosPerCall
        : remaining;
    callCounts.add(next);
    remaining -= next;
  }

  Future<ExperimentalVideoGenerationResponse> runOne(int n) async {
    final subRequest = request.copyWith(n: n);

    if (effectiveCallOptions.isEmpty) {
      return model.generateVideos(subRequest, cancelToken: cancelToken);
    }

    if (model is! ExperimentalVideoGenerationCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides (headers/body) for video generation. '
        'Implement `ExperimentalVideoGenerationCallOptionsCapability` (or use a provider that does).',
      );
    }

    return (model as ExperimentalVideoGenerationCallOptionsCapability)
        .generateVideosWithCallOptions(
      subRequest,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );
  }

  final responses = <ExperimentalVideoGenerationResponse>[];
  for (final n in callCounts) {
    if (cancelToken?.isCancelled == true) {
      throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
    }
    responses.add(await runOne(n));
  }

  final allVideos = <ExperimentalGeneratedVideo>[];
  final allWarnings = <LLMWarning>[];
  final allResponses = <ExperimentalVideoResponseMetadata>[];
  Map<String, dynamic>? providerMetadata;

  for (final r in responses) {
    allVideos.addAll(r.videos);
    allWarnings.addAll(r.warnings);
    allResponses.addAll(r.responses);
    providerMetadata =
        _mergeProviderMetadata(providerMetadata, r.providerMetadata);
  }

  if (allVideos.isEmpty) {
    throw NoVideoGeneratedError(
      response: responses.isEmpty ? null : responses.last,
    );
  }

  final downloadFn = download ?? createDownload();

  // Vercel parity: download URL-based videos eagerly so the result contains
  // portable binary payloads by default.
  final normalizedVideos = <ExperimentalGeneratedVideo>[];
  for (final video in allVideos) {
    if (video is ExperimentalGeneratedVideoUrl) {
      final downloaded = await downloadFn(
        url: video.url,
        cancelToken: cancelToken,
      );

      bool usable(String? type) =>
          type != null &&
          type.isNotEmpty &&
          type.toLowerCase() != 'application/octet-stream';

      final mediaType = usable(video.mediaType)
          ? video.mediaType
          : (usable(downloaded.mediaType)
              ? downloaded.mediaType!
              : 'video/mp4');

      normalizedVideos.add(
        ExperimentalGeneratedVideoBinary(
          data: downloaded.data,
          mediaType: mediaType,
        ),
      );
      continue;
    }

    normalizedVideos.add(video);
  }

  final normalizedResponse = ExperimentalVideoGenerationResponse(
    videos: normalizedVideos,
    warnings: allWarnings,
    responses: allResponses,
    providerMetadata: providerMetadata,
  );

  return ExperimentalGenerateVideoResult(rawResponse: normalizedResponse);
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

      final existingVideos = merged['videos'];
      final newVideos = (bv)['videos'];
      if (existingVideos is List && newVideos is List) {
        merged['videos'] = [...existingVideos, ...newVideos];
      }

      out[key] = merged;
    } else {
      out[key] = bv;
    }
  }

  return out.isEmpty ? null : out;
}
