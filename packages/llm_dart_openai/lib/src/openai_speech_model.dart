import 'dart:typed_data';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_options.dart';

final class OpenAISpeechModel implements SpeechModel {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAISpeechModelSettings settings;

  @override
  final String modelId;

  OpenAISpeechModel({
    required this.apiKey,
    required this.modelId,
    required this.transport,
    required this.profile,
    String? baseUrl,
    ProviderModelOptions settings = const OpenAISpeechModelSettings(),
  })  : settings = _resolveSettings(settings),
        baseUrl = baseUrl ?? profile.defaultBaseUrl;

  @override
  String get providerId => profile.providerId;

  Uri get speechUri => Uri.parse('$baseUrl/audio/speech');

  Map<String, String> get defaultHeaders => profile.buildHeaders(
        apiKey: apiKey,
        extraHeaders: {
          if (settings.organization case final organization?)
            'openai-organization': organization,
          if (settings.project case final project?) 'openai-project': project,
          ...settings.headers,
        },
      );

  @override
  Future<SpeechGenerationResult> generateSpeech(
    SpeechGenerationRequest request,
  ) async {
    final providerOptions = request.callOptions.providerOptions;
    if (providerOptions != null && providerOptions is! OpenAISpeechOptions) {
      throw ArgumentError.value(
        providerOptions,
        'request.callOptions.providerOptions',
        'Expected OpenAISpeechOptions for OpenAI-family speech models.',
      );
    }

    final options = providerOptions as OpenAISpeechOptions?;
    final response = await transport.send(
      TransportRequest(
        uri: speechUri,
        method: TransportMethod.post,
        headers: {
          ...defaultHeaders,
          'content-type': 'application/json',
          'accept': 'application/octet-stream',
          if (request.callOptions.headers case final headers?) ...headers,
        },
        body: {
          'model': modelId,
          'input': request.text,
          if (request.voice != null) 'voice': request.voice,
          if (options?.outputFormat case final outputFormat?)
            'response_format': outputFormat,
          if (options?.instructions case final instructions?)
            'instructions': instructions,
          if (options?.speed case final speed?) 'speed': speed,
          if (options?.language case final language?) 'language': language,
        },
        timeout: request.callOptions.timeout,
        cancellation: request.callOptions.cancellation,
        responseType: TransportResponseType.bytes,
      ),
    );

    final bytes = _decodeBytes(response.body);
    if (bytes.isEmpty) {
      throw StateError(
          'Expected OpenAI speech generation to return audio bytes.');
    }

    return SpeechGenerationResult(
      audioBytes: bytes,
      mediaType: _lookupHeader(response.headers, 'content-type') ??
          _defaultMediaTypeForOutputFormat(options?.outputFormat),
      responseMetadata: ModelResponseMetadata(
        timestamp: DateTime.now().toUtc(),
        modelId: modelId,
        headers: response.headers,
      ),
    );
  }

  static OpenAISpeechModelSettings _resolveSettings(
    ProviderModelOptions settings,
  ) {
    if (settings is OpenAISpeechModelSettings) {
      return settings;
    }

    throw ArgumentError.value(
      settings,
      'settings',
      'Expected OpenAISpeechModelSettings for OpenAI-family speech models.',
    );
  }
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
            'Expected speech byte value to be int, got ${value.runtimeType}.',
          );
        }

        return value;
      }).toList(),
    );
  }

  throw StateError(
    'Expected OpenAI speech response bytes but received ${body.runtimeType}.',
  );
}

String? _lookupHeader(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
}

String _defaultMediaTypeForOutputFormat(String? outputFormat) {
  return switch (outputFormat) {
    'wav' => 'audio/wav',
    'opus' => 'audio/opus',
    'aac' => 'audio/aac',
    'flac' => 'audio/flac',
    'pcm' => 'audio/pcm',
    _ => 'audio/mpeg',
  };
}
