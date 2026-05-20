import 'openai_family_profile.dart';

void requireOpenAIProfile(
  OpenAIFamilyProfile profile, {
  required String featureName,
}) {
  if (profile.providerId == 'openai') {
    return;
  }

  throw UnsupportedError(
    '$featureName currently supports only the OpenAI profile. '
    'Use a focused provider-owned or compatibility surface when another '
    'OpenAI-family provider exposes this feature separately.',
  );
}
