import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_model_describer.dart';
import 'elevenlabs_options.dart';
import 'elevenlabs_shared.dart';
import 'simple_multipart_body.dart';

/// Package-owned modern ElevenLabs transcription model surface.
final class ElevenLabsTranscriptionModel
    implements TranscriptionModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final ElevenLabsTranscriptionModelSettings settings;

  @override
  final String modelId;

  ElevenLabsTranscriptionModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings =
        const ElevenLabsTranscriptionModelSettings(),
  })  : baseUrl = normalizeElevenLabsBaseUrl(baseUrl),
        settings = _resolveSettings(settings);

  @override
  String get providerId => 'elevenlabs';

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeElevenLabsTranscriptionModel(modelId);
  }

  Map<String, String> get defaultHeaders => {
        'xi-api-key': apiKey,
        ...settings.headers,
      };

  @override
  Future<TranscriptionResult> transcribe(TranscriptionRequest request) async {
    final providerOptions = request.callOptions.providerOptions;
    if (providerOptions != null &&
        providerOptions is! ElevenLabsTranscriptionOptions) {
      throw ArgumentError.value(
        providerOptions,
        'request.callOptions.providerOptions',
        'Expected ElevenLabsTranscriptionOptions for ElevenLabs transcription models.',
      );
    }

    final options = providerOptions as ElevenLabsTranscriptionOptions?;
    _validateTranscriptionOptions(options);

    final multipart = buildSimpleMultipartBody(
      fields: [
        SimpleMultipartField.file(
          name: 'file',
          filename: buildAudioFilename(request.mediaType),
          mediaType: request.mediaType ?? 'audio/wav',
          bytes: request.audioBytes,
        ),
        SimpleMultipartField.text(
          name: 'model_id',
          value: modelId,
        ),
        if (options?.languageCode case final languageCode?)
          SimpleMultipartField.text(
            name: 'language_code',
            value: languageCode,
          ),
        if (options?.tagAudioEvents case final tagAudioEvents?)
          SimpleMultipartField.text(
            name: 'tag_audio_events',
            value: '$tagAudioEvents',
          ),
        if (options?.numSpeakers case final numSpeakers?)
          SimpleMultipartField.text(
            name: 'num_speakers',
            value: '$numSpeakers',
          ),
        if (options?.timestampGranularity case final timestampGranularity?)
          SimpleMultipartField.text(
            name: 'timestamps_granularity',
            value: timestampGranularity.name,
          ),
        if (options?.diarize case final diarize?)
          SimpleMultipartField.text(
            name: 'diarize',
            value: '$diarize',
          ),
        if (options?.fileFormat case final fileFormat?)
          SimpleMultipartField.text(
            name: 'file_format',
            value: fileFormat.value,
          ),
      ],
    );

    final response = await transport.send(
      TransportRequest(
        uri: _transcriptionUri(
          queryParameters: {
            if (options?.enableLogging case final enableLogging?)
              'enable_logging': '$enableLogging',
          },
        ),
        method: TransportMethod.post,
        headers: {
          ...defaultHeaders,
          'content-type': multipart.contentType,
          'accept': 'application/json',
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: multipart.bytes,
        timeout: request.callOptions.timeout,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    final json = _decodeJsonObject(response.body);
    final text = _asString(json['text']);
    if (text == null || text.isEmpty) {
      throw StateError(
        'Expected ElevenLabs transcription response to contain non-empty text.',
      );
    }

    final segments = _decodeSegments(json['words']);
    final responseMetadata = elevenLabsResponseMetadata(response.headers);
    final bodyMetadata = ProviderMetadata.forNamespace(
      'elevenlabs',
      {
        if (json['language_code'] != null)
          'languageCode': json['language_code'],
        if (json['language_probability'] != null)
          'languageProbability': json['language_probability'],
        if (json['words'] != null) 'words': json['words'],
        if (json['additional_formats'] != null)
          'additionalFormats': json['additional_formats'],
      },
    );

    return TranscriptionResult(
      text: text,
      segments: segments,
      language: _asString(json['language_code']),
      durationSeconds: segments.isEmpty ? null : segments.last.endSeconds,
      responseMetadata: ModelResponseMetadata(
        timestamp: DateTime.now().toUtc(),
        modelId: modelId,
        headers: response.headers,
      ),
      providerMetadata: ProviderMetadata.mergeNullable(
        responseMetadata,
        bodyMetadata,
      ),
    );
  }

  Uri _transcriptionUri({
    required Map<String, String> queryParameters,
  }) {
    final uri = Uri.parse('$baseUrl/speech-to-text');
    return queryParameters.isEmpty
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  static ElevenLabsTranscriptionModelSettings _resolveSettings(
    ProviderModelOptions settings,
  ) {
    if (settings is ElevenLabsTranscriptionModelSettings) {
      return settings;
    }

    throw ArgumentError.value(
      settings,
      'settings',
      'Expected ElevenLabsTranscriptionModelSettings for ElevenLabs transcription models.',
    );
  }
}

void _validateTranscriptionOptions(ElevenLabsTranscriptionOptions? options) {
  if (options == null) {
    return;
  }

  if (options.numSpeakers != null &&
      (options.numSpeakers! < 1 || options.numSpeakers! > 32)) {
    throw ArgumentError.value(
      options.numSpeakers,
      'providerOptions.numSpeakers',
      'ElevenLabs transcription numSpeakers must be between 1 and 32.',
    );
  }
}

Map<String, Object?> _decodeJsonObject(Object? body) {
  if (body is Map<String, Object?>) {
    return body;
  }

  if (body is Map) {
    return Map<String, Object?>.from(body);
  }

  if (body is String) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  }

  throw StateError(
    'Expected an ElevenLabs transcription JSON object but received ${body.runtimeType}.',
  );
}

String? _asString(Object? value) => value is String ? value : null;

List<TranscriptionSegment> _decodeSegments(Object? value) {
  if (value is! List || value.isEmpty) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => Map<String, Object?>.from(item),
      )
      .map(
        (item) => TranscriptionSegment(
          text: _asString(item['text']) ?? '',
          startSeconds: _asDouble(item['start']) ?? 0,
          endSeconds: _asDouble(item['end']) ?? 0,
        ),
      )
      .toList(growable: false);
}

double? _asDouble(Object? value) => value is num ? value.toDouble() : null;
