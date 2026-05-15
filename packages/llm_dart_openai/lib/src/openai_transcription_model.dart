import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_model_describer.dart';
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
  Future<TranscriptionResult> doGenerate(TranscriptionRequest request) async {
    final options = resolveOpenAIProviderOptions<OpenAITranscriptionOptions>(
      request.callOptions,
      parameterName: 'request.callOptions.providerOptions',
      expectedTypeName:
          'OpenAITranscriptionOptions for OpenAI-family transcription models',
    );
    _validateTranscriptionOptions(options);
    final responseFormat = _resolveResponseFormat(
      modelId: modelId,
      options: options,
    );
    _validateTimestampResponseFormat(
      modelId: modelId,
      responseFormat: responseFormat,
      options: options,
    );

    final multipart = buildTransportMultipartBody(
      fields: [
        TransportMultipartField.file(
          name: 'file',
          filename: _buildFilename(request.mediaType),
          mediaType: request.mediaType ?? 'audio/wav',
          bytes: request.audioBytes,
        ),
        TransportMultipartField.text(
          name: 'model',
          value: modelId,
        ),
        for (final include in options?.include ?? const <String>[])
          TransportMultipartField.text(
            name: 'include[]',
            value: include,
          ),
        if (options?.language case final language?)
          TransportMultipartField.text(
            name: 'language',
            value: language,
          ),
        if (options?.prompt case final prompt?)
          TransportMultipartField.text(
            name: 'prompt',
            value: prompt,
          ),
        if (options != null)
          TransportMultipartField.text(
            name: 'temperature',
            value: (options.temperature ?? 0).toString(),
          ),
        TransportMultipartField.text(
          name: 'response_format',
          value: responseFormat.value,
        ),
        for (final granularity in options?.timestampGranularities ?? const [])
          TransportMultipartField.text(
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
        maxRetries: request.callOptions.maxRetries,
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

    final segments = _decodeSegmentsOrWords(json);

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
      language: _normalizeLanguage(openAIStringOrNull(json['language'])),
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

  List<TranscriptionSegment> _decodeSegmentsOrWords(
    Map<String, Object?> json,
  ) {
    if (json.containsKey('segments')) {
      return _decodeSegments(json['segments']);
    }

    return _decodeWords(json['words']);
  }

  List<TranscriptionSegment> _decodeWords(Object? value) {
    if (value is! List || value.isEmpty) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .map(
          (item) => TranscriptionSegment(
            text: openAIStringOrNull(item['word']) ?? '',
            startSeconds: openAIDoubleOrNull(item['start']) ?? 0,
            endSeconds: openAIDoubleOrNull(item['end']) ?? 0,
          ),
        )
        .toList(growable: false);
  }
}

void _validateTranscriptionOptions(OpenAITranscriptionOptions? options) {
  if (options == null || options.temperature == null) {
    return;
  }

  final temperature = options.temperature!;
  if (temperature < 0 || temperature > 1) {
    throw ArgumentError.value(
      temperature,
      'providerOptions.temperature',
      'OpenAI transcription temperature must be between 0 and 1.',
    );
  }
}

OpenAITranscriptionResponseFormat _resolveResponseFormat({
  required String modelId,
  required OpenAITranscriptionOptions? options,
}) {
  if (options?.responseFormat case final responseFormat?) {
    return responseFormat;
  }

  if (options == null || options.timestampGranularities.isEmpty) {
    return OpenAITranscriptionResponseFormat.json;
  }

  if (_usesJsonTimestampTranscriptionFormat(modelId)) {
    return OpenAITranscriptionResponseFormat.json;
  }

  return OpenAITranscriptionResponseFormat.verboseJson;
}

void _validateTimestampResponseFormat({
  required String modelId,
  required OpenAITranscriptionResponseFormat responseFormat,
  required OpenAITranscriptionOptions? options,
}) {
  if (options == null || options.timestampGranularities.isEmpty) {
    return;
  }

  if (responseFormat == OpenAITranscriptionResponseFormat.verboseJson) {
    return;
  }

  if (_usesJsonTimestampTranscriptionFormat(modelId) &&
      responseFormat == OpenAITranscriptionResponseFormat.json) {
    return;
  }

  final expected = _usesJsonTimestampTranscriptionFormat(modelId)
      ? 'json or verboseJson'
      : 'verboseJson';
  throw ArgumentError(
    'OpenAITranscriptionOptions.timestampGranularities require responseFormat=$expected for $modelId.',
  );
}

bool _usesJsonTimestampTranscriptionFormat(String modelId) {
  return modelId == 'gpt-4o-transcribe' || modelId == 'gpt-4o-mini-transcribe';
}

String? _normalizeLanguage(String? language) {
  if (language == null || language.isEmpty) {
    return language;
  }

  return _languageMap[language.toLowerCase()] ?? language;
}

const Map<String, String> _languageMap = {
  'afrikaans': 'af',
  'arabic': 'ar',
  'armenian': 'hy',
  'azerbaijani': 'az',
  'belarusian': 'be',
  'bosnian': 'bs',
  'bulgarian': 'bg',
  'catalan': 'ca',
  'chinese': 'zh',
  'croatian': 'hr',
  'czech': 'cs',
  'danish': 'da',
  'dutch': 'nl',
  'english': 'en',
  'estonian': 'et',
  'finnish': 'fi',
  'french': 'fr',
  'galician': 'gl',
  'german': 'de',
  'greek': 'el',
  'hebrew': 'he',
  'hindi': 'hi',
  'hungarian': 'hu',
  'icelandic': 'is',
  'indonesian': 'id',
  'italian': 'it',
  'japanese': 'ja',
  'kannada': 'kn',
  'kazakh': 'kk',
  'korean': 'ko',
  'latvian': 'lv',
  'lithuanian': 'lt',
  'macedonian': 'mk',
  'malay': 'ms',
  'marathi': 'mr',
  'maori': 'mi',
  'nepali': 'ne',
  'norwegian': 'no',
  'persian': 'fa',
  'polish': 'pl',
  'portuguese': 'pt',
  'romanian': 'ro',
  'russian': 'ru',
  'serbian': 'sr',
  'slovak': 'sk',
  'slovenian': 'sl',
  'spanish': 'es',
  'swahili': 'sw',
  'swedish': 'sv',
  'tagalog': 'tl',
  'tamil': 'ta',
  'thai': 'th',
  'turkish': 'tr',
  'ukrainian': 'uk',
  'urdu': 'ur',
  'vietnamese': 'vi',
  'welsh': 'cy',
};

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
