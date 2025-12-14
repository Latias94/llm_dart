/// Google (Gemini) specific extension keys used in `LLMConfig.extensions`.
///
/// These keys are intentionally defined in the Google package (not `llm_dart_core`)
/// because they map to Gemini-specific request fields and tool configs.
abstract final class GoogleConfigKeys {
  static const String embeddingTaskType = 'embeddingTaskType';
  static const String embeddingTitle = 'embeddingTitle';

  static const String enableImageGeneration = 'enableImageGeneration';
  static const String responseModalities = 'responseModalities';
  static const String safetySettings = 'safetySettings';
  static const String maxInlineDataSize = 'maxInlineDataSize';
  static const String candidateCount = 'candidateCount';

  static const String defaultVoiceName = 'defaultVoiceName';
  static const String defaultSpeakerVoices = 'defaultSpeakerVoices';

  static const String googleFileSearchConfig = 'googleFileSearchConfig';
  static const String googleCodeExecutionEnabled = 'googleCodeExecutionEnabled';
  static const String googleUrlContextEnabled = 'googleUrlContextEnabled';
}
