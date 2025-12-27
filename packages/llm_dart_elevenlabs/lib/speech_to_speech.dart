import 'dart:convert';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/llm_error.dart';
import 'package:llm_dart_core/models/audio_models.dart';

import 'client.dart';
import 'config.dart';

class SpeechToSpeechRequest {
  final List<int> audioData;

  /// The target voice to generate.
  ///
  /// If omitted, defaults to the provider's configured `defaultVoiceId`.
  final String? voiceId;

  final String? modelId;

  /// Voice settings overriding stored settings for the given voice.
  ///
  /// ElevenLabs expects a JSON string in multipart form-data (`voice_settings`).
  final Map<String, dynamic>? voiceSettings;

  final int? seed;
  final bool? removeBackgroundNoise;
  final String? fileFormat;

  /// Matches ElevenLabs' query parameter.
  final bool? enableLogging;

  /// Matches ElevenLabs' query parameter.
  final int? optimizeStreamingLatency;

  /// Matches ElevenLabs' query parameter.
  final String? outputFormat;

  final String filename;

  const SpeechToSpeechRequest({
    required this.audioData,
    this.voiceId,
    this.modelId,
    this.voiceSettings,
    this.seed,
    this.removeBackgroundNoise,
    this.fileFormat,
    this.enableLogging,
    this.optimizeStreamingLatency,
    this.outputFormat,
    this.filename = 'audio.mp3',
  });

  FormData toFormData() {
    return FormData.fromMap({
      'audio': MultipartFile.fromBytes(
        audioData,
        filename: filename,
      ),
      if (modelId != null) 'model_id': modelId,
      if (voiceSettings != null) 'voice_settings': jsonEncode(voiceSettings),
      if (seed != null) 'seed': seed,
      if (removeBackgroundNoise != null)
        'remove_background_noise': removeBackgroundNoise,
      if (fileFormat != null) 'file_format': fileFormat,
    });
  }

  Map<String, String> toQueryParams() => {
        if (enableLogging != null) 'enable_logging': '$enableLogging',
        if (optimizeStreamingLatency != null)
          'optimize_streaming_latency': '$optimizeStreamingLatency',
        if (outputFormat != null) 'output_format': outputFormat!,
      };
}

class SpeechToSpeechResponse {
  final List<int> audioData;
  final String? contentType;
  final String voiceId;
  final String? modelId;

  const SpeechToSpeechResponse({
    required this.audioData,
    required this.voiceId,
    this.contentType,
    this.modelId,
  });

  TTSResponse asTtsResponse() => TTSResponse(
        audioData: audioData,
        contentType: contentType,
        voice: voiceId,
        model: modelId,
      );
}

class ElevenLabsSpeechToSpeech {
  final ElevenLabsClient client;
  final ElevenLabsConfig config;

  ElevenLabsSpeechToSpeech(this.client, this.config);

  Future<SpeechToSpeechResponse> convert(
    SpeechToSpeechRequest request, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }

    final voiceId = request.voiceId ?? config.defaultVoiceId;
    try {
      final audioBytes = await client.postBinaryFormData(
        'speech-to-speech/$voiceId',
        request.toFormData(),
        queryParams: request.toQueryParams(),
        cancelToken: cancelToken,
      );

      return SpeechToSpeechResponse(
        audioData: audioBytes,
        voiceId: voiceId,
        contentType: 'audio/mpeg',
        modelId: request.modelId,
      );
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error during speech-to-speech: $e');
    }
  }

  Stream<AudioStreamEvent> convertStream(
    SpeechToSpeechRequest request, {
    CancelToken? cancelToken,
  }) async* {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }

    final voiceId = request.voiceId ?? config.defaultVoiceId;
    try {
      final response = await client.postStreamFormData(
        'speech-to-speech/$voiceId/stream',
        request.toFormData(),
        queryParams: request.toQueryParams(),
        cancelToken: cancelToken,
      );

      final responseBody = response.data;
      if (responseBody == null) {
        yield const AudioErrorEvent(message: 'Empty streaming response');
        return;
      }

      yield const AudioMetadataEvent(contentType: 'audio/mpeg');

      final stream = responseBody.stream;
      await for (final chunk in stream) {
        // ElevenLabs streams binary audio; do not UTF-8 decode the data.
        // However, Dio provides chunks as raw bytes; pass them through.
        if (chunk.isNotEmpty) {
          yield AudioDataEvent(data: chunk, isFinal: false);
        }
      }

      yield AudioDataEvent(data: const <int>[], isFinal: true);
    } on DioException catch (e) {
      yield AudioErrorEvent(message: e.message ?? 'Dio error');
    } catch (e) {
      if (e is LLMError) rethrow;
      yield AudioErrorEvent(message: 'Unexpected stream error: $e');
    }
  }
}
