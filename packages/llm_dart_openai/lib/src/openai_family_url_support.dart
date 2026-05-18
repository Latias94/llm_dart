import 'openai_family_profile.dart';

String normalizeOpenAIFamilyBaseUrl(
  String? baseUrl,
  OpenAIFamilyProfile profile,
) {
  final normalized =
      (baseUrl == null || baseUrl.isEmpty) ? profile.defaultBaseUrl : baseUrl;
  return normalized.endsWith('/')
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}
