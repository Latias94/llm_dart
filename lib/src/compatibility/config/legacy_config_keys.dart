/// Centralized extension keys used by the legacy root-package compatibility
/// surface.
///
/// These keys are intentionally grouped in one place so the compatibility
/// builder, factories, transport helpers, and provider config adapters do not
/// keep drifting apart through repeated string literals.
abstract final class LegacyExtensionKeys {
  // Shared/provider-agnostic compatibility options
  static const reasoningEffort = 'reasoningEffort';
  static const jsonSchema = 'jsonSchema';
  static const voice = 'voice';
  static const embeddingEncodingFormat = 'embeddingEncodingFormat';
  static const embeddingDimensions = 'embeddingDimensions';
  static const useResponsesApi = 'useResponsesAPI';
  static const previousResponseId = 'previousResponseId';
  static const builtInTools = 'builtInTools';

  // Search compatibility options
  static const webSearchEnabled = 'webSearchEnabled';
  static const webSearchConfig = 'webSearchConfig';
  static const searchPrompt = 'searchPrompt';
  static const useOnlineShortcut = 'useOnlineShortcut';
  static const maxSearchResults = 'maxSearchResults';

  // xAI legacy compatibility options
  static const xaiLiveSearch = 'liveSearch';
  static const xaiSearchParameters = 'searchParameters';

  // HTTP / transport compatibility options
  static const httpProxy = 'httpProxy';
  static const customHeaders = 'customHeaders';
  static const connectionTimeout = 'connectionTimeout';
  static const receiveTimeout = 'receiveTimeout';
  static const sendTimeout = 'sendTimeout';
  static const enableHttpLogging = 'enableHttpLogging';
  static const bypassSslVerification = 'bypassSSLVerification';
  static const sslCertificate = 'sslCertificate';
  static const customTransportClient = 'customTransportClient';
  static const customDio = 'customDio';

  // OpenAI legacy compatibility options
  static const frequencyPenalty = 'frequencyPenalty';
  static const presencePenalty = 'presencePenalty';
  static const logitBias = 'logitBias';
  static const seed = 'seed';
  static const parallelToolCalls = 'parallelToolCalls';
  static const logprobs = 'logprobs';
  static const topLogprobs = 'topLogprobs';
  static const verbosity = 'verbosity';

  // DeepSeek legacy factory compatibility options
  static const deepSeekTopLogprobs = 'top_logprobs';
  static const deepSeekFrequencyPenalty = 'frequency_penalty';
  static const deepSeekPresencePenalty = 'presence_penalty';
  static const deepSeekResponseFormat = 'response_format';

  // Anthropic legacy compatibility options
  static const reasoning = 'reasoning';
  static const thinkingBudgetTokens = 'thinkingBudgetTokens';
  static const interleavedThinking = 'interleavedThinking';
  static const metadata = 'metadata';
  static const container = 'container';
  static const mcpServers = 'mcpServers';

  // Google legacy compatibility options
  static const includeThoughts = 'includeThoughts';
  static const enableImageGeneration = 'enableImageGeneration';
  static const responseModalities = 'responseModalities';
  static const safetySettings = 'safetySettings';
  static const maxInlineDataSize = 'maxInlineDataSize';
  static const candidateCount = 'candidateCount';
  static const embeddingTaskType = 'embeddingTaskType';
  static const embeddingTitle = 'embeddingTitle';

  // Ollama legacy compatibility options
  static const numCtx = 'numCtx';
  static const numGpu = 'numGpu';
  static const numThread = 'numThread';
  static const numa = 'numa';
  static const numBatch = 'numBatch';
  static const keepAlive = 'keepAlive';
  static const raw = 'raw';

  // ElevenLabs legacy compatibility options
  static const voiceId = 'voiceId';
  static const stability = 'stability';
  static const similarityBoost = 'similarityBoost';
  static const style = 'style';
  static const useSpeakerBoost = 'useSpeakerBoost';
}

const Set<String> legacyHttpExtensionKeys = {
  LegacyExtensionKeys.customHeaders,
  LegacyExtensionKeys.connectionTimeout,
  LegacyExtensionKeys.receiveTimeout,
  LegacyExtensionKeys.sendTimeout,
  LegacyExtensionKeys.enableHttpLogging,
  LegacyExtensionKeys.httpProxy,
  LegacyExtensionKeys.bypassSslVerification,
  LegacyExtensionKeys.sslCertificate,
  LegacyExtensionKeys.customTransportClient,
  LegacyExtensionKeys.customDio,
};
