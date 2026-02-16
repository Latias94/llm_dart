/// Experimental video generation related models.
///
/// This module is intentionally marked experimental to align with Vercel AI SDK
/// `experimental_generateVideo` / `VideoModelV3` APIs.
library;

import 'dart:typed_data';

import '../core/provider_options.dart';
import '../core/stream_parts.dart';

/// A video or image file that can be used as input for video generation.
///
/// Mirrors Vercel AI SDK's `VideoModelV3File` concept.
sealed class ExperimentalVideoFile {
  const ExperimentalVideoFile();

  Map<String, dynamic> toJson();
}

/// Input file represented inline.
final class ExperimentalInlineVideoFile extends ExperimentalVideoFile {
  final String mediaType;

  /// Inline data payload.
  ///
  /// Use [Uint8List] for binary data, or [String] for base64-encoded data.
  final Object data;

  /// Optional provider-specific metadata for the file part.
  final ProviderOptions providerOptions;

  const ExperimentalInlineVideoFile({
    required this.mediaType,
    required this.data,
    this.providerOptions = const {},
  }) : assert(data is String || data is Uint8List);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'file',
        'mediaType': mediaType,
        'data': data is Uint8List
            ? (data as Uint8List).toList(growable: false)
            : data,
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };

  factory ExperimentalInlineVideoFile.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final Object data;
    if (raw is String) {
      data = raw;
    } else if (raw is List) {
      data = Uint8List.fromList(List<int>.from(raw));
    } else {
      throw ArgumentError('Invalid inline file data: $raw');
    }
    return ExperimentalInlineVideoFile(
      mediaType: json['mediaType'] as String,
      data: data,
      providerOptions: _parseProviderOptions(json['providerOptions']),
    );
  }
}

/// Input file represented as a URL.
final class ExperimentalUrlVideoFile extends ExperimentalVideoFile {
  final Uri url;
  final ProviderOptions providerOptions;

  const ExperimentalUrlVideoFile({
    required this.url,
    this.providerOptions = const {},
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'url',
        'url': url.toString(),
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };

  factory ExperimentalUrlVideoFile.fromJson(Map<String, dynamic> json) =>
      ExperimentalUrlVideoFile(
        url: Uri.parse(json['url'] as String),
        providerOptions: _parseProviderOptions(json['providerOptions']),
      );
}

ExperimentalVideoFile experimentalVideoFileFromJson(
  Map<String, dynamic> json,
) {
  final type = json['type'];
  switch (type) {
    case 'file':
      return ExperimentalInlineVideoFile.fromJson(json);
    case 'url':
      return ExperimentalUrlVideoFile.fromJson(json);
  }
  throw ArgumentError('Unknown ExperimentalVideoFile type: $type');
}

/// Experimental video generation request configuration.
///
/// Mirrors Vercel AI SDK's `VideoModelV3CallOptions`.
class ExperimentalVideoGenerationRequest {
  /// Text prompt for the video generation.
  ///
  /// May be null when [image] is provided (image-to-video).
  final String? prompt;

  /// Number of videos to generate. Default: 1.
  final int n;

  /// Aspect ratio, e.g. `16:9`, `9:16`, `1:1`.
  final String? aspectRatio;

  /// Resolution, e.g. `1280x720`.
  final String? resolution;

  /// Duration in seconds.
  final int? duration;

  /// Frames per second.
  final int? fps;

  /// Seed for deterministic generation.
  final int? seed;

  /// Optional input image/video file (image-to-video or video editing).
  final ExperimentalVideoFile? image;

  /// Additional provider-specific body parameters.
  final ProviderOptions providerOptions;

  const ExperimentalVideoGenerationRequest({
    this.prompt,
    this.n = 1,
    this.aspectRatio,
    this.resolution,
    this.duration,
    this.fps,
    this.seed,
    this.image,
    this.providerOptions = const {},
  }) : assert(n >= 1);

