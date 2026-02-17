import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'client.dart';
import 'config.dart';
import 'model_path.dart';

/// Google (Gemini / Vertex express) experimental video generation capability.
///
/// This is aligned with Vercel AI SDK's `experimental_generateVideo` +
/// Google/Vertex video models (predictLongRunning + polling).
class GoogleVideo
    implements
        ExperimentalVideoGenerationCapability,
        ExperimentalVideoGenerationCallOptionsCapability {
  final GoogleClient _client;
  final GoogleConfig _config;
  final Logger _logger = Logger('GoogleVideo');

  GoogleVideo(this._client, this._config);

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
    final warnings = <LLMWarning>[];

    final isVertex = _client.usesApiKeyHeaderAuth;
    final videoOptions = _readVideoOptions(
      request.providerOptions,
      isVertex: isVertex,
      providerId: _config.providerId,
      providerOptionsName: _config.providerOptionsName,
    );

    final pollIntervalMs =
        _readInt(videoOptions['pollIntervalMs']) ?? 10000; // 10s
    final pollTimeoutMs =
        _readInt(videoOptions['pollTimeoutMs']) ?? 600000; // 10min

    final instances = <Map<String, dynamic>>[
      <String, dynamic>{},
    ];
    final instance = instances.first;

    if (request.prompt != null && request.prompt!.trim().isNotEmpty) {
      instance['prompt'] = request.prompt;
    }

    final image = request.image;
    if (image != null) {
      if (image is ExperimentalUrlVideoFile) {
        warnings.add(
          LLMUnsupportedWarning(
            feature: 'URL-based image input',
            details: isVertex
                ? 'Vertex AI video models require base64-encoded images or GCS URIs. URL will be ignored.'
                : 'Google Generative AI video models require base64-encoded images. URL will be ignored.',
          ),
        );
      } else if (image is ExperimentalInlineVideoFile) {
        final base64Data = image.data is String
            ? image.data as String
            : base64Encode(image.data as Uint8List);

        if (isVertex) {
          instance['image'] = {
            'bytesBase64Encoded': base64Data,
            'mimeType': image.mediaType,
          };
        } else {
          instance['image'] = {
            'inlineData': {
              'mimeType': image.mediaType,
              'data': base64Data,
            },
          };
        }
      } else {
        warnings.add(
          LLMUnsupportedWarning(
            feature: 'Unknown image input type',
            details:
                'Unsupported ExperimentalVideoFile type: ${image.runtimeType}',
          ),
        );
      }
    }

    final parameters = <String, dynamic>{
      'sampleCount': request.n,
    };

    if (request.aspectRatio != null) {
      parameters['aspectRatio'] = request.aspectRatio;
    }

    if (request.resolution != null) {
      const resolutionMap = {
        '1280x720': '720p',
        '1920x1080': '1080p',
        '3840x2160': '4k',
      };
      parameters['resolution'] =
          resolutionMap[request.resolution] ?? request.resolution;
    }

    if (request.duration != null) {
      parameters['durationSeconds'] = request.duration;
    }
    if (request.seed != null) parameters['seed'] = request.seed;

    // Known provider option keys (Vercel parity) + passthrough.
    _copyIfPresent(videoOptions, parameters, 'personGeneration');
    _copyIfPresent(videoOptions, parameters, 'negativePrompt');
    if (isVertex) {
      _copyIfPresent(videoOptions, parameters, 'generateAudio');
      _copyIfPresent(videoOptions, parameters, 'gcsOutputDirectory');
    }

    final referenceImages = videoOptions['referenceImages'];
    if (referenceImages is List && referenceImages.isNotEmpty) {
      if (isVertex) {
        instance['referenceImages'] = referenceImages;
      } else {
        instance['referenceImages'] = referenceImages.map((ref) {
          if (ref is! Map) return ref;
          final bytesBase64 = ref['bytesBase64Encoded'];
          final gcsUri = ref['gcsUri'];
          if (bytesBase64 is String && bytesBase64.isNotEmpty) {
            return {
              'inlineData': {
                'mimeType': 'image/png',
                'data': bytesBase64,
              },
            };
          }
          if (gcsUri is String && gcsUri.isNotEmpty) {
            return {'gcsUri': gcsUri};
          }
          return ref;
        }).toList(growable: false);
      }
    }

    for (final entry in videoOptions.entries) {
      final key = entry.key;
      if (key == 'pollIntervalMs' ||
          key == 'pollTimeoutMs' ||
          key == 'personGeneration' ||
          key == 'negativePrompt' ||
          key == 'referenceImages' ||
          key == 'generateAudio' ||
          key == 'gcsOutputDirectory') {
        continue;
      }
      parameters[key] = entry.value;
    }

    final modelPath = googleModelPath(_config.model);
    final predictEndpoint = '$modelPath:predictLongRunning';

    final requestBody = callOptions.mergeIntoRequestBody({
      'instances': instances,
      'parameters': parameters,
    });

    _logger.fine('Google video request endpoint: $predictEndpoint');

    final op = await _client.postJsonWithHeaders(
      predictEndpoint,
      requestBody,
      headers: callOptions.headers,
      cancelToken: cancelToken,
    );

    var operation = op.json;
    var responseHeaders = op.headers;

    final operationName = operation['name'];
    if (operationName is! String || operationName.isEmpty) {
      throw const ProviderError(
          'Google video generation: missing operation name');
    }

    final startedAt = DateTime.now();
    while (operation['done'] != true) {
      if (cancelToken?.isCancelled == true) {
        throw CancelledError(cancelToken?.reason?.toString() ?? 'Cancelled');
      }

      if (DateTime.now().difference(startedAt).inMilliseconds > pollTimeoutMs) {
        throw TimeoutError(
          'Google video generation timed out after ${pollTimeoutMs}ms',
        );
      }

      final delayMs = pollIntervalMs < 0 ? 0 : pollIntervalMs;
      if (delayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      } else {
        await Future<void>.delayed(Duration.zero);
      }

      if (isVertex) {
        final pollEndpoint = '$modelPath:fetchPredictOperation';
        final polled = await _client.postJsonWithHeaders(
          pollEndpoint,
          {'operationName': operationName},
          headers: callOptions.headers,
          cancelToken: cancelToken,
        );
        operation = polled.json;
        responseHeaders = polled.headers;
      } else {
        final polled = await _client.getJsonWithHeaders(
          operationName,
          headers: callOptions.headers,
          cancelToken: cancelToken,
        );
        operation = polled.json;
        responseHeaders = polled.headers;
      }
    }

    final error = operation['error'];
    if (error is Map && (error['message'] is String)) {
      throw ProviderError(
          'Google video generation failed: ${error['message']}');
    }

    final videos = <ExperimentalGeneratedVideo>[];
    final providerVideoMetadata = <Map<String, dynamic>>[];

    if (isVertex) {
      final response = operation['response'];
      final rawVideos = (response is Map) ? response['videos'] : null;
      if (rawVideos is! List || rawVideos.isEmpty) {
        throw const ProviderError(
            'Google video generation: no videos in response');
      }

      for (final raw in rawVideos) {
        if (raw is! Map) continue;
        final bytesBase64 = raw['bytesBase64Encoded'];
        final gcsUri = raw['gcsUri'];
        final mimeType = (raw['mimeType'] is String &&
                (raw['mimeType'] as String).isNotEmpty)
            ? raw['mimeType'] as String
            : 'video/mp4';

        if (bytesBase64 is String && bytesBase64.isNotEmpty) {
          videos.add(ExperimentalGeneratedVideoBase64(
            data: bytesBase64,
            mediaType: mimeType,
          ));
          providerVideoMetadata.add({'mimeType': mimeType});
        } else if (gcsUri is String && gcsUri.isNotEmpty) {
          videos.add(ExperimentalGeneratedVideoUrl(
            url: Uri.parse(gcsUri),
            mediaType: mimeType,
          ));
          providerVideoMetadata.add({'gcsUri': gcsUri, 'mimeType': mimeType});
        }
      }
    } else {
      final response = operation['response'];
      final generateVideoResponse =
          (response is Map) ? response['generateVideoResponse'] : null;
      final samples = (generateVideoResponse is Map)
          ? generateVideoResponse['generatedSamples']
          : null;

      if (samples is! List || samples.isEmpty) {
        throw const ProviderError(
            'Google video generation: no videos in response');
      }

      for (final sample in samples) {
        if (sample is! Map) continue;
        final video = sample['video'];
        final uri = (video is Map) ? video['uri'] : null;
        if (uri is! String || uri.isEmpty) continue;

        final url = _appendApiKeyIfNeeded(uri);
        videos.add(ExperimentalGeneratedVideoUrl(
          url: Uri.parse(url),
          mediaType: 'video/mp4',
        ));
        providerVideoMetadata.add({'uri': uri});
      }
    }

    if (videos.isEmpty) {
      throw const ProviderError(
          'Google video generation: no valid videos in response');
    }

    final providerMetadata = <String, dynamic>{
      _config.providerOptionsName: {
        'videos': providerVideoMetadata,
      },
    };

    return ExperimentalVideoGenerationResponse(
      videos: videos,
      warnings: warnings,
      responses: [
        ExperimentalVideoResponseMetadata(
          timestamp: DateTime.now().toUtc(),
          modelId: _config.model,
          headers: responseHeaders.isEmpty ? null : responseHeaders,
        ),
      ],
      providerMetadata: providerMetadata,
    );
  }

  String _appendApiKeyIfNeeded(String uri) {
    if (_client.usesApiKeyHeaderAuth) return uri;
    final apiKey = _config.apiKey;
    if (apiKey.isEmpty) return uri;

    final parsed = Uri.tryParse(uri);
    if (parsed == null) return uri;
    if (parsed.queryParameters.containsKey('key')) return uri;

    final nextQuery = Map<String, String>.from(parsed.queryParameters);
    nextQuery['key'] = apiKey;
    return parsed.replace(queryParameters: nextQuery).toString();
  }
}

Map<String, dynamic> _readVideoOptions(
  ProviderOptions providerOptions, {
  required bool isVertex,
  required String providerId,
  required String providerOptionsName,
}) {
  Map<String, dynamic>? options;

  // Primary lookup: current provider id/namespace.
  options = providerOptions[providerId] ?? providerOptions[providerOptionsName];

  // Vercel AI SDK mental model aliases:
  // - Google Vertex video options live under `vertex`.
  if (options == null && isVertex) {
    options = providerOptions['vertex'] ?? providerOptions['google-vertex'];
  }

  // - Google video options live under `google`.
  if (options == null && !isVertex) {
    options = providerOptions['google'];
  }

  if (options == null) return const <String, dynamic>{};
  return Map<String, dynamic>.from(options);
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

void _copyIfPresent(
  Map<String, dynamic> from,
  Map<String, dynamic> to,
  String key,
) {
  if (!from.containsKey(key)) return;
  final value = from[key];
  if (value == null) return;
  to[key] = value;
}
