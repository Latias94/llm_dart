import 'dart:convert';
import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_options.dart';
import 'google_shared.dart';

final class GoogleSpeechModel implements SpeechModel {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final GoogleSpeechModelSettings settings;

  @override
  final String modelId;

  GoogleSpeechModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    String? baseUrl,
    ProviderModelOptions settings = const GoogleSpeechModelSettings(),
  })  : settings = _resolveSettings(settings),
        baseUrl = baseUrl ?? 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get providerId => 'google';

  Uri get generateContentUri =>
      Uri.parse('${_normalizedBaseUrl()}/models/$modelId:generateContent');

  @override
  Future<SpeechGenerationResult> generateSpeech(
    SpeechGenerationRequest request,
  ) async {
    final providerOptions = request.callOptions.providerOptions;
    if (providerOptions != null && providerOptions is! GoogleSpeechOptions) {
      throw ArgumentError.value(
        providerOptions,
        'request.callOptions.providerOptions',
        'Expected GoogleSpeechOptions for Google speech models.',
      );
    }

    final options = providerOptions as GoogleSpeechOptions?;
    _validateRequest(request, options);

    final response = await transport.send(
      TransportRequest(
        uri: generateContentUri,
        method: TransportMethod.post,
        headers: {
          'x-goog-api-key': apiKey,
          'content-type': 'application/json',
          'accept': 'application/json',
          ...settings.headers,
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: _buildRequestBody(request, options: options),
        timeout: request.callOptions.timeout,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return _decodeResponse(response.body);
  }

  void _validateRequest(
    SpeechGenerationRequest request,
    GoogleSpeechOptions? options,
  ) {
    if (request.voice != null &&
        options != null &&
        options.speakers.isNotEmpty) {
      throw ArgumentError(
        'Google speech models do not allow request.voice together with GoogleSpeechOptions.speakers.',
      );
    }

    if ((request.voice == null || request.voice!.isEmpty) &&
        options != null &&
        options.speakers.any(
            (speaker) => speaker.speaker.isEmpty || speaker.voice.isEmpty)) {
      throw ArgumentError(
        'GoogleSpeechOptions.speakers requires non-empty speaker and voice values.',
      );
    }
  }

  Map<String, Object?> _buildRequestBody(
    SpeechGenerationRequest request, {
    required GoogleSpeechOptions? options,
  }) {
    return {
      'contents': [
        {
          'parts': [
            {
              'text': request.text,
            },
          ],
        },
      ],
      'generationConfig': {
        'responseModalities': ['AUDIO'],
        'speechConfig': _buildSpeechConfig(request, options: options),
        if (options?.temperature case final temperature?)
          'temperature': temperature,
        if (options?.topP case final topP?) 'topP': topP,
        if (options?.topK case final topK?) 'topK': topK,
        if (options?.maxOutputTokens case final maxOutputTokens?)
          'maxOutputTokens': maxOutputTokens,
        if (options != null && options.stopSequences.isNotEmpty)
          'stopSequences': options.stopSequences,
      },
    };
  }

  Map<String, Object?> _buildSpeechConfig(
    SpeechGenerationRequest request, {
    required GoogleSpeechOptions? options,
  }) {
    if (options != null && options.speakers.isNotEmpty) {
      return {
        'multiSpeakerVoiceConfig': {
          'speakerVoiceConfigs': [
            for (final speaker in options.speakers)
              {
                'speaker': speaker.speaker,
                'voiceConfig': {
                  'prebuiltVoiceConfig': {
                    'voiceName': speaker.voice,
                  },
                },
              },
          ],
        },
      };
    }

    final voice = request.voice == null || request.voice!.isEmpty
        ? settings.defaultVoice
        : request.voice!;

    return {
      'voiceConfig': {
        'prebuiltVoiceConfig': {
          'voiceName': voice,
        },
      },
    };
  }

  SpeechGenerationResult _decodeResponse(Object? body) {
    final json = _decodeJsonObject(body);
    final candidates = asList(json['candidates']);
    if (candidates.isEmpty) {
      throw StateError(
        'Expected a Google speech response with at least one candidate.',
      );
    }

    final bytesBuilder = BytesBuilder(copy: false);
    final finishReasons = <String>[];
    String? mediaType;

    for (var index = 0; index < candidates.length; index += 1) {
      final candidate = asMap(candidates[index]);
      if (candidate == null) {
        throw StateError(
          'Expected Google speech candidate $index to be a JSON object.',
        );
      }

      final finishReason = asString(candidate['finishReason']);
      if (finishReason != null && finishReason.isNotEmpty) {
        finishReasons.add(finishReason);
      }

      final content = asMap(candidate['content']);
      final parts = asList(content?['parts']);
      for (final partValue in parts) {
        final part = asMap(partValue);
        final inlineData = asMap(part?['inlineData']);
        final bytes = decodeBase64(asString(inlineData?['data']));
        if (bytes == null || bytes.isEmpty) {
          continue;
        }

        bytesBuilder.add(bytes);
        mediaType ??= asString(inlineData?['mimeType']);
      }
    }

    final audioBytes = bytesBuilder.takeBytes();
    if (audioBytes.isEmpty) {
      throw StateError(
        'Expected Google speech generation to return audio bytes.',
      );
    }

    return SpeechGenerationResult(
      audioBytes: Uint8List.fromList(audioBytes),
      mediaType: mediaType ?? 'audio/pcm',
      providerMetadata: googleProviderMetadata(
        {
          'generationApi': 'generateContent',
          if (asString(json['modelVersion']) case final modelVersion?)
            'modelVersion': modelVersion,
          if (asMap(json['usageMetadata']) case final usageMetadata?)
            'usage': normalizeJsonValue(usageMetadata),
          if (finishReasons.isNotEmpty) 'finishReasons': finishReasons,
        },
      ),
    );
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
      'Expected a Google speech JSON object response but received ${body.runtimeType}.',
    );
  }

  String _normalizedBaseUrl() {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  static GoogleSpeechModelSettings _resolveSettings(
    ProviderModelOptions settings,
  ) {
    if (settings is GoogleSpeechModelSettings) {
      return settings;
    }

    throw ArgumentError.value(
      settings,
      'settings',
      'Expected GoogleSpeechModelSettings for Google speech models.',
    );
  }
}
