final class OpenAIModerationSettings {
  final String? defaultModel;
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIModerationSettings({
    this.defaultModel,
    this.organization,
    this.project,
    this.headers = const {},
  });
}
