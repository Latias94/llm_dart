import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/openai/builtin_tools.dart';
import '../../../../providers/openai/config.dart';
import '../../../config/provider_defaults.dart';

/// Internal grouped views for compatibility-era OpenAI config reads.
///
/// The public `OpenAIConfig` constructor intentionally remains flat for
/// migration stability. Compatibility implementations should prefer these
/// grouped views so the internal ownership of fields becomes more explicit.
extension OpenAIConfigCompatibilityViews on OpenAIConfig {
  OpenAIRequestCompatibilityConfigView get requestCompat =>
      OpenAIRequestCompatibilityConfigView(this);

  OpenAIResponsesCompatibilityConfigView get responsesCompat =>
      OpenAIResponsesCompatibilityConfigView(this);

  OpenAIEmbeddingCompatibilityConfigView get embeddingCompat =>
      OpenAIEmbeddingCompatibilityConfigView(this);

  OpenAIAudioCompatibilityConfigView get audioCompat =>
      OpenAIAudioCompatibilityConfigView(this);
}

final class OpenAIRequestCompatibilityConfigView {
  final OpenAIConfig _config;

  const OpenAIRequestCompatibilityConfigView(this._config);

  String get model => _config.model;
  int? get maxTokens => _config.maxTokens;
  double? get temperature => _config.temperature;
  double? get topP => _config.topP;
  int? get topK => _config.topK;
  String? get systemPrompt => _config.systemPrompt;
  List<Tool>? get tools => _config.tools;
  ToolChoice? get toolChoice => _config.toolChoice;
  List<String>? get stopSequences => _config.stopSequences;
  ReasoningEffort? get reasoningEffort => _config.reasoningEffort;
  StructuredOutputFormat? get jsonSchema => _config.jsonSchema;
  String? get user => _config.user;
  ServiceTier? get serviceTier => _config.serviceTier;
}

final class OpenAIResponsesCompatibilityConfigView {
  final OpenAIConfig _config;

  const OpenAIResponsesCompatibilityConfigView(this._config);

  bool get enabled => _config.useResponsesAPI;
  String? get previousResponseId => _config.previousResponseId;
  List<OpenAIBuiltInTool>? get builtInTools => _config.builtInTools;
}

final class OpenAIEmbeddingCompatibilityConfigView {
  final OpenAIConfig _config;

  const OpenAIEmbeddingCompatibilityConfigView(this._config);

  String get encodingFormat => _config.embeddingEncodingFormat ?? 'float';
  int? get dimensions => _config.embeddingDimensions;
}

final class OpenAIAudioCompatibilityConfigView {
  final OpenAIConfig _config;

  const OpenAIAudioCompatibilityConfigView(this._config);

  String get defaultVoice =>
      _config.voice ?? ProviderDefaults.openaiDefaultVoice;
}
