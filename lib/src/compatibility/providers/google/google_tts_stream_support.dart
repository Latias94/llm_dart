part of 'tts.dart';

final class GoogleTTSStreamSupport {
  const GoogleTTSStreamSupport();

  Stream<GoogleTTSStreamEvent> generateSpeechStream({
    required GoogleClient client,
    required String endpoint,
    required Map<String, dynamic> requestBody,
  }) async* {
    try {
      final stream = client.postStream(
        endpoint,
        data: requestBody,
      );

      await for (final chunk in stream) {
        final data = _normalizeChunkData(chunk.data);
        if (data == null) {
          continue;
        }

        for (final event in parseChunk(data)) {
          yield event;
        }
      }
    } catch (e) {
      yield GoogleTTSErrorEvent(message: 'Google TTS streaming failed: $e');
    }
  }

  List<GoogleTTSStreamEvent> parseChunk(Map<String, dynamic> data) {
    final events = <GoogleTTSStreamEvent>[];

    try {
      final candidate = data['candidates']?[0];
      final content = candidate?['content'];
      final parts = content?['parts'];
      final inlineData = parts?[0]?['inlineData'];
      final audioData = inlineData?['data'] as String?;

      if (audioData != null) {
        events.add(GoogleTTSAudioDataEvent(data: base64.decode(audioData)));
      }

      if (candidate?['finishReason'] != null) {
        final response = GoogleTTSResponse.fromApiResponse(data);
        events.add(GoogleTTSCompletionEvent(response));
      }
    } catch (e) {
      events.add(
        GoogleTTSErrorEvent(message: 'Error processing stream chunk: $e'),
      );
    }

    return events;
  }

  Map<String, dynamic>? _normalizeChunkData(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return null;
  }
}
