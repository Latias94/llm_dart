import 'package:llm_dart_core/llm_dart_core.dart';

import 'ai_errors.dart';
import 'types.dart';

/// Transcribe speech to text using a provider-agnostic capability.
///
/// AI SDK parity notes:
/// - If [request.audioUrl] is set, this helper will download the URL (using
///   [download] or [createDownload]) and forward the bytes as `audioData`.
/// - If [request.audioData], [request.filePath], or [request.cloudStorageUrl]
///   is already set, [request.audioUrl] is ignored (no download).
Future<TranscribeResult> transcribe({
  required SpeechToTextCapability model,
  required STTRequest request,
  DownloadFn? download,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final STTResponse response;

  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  final effectiveRequest = await _resolveAudioUrlIfNeeded(
    request,
    download: download,
    cancelToken: cancelToken,
  );

  if (effectiveCallOptions.isEmpty) {
    response =
        await model.speechToText(effectiveRequest, cancelToken: cancelToken);
  } else {
    if (model is! SpeechToTextCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides (headers/body) for transcription. '
        'Implement `SpeechToTextCallOptionsCapability` (or use a provider that does).',
      );
    }

    response = await (model as SpeechToTextCallOptionsCapability)
        .speechToTextWithCallOptions(
      effectiveRequest,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );
  }

  if (response.text.trim().isEmpty) {
    throw NoTranscriptGeneratedError(
      response: response,
      responses: response.responses,
    );
  }

  return TranscribeResult(rawResponse: response);
}

/// Convenience helper to transcribe from audio bytes.
Future<TranscribeResult> transcribeFromAudioBytes({
  required SpeechToTextCapability model,
  required List<int> audioData,
  String? modelId,
  String? language,
  String? format,
  bool includeWordTiming = false,
  bool includeConfidence = false,
  DownloadFn? download,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  return transcribe(
    model: model,
    request: STTRequest(
      audioData: audioData,
      model: modelId,
      language: language,
      format: format,
      includeWordTiming: includeWordTiming,
      includeConfidence: includeConfidence,
    ),
    download: download,
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

/// Convenience helper to transcribe from a remote URL.
Future<TranscribeResult> transcribeFromUrl({
  required SpeechToTextCapability model,
  required Uri url,
  String? modelId,
  String? language,
  String? format,
  bool includeWordTiming = false,
  bool includeConfidence = false,
  DownloadFn? download,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  return transcribe(
    model: model,
    request: STTRequest(
      audioUrl: url.toString(),
      model: modelId,
      language: language,
      format: format,
      includeWordTiming: includeWordTiming,
      includeConfidence: includeConfidence,
    ),
    download: download,
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

/// Convenience helper to transcribe from a local file path.
Future<TranscribeResult> transcribeFromFile({
  required SpeechToTextCapability model,
  required String filePath,
  String? modelId,
  String? language,
  String? format,
  bool includeWordTiming = false,
  bool includeConfidence = false,
  DownloadFn? download,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) {
  return transcribe(
    model: model,
    request: STTRequest(
      filePath: filePath,
      model: modelId,
      language: language,
      format: format,
      includeWordTiming: includeWordTiming,
      includeConfidence: includeConfidence,
    ),
    download: download,
    defaultCallOptions: defaultCallOptions,
    callOptions: callOptions,
    cancelToken: cancelToken,
  );
}

/// Translate audio to English (when supported by the provider).
Future<TranscribeResult> translateAudio({
  required AudioTranslationCapability model,
  required AudioTranslationRequest request,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final STTResponse response;

  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  if (effectiveCallOptions.isEmpty) {
    response = await model.translateAudio(request, cancelToken: cancelToken);
  } else {
    if (model is! AudioTranslationCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides (headers/body) for audio translation. '
        'Implement `AudioTranslationCallOptionsCapability` (or use a provider that does).',
      );
    }

    response = await (model as AudioTranslationCallOptionsCapability)
        .translateAudioWithCallOptions(
      request,
      callOptions: effectiveCallOptions,
      cancelToken: cancelToken,
    );
  }

  return TranscribeResult(rawResponse: response);
}

Future<STTRequest> _resolveAudioUrlIfNeeded(
  STTRequest request, {
  required DownloadFn? download,
  CancelToken? cancelToken,
}) async {
  // If the request already carries audio bytes or a provider-specific pointer,
  // ignore `audioUrl` to avoid surprising double inputs.
  if (request.audioData != null ||
      request.filePath != null ||
      request.cloudStorageUrl != null) {
    return _stripAudioUrl(request);
  }

  final url = request.audioUrl;
  if (url == null || url.trim().isEmpty) return request;

  final parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.hasScheme) {
    throw InvalidRequestError('Invalid audioUrl: $url');
  }

  final downloadFn = download ?? createDownload();
  final result = await downloadFn(url: parsed, cancelToken: cancelToken);

  final formatHint =
      request.format ?? _formatHintFromMediaType(result.mediaType);

  return STTRequest(
    audioData: result.data,
    model: request.model,
    language: request.language,
    format: formatHint,
    includeWordTiming: request.includeWordTiming,
    includeConfidence: request.includeConfidence,
    temperature: request.temperature,
    timestampGranularity: request.timestampGranularity,
    diarize: request.diarize,
    numSpeakers: request.numSpeakers,
    tagAudioEvents: request.tagAudioEvents,
    webhook: request.webhook,
    prompt: request.prompt,
    responseFormat: request.responseFormat,
    enableLogging: request.enableLogging,
  );
}

STTRequest _stripAudioUrl(STTRequest request) {
  if (request.audioUrl == null) return request;

  return STTRequest(
    audioData: request.audioData,
    filePath: request.filePath,
    cloudStorageUrl: request.cloudStorageUrl,
    model: request.model,
    language: request.language,
    format: request.format,
    includeWordTiming: request.includeWordTiming,
    includeConfidence: request.includeConfidence,
    temperature: request.temperature,
    timestampGranularity: request.timestampGranularity,
    diarize: request.diarize,
    numSpeakers: request.numSpeakers,
    tagAudioEvents: request.tagAudioEvents,
    webhook: request.webhook,
    prompt: request.prompt,
    responseFormat: request.responseFormat,
    enableLogging: request.enableLogging,
  );
}

String? _formatHintFromMediaType(String? mediaType) {
  final type = mediaType?.toLowerCase().trim();
  if (type == null || type.isEmpty) return null;

  if (type == 'audio/mpeg' || type == 'audio/mp3') return 'mp3';
  if (type == 'audio/wav' || type == 'audio/x-wav') return 'wav';
  if (type == 'audio/ogg') return 'ogg';
  if (type == 'audio/opus') return 'opus';
  if (type == 'audio/aac') return 'aac';
  if (type == 'audio/flac') return 'flac';
  if (type == 'audio/webm') return 'webm';
  if (type == 'audio/mp4' || type == 'audio/m4a') return 'm4a';

  return null;
}
