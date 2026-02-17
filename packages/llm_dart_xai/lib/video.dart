import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';

import 'config.dart';

class XAIVideo
    implements
        ExperimentalVideoGenerationCapability,
        ExperimentalVideoGenerationCallOptionsCapability,
        ExperimentalVideoGenerationMaxVideosPerCallCapability {
  final OpenAIClient client;
  final XAIConfig config;

  XAIVideo(this.client, this.config);

  @override
  int get maxVideosPerCall => 1;

  @override
  Future<ExperimentalVideoGenerationResponse> generateVideos(
    ExperimentalVideoGenerationRequest request, {
    CancelToken? cancelToken,
  }) {
    return generateVideosWithCallOptions(
      request,
      callOptions: const LLMCallOptions(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ExperimentalVideoGenerationResponse> generateVideosWithCallOptions(
    ExperimentalVideoGenerationRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final warnings = <LLMWarning>[];

    final mergedProviderOptions =
        _mergeProviderOptions(config.originalConfig, request.providerOptions);
    final xaiOptions =
        mergedProviderOptions['xai'] ?? const <String, dynamic>{};

    final pollIntervalMs = _readInt(xaiOptions['pollIntervalMs']) ?? 5000;
    final pollTimeoutMs = _readInt(xaiOptions['pollTimeoutMs']) ?? 600000;

    final videoUrl = _readString(xaiOptions['videoUrl']) ??
        _readString(xaiOptions['video_url']);
    final isEdit = videoUrl != null && videoUrl.trim().isNotEmpty;

    if (request.fps != null) {
      warnings.add(const LLMUnsupportedWarning(
        feature: 'fps',
        details: 'xAI video models do not support custom FPS.',
      ));
    }

    if (request.seed != null) {
      warnings.add(const LLMUnsupportedWarning(
        feature: 'seed',
        details: 'xAI video models do not support seed.',
      ));
    }

    if (request.n > 1) {
      warnings.add(const LLMUnsupportedWarning(
        feature: 'n',
        details:
            'xAI video models do not support generating multiple videos per call. Only 1 video will be generated.',
      ));
    }

    if (isEdit && request.duration != null) {
      warnings.add(const LLMUnsupportedWarning(
        feature: 'duration',
        details: 'xAI video editing does not support custom duration.',
      ));
    }

    if (isEdit && request.aspectRatio != null) {
      warnings.add(const LLMUnsupportedWarning(
        feature: 'aspectRatio',
        details: 'xAI video editing does not support custom aspect ratio.',
      ));
    }

    if (isEdit &&
        (request.resolution != null || xaiOptions['resolution'] != null)) {
      warnings.add(const LLMUnsupportedWarning(
        feature: 'resolution',
        details: 'xAI video editing does not support custom resolution.',
      ));
    }

    final body = <String, dynamic>{
      'model': config.videoModel,
      if (request.prompt != null) 'prompt': request.prompt,
    };

    if (!isEdit && request.duration != null) {
      body['duration'] = request.duration;
    }

    if (!isEdit && request.aspectRatio != null) {
      body['aspect_ratio'] = request.aspectRatio;
    }

    if (!isEdit) {
      final resolvedResolution =
          _resolveResolution(request.resolution, xaiOptions, warnings);
      if (resolvedResolution != null) {
        body['resolution'] = resolvedResolution;
      }
    }

    if (videoUrl != null && videoUrl.trim().isNotEmpty) {
      body['video'] = {'url': videoUrl.trim()};
    }

    final image = request.image;
    if (image != null) {
      body['image'] = {'url': _experimentalVideoFileToUrl(image)};
    }

    // Pass through any additional xai provider options to the request body,
    // excluding known non-body options.
    for (final entry in xaiOptions.entries) {
      final key = entry.key;
      if (key == 'pollIntervalMs' ||
          key == 'pollTimeoutMs' ||
          key == 'resolution' ||
          key == 'videoUrl' ||
          key == 'video_url' ||
          key == 'jsonSchema' ||
          key == 'embeddingEncodingFormat' ||
          key == 'embeddingDimensions' ||
          key == 'imageModel' ||
          key == 'imageModelId' ||
          key == 'videoModel' ||
          key == 'videoModelId' ||
          key == 'liveSearch' ||
          key == 'searchParameters') {
        continue;
      }
      body[key] = entry.value;
    }

    final effectiveBody = callOptions.mergeIntoRequestBody(body);

    final createResult = await client.postJsonWithHeaders(
      isEdit ? 'videos/edits' : 'videos/generations',
      effectiveBody,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );

    final createJson = createResult.json;
    final requestId = _readString(createJson['request_id']) ??
        _readString(createJson['requestId']);
    if (requestId == null || requestId.trim().isEmpty) {
      throw ProviderError(
        'No request_id returned from xAI API. Response: ${jsonEncode(createJson)}',
      );
    }

    final deadline =
        DateTime.now().toUtc().add(Duration(milliseconds: pollTimeoutMs));
    Map<String, String>? pollHeaders;
    Map<String, dynamic>? pollJson;

    while (true) {
      if (cancelToken?.isCancelled == true) {
        throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
      }

      if (pollIntervalMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: pollIntervalMs));
      }

      if (DateTime.now().toUtc().isAfter(deadline)) {
        throw TimeoutError(
            'Video generation timed out after ${pollTimeoutMs}ms');
      }

      final pollResult = await client.getJsonWithResponseHeaders(
        'videos/${requestId.trim()}',
        headers: callOptions.headers,
        cancelToken: cancelToken,
      );

      pollJson = pollResult.json;
      pollHeaders = pollResult.headers;

      final status = _readString(pollJson['status']);
      final videoObj = pollJson['video'];
      final url = (videoObj is Map) ? _readString(videoObj['url']) : null;

      if (status == 'done' ||
          (status == null && url != null && url.trim().isNotEmpty)) {
        if (url == null || url.trim().isEmpty) {
          throw const ProviderError(
            'Video generation completed but no video URL was returned.',
          );
        }

        return ExperimentalVideoGenerationResponse(
          videos: [
            ExperimentalGeneratedVideoUrl(
              url: Uri.parse(url.trim()),
              mediaType: 'video/mp4',
            ),
          ],
          warnings: List<LLMWarning>.unmodifiable(warnings),
          responses: [
            ExperimentalVideoResponseMetadata(
              timestamp: startedAt,
              modelId: config.videoModel,
              headers: pollHeaders.isEmpty ? null : pollHeaders,
            ),
          ],
          providerMetadata: _providerMetadata(
            endpoint: isEdit ? 'videos/edits' : 'videos/generations',
            model: config.videoModel,
            requestId: requestId.trim(),
            pollResponse: pollJson,
          ),
        );
      }
    }
  }
}

Map<String, Map<String, dynamic>> _mergeProviderOptions(
  LLMConfig? originalConfig,
  ProviderOptions requestProviderOptions,
) {
  final base =
      originalConfig?.providerOptions ?? const <String, Map<String, dynamic>>{};
  if (base.isEmpty) return requestProviderOptions;
  if (requestProviderOptions.isEmpty) return base;

  final out = <String, Map<String, dynamic>>{};
  for (final entry in base.entries) {
    out[entry.key] = Map<String, dynamic>.from(entry.value);
  }
  for (final entry in requestProviderOptions.entries) {
    final key = entry.key;
    final existing = out[key];
    if (existing == null) {
      out[key] = Map<String, dynamic>.from(entry.value);
    } else {
      out[key] = {...existing, ...entry.value};
    }
  }
  return out;
}

String? _resolveResolution(
  String? requestResolution,
  Map<String, dynamic> xaiOptions,
  List<LLMWarning> warnings,
) {
  final opt = _readString(xaiOptions['resolution']);
  if (opt != null && opt.trim().isNotEmpty) return opt.trim();

  final r = requestResolution?.trim();
  if (r == null || r.isEmpty) return null;

  const map = <String, String>{
    '1280x720': '720p',
    '854x480': '480p',
    '640x480': '480p',
  };

  final mapped = map[r];
  if (mapped != null) return mapped;

  warnings.add(LLMUnsupportedWarning(
    feature: 'resolution',
    details:
        'Unrecognized resolution "$r". Use providerOptions.xai.resolution with "480p" or "720p" instead.',
  ));
  return null;
}

String _experimentalVideoFileToUrl(ExperimentalVideoFile file) {
  switch (file) {
    case ExperimentalUrlVideoFile(:final url):
      return url.toString();
    case ExperimentalInlineVideoFile(:final mediaType, :final data):
      final String base64Data;
      if (data is String) {
        base64Data = data;
      } else if (data is Uint8List) {
        base64Data = base64Encode(data);
      } else {
        throw InvalidRequestError(
            'Invalid inline file data: ${data.runtimeType}');
      }
      return 'data:$mediaType;base64,$base64Data';
  }
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _readString(Object? value) {
  if (value is String) return value;
  return null;
}

Map<String, dynamic> _providerMetadata({
  required String endpoint,
  required String model,
  required String requestId,
  required Map<String, dynamic>? pollResponse,
}) {
  final payload = <String, dynamic>{
    'model': model,
    'endpoint': endpoint,
    'requestId': requestId,
    if (pollResponse != null) 'poll': pollResponse,
  };

  return {
    'xai': payload,
    'xai.video': payload,
  };
}
