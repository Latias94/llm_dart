import 'dart:convert';

import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/llm_error.dart';

import 'client.dart';
import 'config.dart';

class ForcedAlignmentRequest {
  final List<int> audioData;
  final String text;

  /// If true, the file will be streamed to the server and processed in chunks.
  /// This is useful for longer audio files.
  final bool? enabledSpooledFile;

  final String filename;

  const ForcedAlignmentRequest({
    required this.audioData,
    required this.text,
    this.enabledSpooledFile,
    this.filename = 'audio.mp3',
  });

  FormData toFormData() {
    return FormData.fromMap({
      'file': MultipartFile.fromBytes(
        audioData,
        filename: filename,
      ),
      'text': text,
      if (enabledSpooledFile != null)
        'enabled_spooled_file': enabledSpooledFile,
    });
  }
}

class ForcedAlignmentCharacter {
  final String text;
  final double start;
  final double end;

  const ForcedAlignmentCharacter({
    required this.text,
    required this.start,
    required this.end,
  });

  factory ForcedAlignmentCharacter.fromJson(Map<String, dynamic> json) =>
      ForcedAlignmentCharacter(
        text: json['text'] as String,
        start: (json['start'] as num).toDouble(),
        end: (json['end'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'start': start,
        'end': end,
      };
}

class ForcedAlignmentWord {
  final String text;
  final double start;
  final double end;
  final double loss;

  const ForcedAlignmentWord({
    required this.text,
    required this.start,
    required this.end,
    required this.loss,
  });

  factory ForcedAlignmentWord.fromJson(Map<String, dynamic> json) =>
      ForcedAlignmentWord(
        text: json['text'] as String,
        start: (json['start'] as num).toDouble(),
        end: (json['end'] as num).toDouble(),
        loss: (json['loss'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'start': start,
        'end': end,
        'loss': loss,
      };
}

class ForcedAlignmentResponse {
  final List<ForcedAlignmentCharacter> characters;
  final List<ForcedAlignmentWord> words;
  final double loss;

  const ForcedAlignmentResponse({
    required this.characters,
    required this.words,
    required this.loss,
  });

  factory ForcedAlignmentResponse.fromJson(Map<String, dynamic> json) {
    final characters = (json['characters'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ForcedAlignmentCharacter.fromJson)
        .toList(growable: false);
    final words = (json['words'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ForcedAlignmentWord.fromJson)
        .toList(growable: false);
    final loss = (json['loss'] as num).toDouble();

    return ForcedAlignmentResponse(
      characters: characters,
      words: words,
      loss: loss,
    );
  }

  Map<String, dynamic> toJson() => {
        'characters': characters.map((c) => c.toJson()).toList(),
        'words': words.map((w) => w.toJson()).toList(),
        'loss': loss,
      };

  @override
  String toString() => jsonEncode({
        'loss': loss,
        'characters': characters.length,
        'words': words.length,
      });
}

class ElevenLabsForcedAlignment {
  final ElevenLabsClient client;
  final ElevenLabsConfig config;

  ElevenLabsForcedAlignment(this.client, this.config);

  Future<ForcedAlignmentResponse> create(
    ForcedAlignmentRequest request, {
    CancelToken? cancelToken,
  }) async {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }

    try {
      final json = await client.postFormData(
        'forced-alignment',
        request.toFormData(),
        cancelToken: cancelToken,
      );
      return ForcedAlignmentResponse.fromJson(json);
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error during forced alignment: $e');
    }
  }
}
