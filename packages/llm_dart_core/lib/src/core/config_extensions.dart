import 'config.dart';
import '../models/tool_models.dart' show StructuredOutputFormat;
import 'web_search.dart' show WebSearchConfig, WebSearchLocation;

/// Well-known extension keys used in [LLMConfig.extensions].
/// These keys form the "contract" between the high-level builder APIs
/// (e.g. [LLMBuilder], HTTP helpers) and individual provider packages
/// (OpenAI, Anthropic, Google, DeepSeek, xAI, Ollama, ElevenLabs).
///
/// All new extension-based configuration should use these constants
/// instead of ad-hoc string literals so that:
/// - configuration is easier to discover and document,
/// - typos are avoided,
/// - refactors across packages remain safe.
abstract final class LLMConfigKeys {
  // Reasoning / structured output / embeddings
  static const String reasoningEffort = 'reasoningEffort';
  static const String jsonSchema = 'jsonSchema';
  static const String voice = 'voice';
  static const String embeddingEncodingFormat = 'embeddingEncodingFormat';
  static const String embeddingDimensions = 'embeddingDimensions';

  // Generic reasoning controls
  static const String reasoning = 'reasoning';
  static const String thinkingBudgetTokens = 'thinkingBudgetTokens';
  static const String interleavedThinking = 'interleavedThinking';
  static const String includeThoughts = 'includeThoughts';

  // Web search
  static const String webSearchEnabled = 'webSearchEnabled';
  static const String webSearchConfig = 'webSearchConfig';
  static const String webSearchLocation = 'webSearchLocation';
  static const String searchPrompt = 'searchPrompt';
  static const String useOnlineShortcut = 'useOnlineShortcut';
  static const String maxSearchResults = 'maxSearchResults';
  static const String stopSequences = 'stopSequences';

  // Image generation
  static const String imageSize = 'imageSize';
  static const String batchSize = 'batchSize';
  static const String imageSeed = 'imageSeed';
  static const String numInferenceSteps = 'numInferenceSteps';
  static const String guidanceScale = 'guidanceScale';
  static const String promptEnhancement = 'promptEnhancement';

  // Audio / speech
  static const String audioFormat = 'audioFormat';
  static const String audioQuality = 'audioQuality';
  static const String sampleRate = 'sampleRate';
  static const String languageCode = 'languageCode';
  static const String audioProcessingMode = 'audioProcessingMode';
  static const String includeTimestamps = 'includeTimestamps';
  static const String timestampGranularity = 'timestampGranularity';
  static const String textNormalization = 'textNormalization';
  static const String instructions = 'instructions';
  static const String previousText = 'previousText';
  static const String nextText = 'nextText';
  static const String audioSeed = 'audioSeed';
  static const String enableLogging = 'enableLogging';
  static const String optimizeStreamingLatency = 'optimizeStreamingLatency';
  static const String diarize = 'diarize';
  static const String numSpeakers = 'numSpeakers';
  static const String tagAudioEvents = 'tagAudioEvents';
  static const String webhook = 'webhook';
  static const String prompt = 'prompt';
  static const String responseFormat = 'responseFormat';
  static const String cloudStorageUrl = 'cloudStorageUrl';

  // HTTP configuration
  static const String httpProxy = 'httpProxy';
  static const String customHeaders = 'customHeaders';
  static const String bypassSSLVerification = 'bypassSSLVerification';
  static const String sslCertificate = 'sslCertificate';
  static const String connectionTimeout = 'connectionTimeout';
  static const String receiveTimeout = 'receiveTimeout';
  static const String sendTimeout = 'sendTimeout';
  static const String enableHttpLogging = 'enableHttpLogging';
  static const String customDio = 'customDio';
  static const String customInterceptors = 'customInterceptors';

  // OpenAI-style sampling controls (generic mapping keys)
  static const String frequencyPenalty = 'frequencyPenalty';
  static const String presencePenalty = 'presencePenalty';
  static const String logitBias = 'logitBias';
  static const String seed = 'seed';
  static const String parallelToolCalls = 'parallelToolCalls';
  static const String logprobs = 'logprobs';
  static const String topLogprobs = 'topLogprobs';

  // Provider-agnostic metadata container
  static const String metadata = 'metadata';
  static const String logger = 'logger';
  static const String container = 'container';
  static const String mcpServers = 'mcpServers';

  // Ollama / local LLM tuning
  static const String numCtx = 'numCtx';
  static const String numGpu = 'numGpu';
  static const String numThread = 'numThread';
  static const String numa = 'numa';
  static const String numBatch = 'numBatch';
  static const String keepAlive = 'keepAlive';
  static const String raw = 'raw';

  // ElevenLabs audio settings
  static const String voiceId = 'voiceId';
  static const String stability = 'stability';
  static const String similarityBoost = 'similarityBoost';
  static const String style = 'style';
  static const String useSpeakerBoost = 'useSpeakerBoost';
}

/// Typed key for values stored in [LLMConfig.extensions].
///
/// This is an optional, additive API: existing string-based keys in
/// [LLMConfigKeys] remain supported. Typed keys are useful when multiple
/// packages share extension contracts and you want stronger type hints.
final class LLMConfigKey<T> {
  final String name;
  const LLMConfigKey(this.name);

  @override
  String toString() => name;
}

/// Typed helpers for working with [LLMConfig.extensions].
extension LLMConfigTypedExtensions on LLMConfig {
  T? getKey<T>(LLMConfigKey<T> key) => getExtension<T>(key.name);

  bool hasKey<T>(LLMConfigKey<T> key) => hasExtension(key.name);

  LLMConfig withKey<T>(LLMConfigKey<T> key, T value) =>
      withExtension(key.name, value);
}

/// A curated set of commonly used typed extension keys.
///
/// We keep this list intentionally small to avoid duplicating every key in
/// [LLMConfigKeys]. Add more as cross-package contracts stabilize.
abstract final class LLMConfigTypedKeys {
  static const customHeaders = LLMConfigKey<Map<String, String>>(
    LLMConfigKeys.customHeaders,
  );

  static const metadata = LLMConfigKey<Map<String, dynamic>>(
    LLMConfigKeys.metadata,
  );

  static const reasoning = LLMConfigKey<bool>(
    LLMConfigKeys.reasoning,
  );

  static const reasoningEffort = LLMConfigKey<String>(
    LLMConfigKeys.reasoningEffort,
  );

  static const jsonSchema = LLMConfigKey<StructuredOutputFormat>(
    LLMConfigKeys.jsonSchema,
  );

  static const webSearchEnabled = LLMConfigKey<bool>(
    LLMConfigKeys.webSearchEnabled,
  );

  static const webSearchConfig = LLMConfigKey<WebSearchConfig>(
    LLMConfigKeys.webSearchConfig,
  );

  static const webSearchLocation = LLMConfigKey<WebSearchLocation>(
    LLMConfigKeys.webSearchLocation,
  );

  static const logger = LLMConfigKey<dynamic>(
    LLMConfigKeys.logger,
  );

  static const customDio = LLMConfigKey<dynamic>(
    LLMConfigKeys.customDio,
  );
}
