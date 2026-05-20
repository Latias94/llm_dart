abstract final class OpenAIFilePurposes {
  static const String assistants = 'assistants';
  static const String batch = 'batch';
  static const String fineTune = 'fine-tune';
  static const String userData = 'user_data';
  static const String vision = 'vision';
}

final class OpenAIFilesSettings {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIFilesSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIFileUpload {
  final List<int> bytes;
  final String filename;
  final String purpose;
  final String mediaType;
  final int? expiresAfter;

  const OpenAIFileUpload({
    required this.bytes,
    required this.filename,
    this.purpose = OpenAIFilePurposes.assistants,
    this.mediaType = 'application/octet-stream',
    this.expiresAfter,
  });
}