  ExperimentalVideoGenerationRequest copyWith({
    String? prompt,
    int? n,
    String? aspectRatio,
    String? resolution,
    int? duration,
    int? fps,
    int? seed,
    ExperimentalVideoFile? image,
    ProviderOptions? providerOptions,
  }) {
    return ExperimentalVideoGenerationRequest(
      prompt: prompt ?? this.prompt,
      n: n ?? this.n,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      resolution: resolution ?? this.resolution,
      duration: duration ?? this.duration,
      fps: fps ?? this.fps,
      seed: seed ?? this.seed,
      image: image ?? this.image,
      providerOptions: providerOptions ?? this.providerOptions,
    );
  }

  Map<String, dynamic> toJson() => {
        if (prompt != null) 'prompt': prompt,
        'n': n,
        if (aspectRatio != null) 'aspectRatio': aspectRatio,
        if (resolution != null) 'resolution': resolution,
        if (duration != null) 'duration': duration,
        if (fps != null) 'fps': fps,
        if (seed != null) 'seed': seed,
        if (image != null) 'image': image!.toJson(),
        if (providerOptions.isNotEmpty) 'providerOptions': providerOptions,
      };

  factory ExperimentalVideoGenerationRequest.fromJson(
    Map<String, dynamic> json,
  ) =>
      ExperimentalVideoGenerationRequest(
        prompt: json['prompt'] as String?,
        n: (json['n'] as int?) ?? 1,
        aspectRatio: json['aspectRatio'] as String?,
        resolution: json['resolution'] as String?,
        duration: json['duration'] as int?,
        fps: json['fps'] as int?,
        seed: json['seed'] as int?,
        image: json['image'] is Map
            ? experimentalVideoFileFromJson(
                (json['image'] as Map).cast<String, dynamic>(),
              )
            : null,
        providerOptions: _parseProviderOptions(json['providerOptions']),
      );
}

ProviderOptions _parseProviderOptions(Object? raw) {
  if (raw is ProviderOptions) return raw;
  if (raw is! Map) return const {};

  final result = <String, Map<String, dynamic>>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key is! String) continue;

    final value = entry.value;
    if (value is Map<String, dynamic>) {
      result[key] = value;
    } else if (value is Map) {
      result[key] = Map<String, dynamic>.from(value);
    }
  }

  return result.isEmpty ? const {} : result;
}

/// A generated video payload.
///
/// Mirrors Vercel AI SDK's `VideoModelV3VideoData` union.
sealed class ExperimentalGeneratedVideo {
  const ExperimentalGeneratedVideo();

  String get mediaType;

  Map<String, dynamic> toJson();
}

final class ExperimentalGeneratedVideoUrl extends ExperimentalGeneratedVideo {
  final Uri url;
  @override
  final String mediaType;

