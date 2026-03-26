abstract interface class OpenAIFamilyProfile {
  String get providerId;

  String get defaultBaseUrl;

  Map<String, String> buildHeaders({
    required String apiKey,
    Map<String, String> extraHeaders = const {},
  });
}

final class OpenAIProfile implements OpenAIFamilyProfile {
  @override
  final String providerId;

  @override
  final String defaultBaseUrl;

  const OpenAIProfile({
    this.providerId = 'openai',
    this.defaultBaseUrl = 'https://api.openai.com/v1',
  });

  @override
  Map<String, String> buildHeaders({
    required String apiKey,
    Map<String, String> extraHeaders = const {},
  }) {
    return <String, String>{
      'authorization': 'Bearer $apiKey',
      ...extraHeaders,
    };
  }
}
