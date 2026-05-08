/// OpenAI audio translation request.
///
/// This is a provider-owned compatibility model for the legacy
/// `/audio/translations` endpoint. It intentionally stays outside the shared
/// audio model layer because audio translation is not a cross-provider
/// capability contract in this package.
class AudioTranslationRequest {
  /// Audio data as bytes (for direct audio input)
  final List<int>? audioData;

  /// File path (for file input)
  final String? filePath;

  /// Model to use for translation
  final String? model;

  /// Audio format hint
  final String? format;

  /// Prompt to guide translation style
  final String? prompt;

  /// Response format (json, text, srt, verbose_json, vtt)
  final String? responseFormat;

  /// Temperature for translation (0.0-1.0)
  final double? temperature;

  const AudioTranslationRequest({
    this.audioData,
    this.filePath,
    this.model,
    this.format,
    this.prompt,
    this.responseFormat,
    this.temperature,
  });

  /// Create translation request from audio data
  factory AudioTranslationRequest.fromAudio(
    List<int> audioData, {
    String? model,
    String? format,
    String? prompt,
    String? responseFormat,
    double? temperature,
  }) =>
      AudioTranslationRequest(
        audioData: audioData,
        model: model,
        format: format,
        prompt: prompt,
        responseFormat: responseFormat,
        temperature: temperature,
      );

  /// Create translation request from file
  factory AudioTranslationRequest.fromFile(
    String filePath, {
    String? model,
    String? format,
    String? prompt,
    String? responseFormat,
    double? temperature,
  }) =>
      AudioTranslationRequest(
        filePath: filePath,
        model: model,
        format: format,
        prompt: prompt,
        responseFormat: responseFormat,
        temperature: temperature,
      );

  Map<String, dynamic> toJson() => {
        if (audioData != null) 'audio_data': audioData,
        if (filePath != null) 'file_path': filePath,
        if (model != null) 'model': model,
        if (format != null) 'format': format,
        if (prompt != null) 'prompt': prompt,
        if (responseFormat != null) 'response_format': responseFormat,
        if (temperature != null) 'temperature': temperature,
      };

  factory AudioTranslationRequest.fromJson(Map<String, dynamic> json) =>
      AudioTranslationRequest(
        audioData: json['audio_data'] != null
            ? List<int>.from(json['audio_data'] as List)
            : null,
        filePath: json['file_path'] as String?,
        model: json['model'] as String?,
        format: json['format'] as String?,
        prompt: json['prompt'] as String?,
        responseFormat: json['response_format'] as String?,
        temperature: json['temperature'] as double?,
      );
}
