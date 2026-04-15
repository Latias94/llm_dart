import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_model_describer.dart';
import 'openai_multipart_body.dart';
import 'openai_non_text_model_support.dart';
import 'openai_options.dart';

final class OpenAITranscriptionModel
    implements TranscriptionModel, CapabilityDescribedModel {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAITranscriptionModelSettings settings;

  @override
  final String modelId;

  OpenAITranscriptionModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    String? baseUrl,
    ProviderModelOptions settings = const OpenAITranscriptionModelSettings(),
  })  : settings = resolveOpenAIModelSettings(
          settings,
          parameterName: 'settings',
          expectedTypeName:
              'OpenAITranscriptionModelSettings for OpenAI-family transcription models',
        ),
        baseUrl = baseUrl ?? profile.defaultBaseUrl;

  @override
  String get providerId => profile.providerId;

  @override
  ModelCapabilityProfile get capabilityProfile {
    return describeOpenAITranscriptionModel(
      modelId,
      profile: profile,
    );
  }

  Uri get transcriptionUri => Uri.parse('$baseUrl/audio/transcriptions');

  Map<String, String> get defaultHeaders => buildOpenAIFamilyDefaultHeaders(
        profile: profile,
        apiKey: apiKey,
        organization: settings.organization,
        project: settings.project,
        headers: settings.headers,
      );

  @override
  Future<TranscriptionResult> transcribe(TranscriptionRequest request) async {
    final options = resolveOpenAIProviderOptions<OpenAITranscriptionOptions>(
      request.callOptions,
      parameterName: 'request.callOptions.providerOptions',
      expectedTypeName:
          'OpenAITranscriptionOptions for OpenAI-family transcription models',
    );
    final responseFormat =
        options?.responseFormat ?? OpenAITranscriptionResponseFormat.json;
    if (options != null &&
        options.timestampGranularities.isNotEmpty &&
        responseFormat != OpenAITranscriptionResponseFormat.verboseJson) {
      throw ArgumentError(
        'OpenAITranscriptionOptions.timestampGranularities require responseFormat=verboseJson.',
      );
    }

    final multipart = buildOpenAIMultipartBody(
      fields: [
        OpenAIMultipartField.file(
          name: 'file',
          filename: _buildFilename(request.mediaType),
          mediaType: request.mediaType ?? 'audio/wav',
          bytes: request.audioBytes,
        ),
        OpenAIMultipartField.text(
          name: 'model',
          value: modelId,
        ),
        if (options?.language case final language?)
          OpenAIMultipartField.text(
            name: 'language',
            value: language,
          ),
        if (options?.prompt case final prompt?)
          OpenAIMultipartField.text(
            name: 'prompt',
            value: prompt,
          ),
        if (options?.temperature case final temperature?)
          OpenAIMultipartField.text(
            name: 'temperature',
            value: temperature.toString(),
          ),
        OpenAIMultipartField.text(
          name: 'response_format',
          value: responseFormat.value,
        ),
        for (final granularity in options?.timestampGranularities ?? const [])
          OpenAIMultipartField.text(
            name: 'timestamp_granularities[]',
            value: granularity.value,
          ),
      ],
    );

    final response = await transport.send(
      TransportRequest(
        uri: transcriptionUri,
        method: TransportMethod.post,
        headers: {
          ...defaultHeaders,
          'content-type': multipart.contentType,
          'accept': _acceptForResponseFormat(responseFormat),
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: multipart.bytes,
        timeout: request.callOptions.timeout,
        cancellation: request.callOptions.cancellation,
        responseType: _responseTypeForResponseFormat(responseFormat),
      ),
    );

    return switch (responseFormat) {
      OpenAITranscriptionResponseFormat.json ||
      OpenAITranscriptionResponseFormat.verboseJson =>
        _decodeJsonResponse(
          response.body,
          headers: response.headers,
          responseFormat: responseFormat,
        ),
      _ => TranscriptionResult(
          text: _decodePlainTextBody(response.body),
          responseMetadata: ModelResponseMetadata(
            timestamp: DateTime.now().toUtc(),
            modelId: modelId,
            headers: response.headers,
          ),
          providerMetadata: ProviderMetadata.forNamespace(
            'openai',
            {
              'responseFormat': responseFormat.value,
            },
          ),
        ),
    };
  }

  TranscriptionResult _decodeJsonResponse(
    Object? body, {
    required Map<String, String> headers,
    required OpenAITranscriptionResponseFormat responseFormat,
  }) {
    final json = decodeOpenAIJsonObject(
      body,
      responseName: 'transcription',
    );
    final text = json['text'];
    if (text is! String || text.isEmpty) {
      throw StateError(
        'Expected OpenAI transcription response to contain non-empty text.',
      );
    }

    final segments = _decodeSegments(json['segments']);

    final providerMetadata = ProviderMetadata.forNamespace(
      'openai',
      {
        'responseFormat': responseFormat.value,
        if (json['language'] != null) 'language': json['language'],
        if (json['duration'] != null) 'durationSeconds': json['duration'],
        if (json['words'] != null) 'words': json['words'],
        if (json['segments'] != null) 'segments': json['segments'],
      },
    );

    return TranscriptionResult(
      text: text,
      segments: segments,
      language: openAIStringOrNull(json['language']),
      durationSeconds: openAIDoubleOrNull(json['duration']),
      responseMetadata: ModelResponseMetadata(
        timestamp: DateTime.now().toUtc(),
        modelId: modelId,
        headers: headers,
      ),
      providerMetadata: providerMetadata,
    );
  }

  String _decodePlainTextBody(Object? body) {
    if (body is String) {
      return body;
    }

    throw StateError(
      'Expected an OpenAI transcription plain-text response but received ${body.runtimeType}.',
    );
  }

  List<TranscriptionSegment> _decodeSegments(Object? value) {
    if (value is! List || value.isEmpty) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .map(
          (item) => TranscriptionSegment(
            text: openAIStringOrNull(item['text']) ?? '',
            startSeconds: openAIDoubleOrNull(item['start']) ?? 0,
            endSeconds: openAIDoubleOrNull(item['end']) ?? 0,
          ),
        )
        .toList(growable: false);
  }
}

String _buildFilename(String? mediaType) {
  final normalized = mediaType?.split(';').first.trim().toLowerCase();
  final extension = switch (normalized) {
    'audio/mpeg' || 'audio/mp3' => 'mp3',
    'audio/wav' => 'wav',
    'audio/x-wav' => 'wav',
    'audio/webm' => 'webm',
    'audio/mp4' => 'mp4',
    'audio/m4a' => 'm4a',
    'audio/ogg' => 'ogg',
    'audio/flac' => 'flac',
    _ => 'bin',
  };

  return 'audio.$extension';
}

String _acceptForResponseFormat(
    OpenAITranscriptionResponseFormat responseFormat) {
  return switch (responseFormat) {
    OpenAITranscriptionResponseFormat.json ||
    OpenAITranscriptionResponseFormat.verboseJson =>
      'application/json',
    OpenAITranscriptionResponseFormat.srt => 'text/plain',
    OpenAITranscriptionResponseFormat.text => 'text/plain',
    OpenAITranscriptionResponseFormat.vtt => 'text/vtt',
  };
}

TransportResponseType _responseTypeForResponseFormat(
  OpenAITranscriptionResponseFormat responseFormat,
) {
  return switch (responseFormat) {
    OpenAITranscriptionResponseFormat.json ||
    OpenAITranscriptionResponseFormat.verboseJson =>
      TransportResponseType.json,
    _ => TransportResponseType.plainText,
  };
}
