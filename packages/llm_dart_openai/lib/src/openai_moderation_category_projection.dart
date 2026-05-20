typedef OpenAIModerationCategoryDecoder<T> = T Function(
  Object? value, {
  required String path,
});

final class OpenAIModerationCategoryValues<T> {
  final T hate;
  final T hateThreatening;
  final T harassment;
  final T harassmentThreatening;
  final T selfHarm;
  final T selfHarmIntent;
  final T selfHarmInstructions;
  final T sexual;
  final T sexualMinors;
  final T violence;
  final T violenceGraphic;

  const OpenAIModerationCategoryValues({
    required this.hate,
    required this.hateThreatening,
    required this.harassment,
    required this.harassmentThreatening,
    required this.selfHarm,
    required this.selfHarmIntent,
    required this.selfHarmInstructions,
    required this.sexual,
    required this.sexualMinors,
    required this.violence,
    required this.violenceGraphic,
  });

  factory OpenAIModerationCategoryValues.fromJson(
    Map<String, Object?> json, {
    required String pathPrefix,
    required OpenAIModerationCategoryDecoder<T> decode,
  }) {
    return OpenAIModerationCategoryValues(
      hate: decode(json['hate'], path: '$pathPrefix.hate'),
      hateThreatening: decode(
        json['hate/threatening'],
        path: '$pathPrefix.hate/threatening',
      ),
      harassment: decode(
        json['harassment'],
        path: '$pathPrefix.harassment',
      ),
      harassmentThreatening: decode(
        json['harassment/threatening'],
        path: '$pathPrefix.harassment/threatening',
      ),
      selfHarm: decode(json['self-harm'], path: '$pathPrefix.self-harm'),
      selfHarmIntent: decode(
        json['self-harm/intent'],
        path: '$pathPrefix.self-harm/intent',
      ),
      selfHarmInstructions: decode(
        json['self-harm/instructions'],
        path: '$pathPrefix.self-harm/instructions',
      ),
      sexual: decode(json['sexual'], path: '$pathPrefix.sexual'),
      sexualMinors: decode(
        json['sexual/minors'],
        path: '$pathPrefix.sexual/minors',
      ),
      violence: decode(json['violence'], path: '$pathPrefix.violence'),
      violenceGraphic: decode(
        json['violence/graphic'],
        path: '$pathPrefix.violence/graphic',
      ),
    );
  }

  Map<String, T> toJson() {
    return {
      'hate': hate,
      'hate/threatening': hateThreatening,
      'harassment': harassment,
      'harassment/threatening': harassmentThreatening,
      'self-harm': selfHarm,
      'self-harm/intent': selfHarmIntent,
      'self-harm/instructions': selfHarmInstructions,
      'sexual': sexual,
      'sexual/minors': sexualMinors,
      'violence': violence,
      'violence/graphic': violenceGraphic,
    };
  }

  Iterable<String> matchingKeys(bool Function(T value) test) sync* {
    for (final entry in toJson().entries) {
      if (test(entry.value)) {
        yield entry.key;
      }
    }
  }
}

Map<String, T> openAIModerationCategoryJson<T>({
  required T hate,
  required T hateThreatening,
  required T harassment,
  required T harassmentThreatening,
  required T selfHarm,
  required T selfHarmIntent,
  required T selfHarmInstructions,
  required T sexual,
  required T sexualMinors,
  required T violence,
  required T violenceGraphic,
}) {
  return OpenAIModerationCategoryValues(
    hate: hate,
    hateThreatening: hateThreatening,
    harassment: harassment,
    harassmentThreatening: harassmentThreatening,
    selfHarm: selfHarm,
    selfHarmIntent: selfHarmIntent,
    selfHarmInstructions: selfHarmInstructions,
    sexual: sexual,
    sexualMinors: sexualMinors,
    violence: violence,
    violenceGraphic: violenceGraphic,
  ).toJson();
}