  const ExperimentalGeneratedVideoUrl({
    required this.url,
    required this.mediaType,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'url',
        'url': url.toString(),
        'mediaType': mediaType,
      };

  factory ExperimentalGeneratedVideoUrl.fromJson(Map<String, dynamic> json) =>
      ExperimentalGeneratedVideoUrl(
        url: Uri.parse(json['url'] as String),
        mediaType: json['mediaType'] as String,
      );
}

final class ExperimentalGeneratedVideoBase64
    extends ExperimentalGeneratedVideo {
  final String data;
  @override
  final String mediaType;

  const ExperimentalGeneratedVideoBase64({
    required this.data,
    required this.mediaType,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'base64',
        'data': data,
        'mediaType': mediaType,
      };

  factory ExperimentalGeneratedVideoBase64.fromJson(
    Map<String, dynamic> json,
  ) =>
      ExperimentalGeneratedVideoBase64(
        data: json['data'] as String,
        mediaType: json['mediaType'] as String,
      );
}

final class ExperimentalGeneratedVideoBinary
    extends ExperimentalGeneratedVideo {
  final Uint8List data;
  @override
  final String mediaType;

  const ExperimentalGeneratedVideoBinary({
    required this.data,
    required this.mediaType,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'binary',
        'data': data.toList(growable: false),
        'mediaType': mediaType,
      };

  factory ExperimentalGeneratedVideoBinary.fromJson(
    Map<String, dynamic> json,
  ) =>
      ExperimentalGeneratedVideoBinary(
        data: Uint8List.fromList(List<int>.from(json['data'] as List)),
        mediaType: json['mediaType'] as String,
      );
}

ExperimentalGeneratedVideo experimentalGeneratedVideoFromJson(
  Map<String, dynamic> json,
) {
  final type = json['type'];
  switch (type) {
    case 'url':
      return ExperimentalGeneratedVideoUrl.fromJson(json);
    case 'base64':
      return ExperimentalGeneratedVideoBase64.fromJson(json);
    case 'binary':
      return ExperimentalGeneratedVideoBinary.fromJson(json);
  }
  throw ArgumentError('Unknown ExperimentalGeneratedVideo type: $type');
}

/// Experimental response metadata for a video model call.
///
/// Mirrors AI SDK's `VideoModelResponseMetadata`.
class ExperimentalVideoResponseMetadata {
  final DateTime timestamp;
  final String modelId;
  final Map<String, String>? headers;

  const ExperimentalVideoResponseMetadata({
    required this.timestamp,
    required this.modelId,
    this.headers,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'modelId': modelId,
        if (headers != null) 'headers': headers,
      };

  factory ExperimentalVideoResponseMetadata.fromJson(
    Map<String, dynamic> json,
  ) =>
      ExperimentalVideoResponseMetadata(
        timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
        modelId: json['modelId'] as String,
        headers: (json['headers'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );
}

/// Experimental video generation response with metadata.
class ExperimentalVideoGenerationResponse {
  final List<ExperimentalGeneratedVideo> videos;
  final List<LLMWarning> warnings;

  /// Response metadata for each underlying provider call.
  ///
  /// This mirrors Vercel AI SDK's `responses` array on the generateVideo result.
  final List<ExperimentalVideoResponseMetadata> responses;
  final Map<String, dynamic>? providerMetadata;

  const ExperimentalVideoGenerationResponse({
    required this.videos,
    this.warnings = const <LLMWarning>[],
    this.responses = const <ExperimentalVideoResponseMetadata>[],
    this.providerMetadata,
  });

  ExperimentalGeneratedVideo get video => videos.first;

  Map<String, dynamic> toJson() => {
        'videos': videos.map((v) => v.toJson()).toList(growable: false),
        if (warnings.isNotEmpty)
          'warnings': warnings.map((w) => w.toJson()).toList(growable: false),
        if (responses.isNotEmpty)
          'responses': responses.map((r) => r.toJson()).toList(growable: false),
        if (providerMetadata != null && providerMetadata!.isNotEmpty)
          'providerMetadata': providerMetadata,
      };

  factory ExperimentalVideoGenerationResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      ExperimentalVideoGenerationResponse(
        videos: (json['videos'] as List)
            .map((v) => experimentalGeneratedVideoFromJson(
                  (v as Map).cast<String, dynamic>(),
                ))
            .toList(growable: false),
        warnings: (json['warnings'] as List?)
                ?.whereType<Map>()
                .map((m) => LLMWarning.fromJson(m.cast<String, dynamic>()))
                .toList(growable: false) ??
            const <LLMWarning>[],
        responses: _parseResponses(json),
        providerMetadata: json['providerMetadata'] is Map
            ? Map<String, dynamic>.from(json['providerMetadata'] as Map)
            : null,
      );
}

List<ExperimentalVideoResponseMetadata> _parseResponses(
  Map<String, dynamic> json,
) {
  final rawResponses = json['responses'];
  if (rawResponses is List) {
    final out = <ExperimentalVideoResponseMetadata>[];
    for (final raw in rawResponses) {
      if (raw is! Map) continue;
      out.add(ExperimentalVideoResponseMetadata.fromJson(
        raw.cast<String, dynamic>(),
      ));
    }
    return out;
  }

  // Backward-compat: older snapshots may still serialize a single `response`.
  final rawResponse = json['response'];
  if (rawResponse is Map) {
    return [
      ExperimentalVideoResponseMetadata.fromJson(
        rawResponse.cast<String, dynamic>(),
      ),
    ];
  }

  return const <ExperimentalVideoResponseMetadata>[];
}
