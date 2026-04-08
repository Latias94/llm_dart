import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'elevenlabs_options.dart';
import 'elevenlabs_shared.dart';

/// Package-owned modern ElevenLabs speech model surface.
final class ElevenLabsSpeechModel implements SpeechModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final ElevenLabsSpeechModelSettings settings;

  @override
  final String modelId;

  ElevenLabsSpeechModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings = const ElevenLabsSpeechModelSettings(),
  })  : baseUrl = normalizeElevenLabsBaseUrl(baseUrl),
        settings = _resolveSettings(settings);

  @override
  String get providerId => 'elevenlabs';

  Map<String, String> get defaultHeaders => {
        'xi-api-key': apiKey,
        ...settings.headers,
      };

  @override
  Future<SpeechGenerationResult> generateSpeech(
    SpeechGenerationRequest request,
  ) async {
    final providerOptions = request.callOptions.providerOptions;
    if (providerOptions != null &&
        providerOptions is! ElevenLabsSpeechOptions) {
      throw ArgumentError.value(
        providerOptions,
        'request.callOptions.providerOptions',
        'Expected ElevenLabsSpeechOptions for ElevenLabs speech models.',
      );
    }

    final options = providerOptions as ElevenLabsSpeechOptions?;
    _validateSpeechOptions(options);

    final voiceId = _resolveVoiceId(request.voice);
    final outputFormat = _mapOutputFormat(options?.outputFormat);
    final response = await transport.send(
      TransportRequest(
        uri: _speechUri(
          voiceId,
          queryParameters: {
            'output_format': outputFormat,
            if (options?.enableLogging case final enableLogging?)
              'enable_logging': '$enableLogging',
            if (options?.optimizeStreamingLatency case final latency?)
              'optimize_streaming_latency': '$latency',
          },
        ),
        method: TransportMethod.post,
        headers: {
          ...defaultHeaders,
          'content-type': 'application/json',
          'accept': 'application/octet-stream',
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: _buildRequestBody(
          request,
          options: options,
        ),
        timeout: request.callOptions.timeout,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.bytes,
      ),
    );

    final audioBytes = _decodeBytes(response.body);
    if (audioBytes.isEmpty) {
      throw StateError(
        'Expected ElevenLabs speech generation to return audio bytes.',
      );
    }

    return SpeechGenerationResult(
      audioBytes: audioBytes,
      mediaType: lookupHeader(response.headers, 'content-type') ??
          _defaultMediaTypeForOutputFormat(outputFormat),
      providerMetadata: elevenLabsResponseMetadata(response.headers),
    );
  }

  Uri _speechUri(
    String voiceId, {
    required Map<String, String> queryParameters,
  }) {
    final uri = Uri.parse('$baseUrl/text-to-speech/$voiceId');
    return queryParameters.isEmpty
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  String _resolveVoiceId(String? requestVoice) {
    if (requestVoice != null && requestVoice.isNotEmpty) {
      return requestVoice;
    }

    final defaultVoiceId = settings.defaultVoiceId;
    if (defaultVoiceId != null && defaultVoiceId.isNotEmpty) {
      return defaultVoiceId;
    }

    return elevenLabsDefaultVoiceId;
  }

  Map<String, Object?> _buildRequestBody(
    SpeechGenerationRequest request, {
    required ElevenLabsSpeechOptions? options,
  }) {
    final body = <String, Object?>{
      'text': request.text,
      'model_id': modelId,
    };

    final voiceSettings = <String, Object?>{
      if (_resolveRatio(settings.stability, options?.stability)
          case final stability?)
        'stability': stability,
      if (_resolveRatio(
        settings.similarityBoost,
        options?.similarityBoost,
      )
          case final similarityBoost?)
        'similarity_boost': similarityBoost,
      if (_resolveRatio(settings.style, options?.style) case final style?)
        'style': style,
      if (options?.speed case final speed?) 'speed': speed,
      if (_resolveBool(
        settings.useSpeakerBoost,
        options?.useSpeakerBoost,
      )
          case final useSpeakerBoost?)
        'use_speaker_boost': useSpeakerBoost,
    };

    if (voiceSettings.isNotEmpty) {
      body['voice_settings'] = voiceSettings;
    }

    if (options?.languageCode case final languageCode?) {
      body['language_code'] = languageCode;
    }

    if (options != null && options.pronunciationDictionaryLocators.isNotEmpty) {
      body['pronunciation_dictionary_locators'] = options
          .pronunciationDictionaryLocators
          .map(
            (locator) => {
              'pronunciation_dictionary_id': locator.pronunciationDictionaryId,
              if (locator.versionId != null) 'version_id': locator.versionId,
            },
          )
          .toList(growable: false);
    }

    if (options?.seed case final seed?) {
      body['seed'] = seed;
    }

    if (options?.previousText case final previousText?) {
      body['previous_text'] = previousText;
    }

    if (options?.nextText case final nextText?) {
      body['next_text'] = nextText;
    }

    if (options != null && options.previousRequestIds.isNotEmpty) {
      body['previous_request_ids'] = options.previousRequestIds;
    }

    if (options != null && options.nextRequestIds.isNotEmpty) {
      body['next_request_ids'] = options.nextRequestIds;
    }

    if (options?.textNormalization case final textNormalization?) {
      body['apply_text_normalization'] = textNormalization.name;
    }

    if (options?.applyLanguageTextNormalization
        case final applyLanguageTextNormalization?) {
      body['apply_language_text_normalization'] =
          applyLanguageTextNormalization;
    }

    return body;
  }

  static ElevenLabsSpeechModelSettings _resolveSettings(
    ProviderModelOptions settings,
  ) {
    if (settings is ElevenLabsSpeechModelSettings) {
      return settings;
    }

    throw ArgumentError.value(
      settings,
      'settings',
      'Expected ElevenLabsSpeechModelSettings for ElevenLabs speech models.',
    );
  }
}

void _validateSpeechOptions(ElevenLabsSpeechOptions? options) {
  if (options == null) {
    return;
  }

  _validateRatio(options.stability, 'providerOptions.stability');
  _validateRatio(
    options.similarityBoost,
    'providerOptions.similarityBoost',
  );
  _validateRatio(options.style, 'providerOptions.style');

  if (options.seed != null &&
      (options.seed! < 0 || options.seed! > 4294967295)) {
    throw ArgumentError.value(
      options.seed,
      'providerOptions.seed',
      'ElevenLabs speech seed must be between 0 and 4294967295.',
    );
  }

  _validateIdList(
    options.previousRequestIds,
    'providerOptions.previousRequestIds',
  );
  _validateIdList(
    options.nextRequestIds,
    'providerOptions.nextRequestIds',
  );

  if (options.pronunciationDictionaryLocators.length > 3) {
    throw ArgumentError.value(
      options.pronunciationDictionaryLocators,
      'providerOptions.pronunciationDictionaryLocators',
      'ElevenLabs supports at most 3 pronunciation dictionary locators.',
    );
  }

  for (final locator in options.pronunciationDictionaryLocators) {
    if (locator.pronunciationDictionaryId.isEmpty) {
      throw ArgumentError.value(
        locator.pronunciationDictionaryId,
        'providerOptions.pronunciationDictionaryLocators',
        'Pronunciation dictionary IDs must not be empty.',
      );
    }
  }
}

void _validateRatio(
  double? value,
  String field,
) {
  if (value == null) {
    return;
  }

  if (value < 0 || value > 1) {
    throw ArgumentError.value(
      value,
      field,
      'ElevenLabs voice-setting values must be between 0 and 1.',
    );
  }
}

void _validateIdList(
  List<String> values,
  String field,
) {
  if (values.length > 3) {
    throw ArgumentError.value(
      values,
      field,
      'ElevenLabs supports at most 3 request IDs per continuity field.',
    );
  }

  if (values.any((value) => value.isEmpty)) {
    throw ArgumentError.value(
      values,
      field,
      'ElevenLabs request IDs must not be empty.',
    );
  }
}

double? _resolveRatio(
  double? modelValue,
  double? invocationValue,
) {
  return invocationValue ?? modelValue;
}

bool? _resolveBool(
  bool? modelValue,
  bool? invocationValue,
) {
  return invocationValue ?? modelValue;
}

Uint8List _decodeBytes(Object? body) {
  if (body is Uint8List) {
    return body;
  }

  if (body is List<int>) {
    return Uint8List.fromList(body);
  }

  if (body is List) {
    return Uint8List.fromList(
      body.map((value) {
        if (value is! int) {
          throw StateError(
            'Expected ElevenLabs speech byte value to be int, got ${value.runtimeType}.',
          );
        }

        return value;
      }).toList(),
    );
  }

  throw StateError(
    'Expected ElevenLabs speech response bytes but received ${body.runtimeType}.',
  );
}

String _mapOutputFormat(String? outputFormat) {
  return switch (outputFormat) {
    null || '' => 'mp3_44100_128',
    'mp3' || 'mp3_128' => 'mp3_44100_128',
    'mp3_32' => 'mp3_44100_32',
    'mp3_64' => 'mp3_44100_64',
    'mp3_96' => 'mp3_44100_96',
    'mp3_192' => 'mp3_44100_192',
    'pcm' => 'pcm_44100',
    'ulaw' => 'ulaw_8000',
    _ => outputFormat,
  };
}

String _defaultMediaTypeForOutputFormat(String outputFormat) {
  if (outputFormat.startsWith('pcm_')) {
    return 'audio/pcm';
  }

  if (outputFormat.startsWith('ulaw_')) {
    return 'audio/basic';
  }

  return 'audio/mpeg';
}
