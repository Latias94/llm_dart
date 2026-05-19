import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_safety_settings.dart';

enum GoogleImageAspectRatio {
  square1x1('1:1'),
  portrait3x4('3:4'),
  landscape4x3('4:3'),
  portrait9x16('9:16'),
  landscape16x9('16:9');

  const GoogleImageAspectRatio(this.value);

  final String value;
}

enum GooglePersonGeneration {
  dontAllow('dont_allow'),
  allowAdult('allow_adult'),
  allowAll('allow_all');

  const GooglePersonGeneration(this.value);

  final String value;
}

final class GoogleImageOptions implements ProviderInvocationOptions {
  final GoogleImageAspectRatio? aspectRatio;
  final GooglePersonGeneration? personGeneration;
  final List<GoogleSafetySetting>? safetySettings;

  const GoogleImageOptions({
    this.aspectRatio,
    this.personGeneration,
    this.safetySettings,
  });
}
