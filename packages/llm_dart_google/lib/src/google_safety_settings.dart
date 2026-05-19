enum GoogleHarmCategory {
  unspecified('HARM_CATEGORY_UNSPECIFIED'),
  hateSpeech('HARM_CATEGORY_HATE_SPEECH'),
  dangerousContent('HARM_CATEGORY_DANGEROUS_CONTENT'),
  harassment('HARM_CATEGORY_HARASSMENT'),
  sexuallyExplicit('HARM_CATEGORY_SEXUALLY_EXPLICIT'),
  civicIntegrity('HARM_CATEGORY_CIVIC_INTEGRITY');

  const GoogleHarmCategory(this.value);

  final String value;
}

enum GoogleHarmBlockThreshold {
  unspecified('HARM_BLOCK_THRESHOLD_UNSPECIFIED'),
  blockLowAndAbove('BLOCK_LOW_AND_ABOVE'),
  blockMediumAndAbove('BLOCK_MEDIUM_AND_ABOVE'),
  blockOnlyHigh('BLOCK_ONLY_HIGH'),
  blockNone('BLOCK_NONE'),
  off('OFF');

  const GoogleHarmBlockThreshold(this.value);

  final String value;
}

final class GoogleSafetySetting {
  final GoogleHarmCategory category;
  final GoogleHarmBlockThreshold threshold;

  const GoogleSafetySetting({
    required this.category,
    required this.threshold,
  });

  Map<String, Object?> toJson() {
    return {
      'category': category.value,
      'threshold': threshold.value,
    };
  }
}
