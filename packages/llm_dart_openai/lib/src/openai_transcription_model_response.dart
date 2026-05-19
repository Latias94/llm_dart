import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_json_support.dart';
import 'openai_non_text_model_support.dart';
import 'openai_transcription_options.dart';

TranscriptionResult decodeOpenAITranscriptionResponse({
  required Object? body,
  required String modelId,
  required Map<String, String> headers,
  required OpenAITranscriptionResponseFormat responseFormat,
}) {
  return switch (responseFormat) {
    OpenAITranscriptionResponseFormat.json ||
    OpenAITranscriptionResponseFormat.verboseJson =>
      decodeOpenAITranscriptionJsonResponse(
        body,
        modelId: modelId,
        headers: headers,
        responseFormat: responseFormat,
      ),
    _ => TranscriptionResult(
        text: decodeOpenAITranscriptionPlainTextBody(body),
        responseMetadata: ModelResponseMetadata(
          timestamp: DateTime.now().toUtc(),
          modelId: modelId,
          headers: headers,
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

TranscriptionResult decodeOpenAITranscriptionJsonResponse(
  Object? body, {
  required String modelId,
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

  final segments = decodeOpenAITranscriptionSegmentsOrWords(json);

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
    language: normalizeOpenAITranscriptionLanguage(
      openAIStringOrNull(json['language']),
    ),
    durationSeconds: openAIDoubleOrNull(json['duration']),
    responseMetadata: ModelResponseMetadata(
      timestamp: DateTime.now().toUtc(),
      modelId: modelId,
      headers: headers,
    ),
    providerMetadata: providerMetadata,
  );
}

String decodeOpenAITranscriptionPlainTextBody(Object? body) {
  if (body is String) {
    return body;
  }

  throw StateError(
    'Expected an OpenAI transcription plain-text response but received ${body.runtimeType}.',
  );
}

List<TranscriptionSegment> decodeOpenAITranscriptionSegments(Object? value) {
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

List<TranscriptionSegment> decodeOpenAITranscriptionSegmentsOrWords(
  Map<String, Object?> json,
) {
  if (json.containsKey('segments')) {
    return decodeOpenAITranscriptionSegments(json['segments']);
  }

  return decodeOpenAITranscriptionWords(json['words']);
}

List<TranscriptionSegment> decodeOpenAITranscriptionWords(Object? value) {
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

String? normalizeOpenAITranscriptionLanguage(String? language) {
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
