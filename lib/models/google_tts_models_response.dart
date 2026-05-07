part of 'google_tts_models.dart';

/// Google TTS response.
class GoogleTTSResponse {
  /// Generated audio data as bytes.
  final List<int> audioData;

  /// Content type (for example, `audio/pcm`).
  final String? contentType;

  /// Usage information if available.
  final UsageInfo? usage;

  /// Model used for generation.
  final String? model;

  /// Additional metadata from the response.
  final Map<String, dynamic>? metadata;

  const GoogleTTSResponse({
    required this.audioData,
    this.contentType,
    this.usage,
    this.model,
    this.metadata,
  });

  /// Create a response from the Google API response payload.
  factory GoogleTTSResponse.fromApiResponse(Map<String, dynamic> response) {
    final candidate = response['candidates']?[0];
    final content = candidate?['content'];
    final parts = content?['parts'];
    final inlineData = parts?[0]?['inlineData'];
    final data = inlineData?['data'] as String?;

    if (data == null) {
      throw ArgumentError('No audio data found in response');
    }

    return GoogleTTSResponse(
      audioData: base64Decode(data),
      contentType: inlineData?['mimeType'] as String?,
      usage: response['usageMetadata'] != null
          ? _parseUsageInfo(response['usageMetadata'] as Map<String, dynamic>)
          : null,
      model: response['modelVersion'] as String?,
      metadata: response,
    );
  }

  static UsageInfo _parseUsageInfo(Map<String, dynamic> usageMetadata) {
    return UsageInfo(
      promptTokens: usageMetadata['promptTokenCount'] as int?,
      completionTokens: usageMetadata['candidatesTokenCount'] as int?,
      totalTokens: usageMetadata['totalTokenCount'] as int?,
    );
  }
}
