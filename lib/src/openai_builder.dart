import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart';

/// OpenAI-specific LLM builder with provider-specific configuration methods.
///
/// This wrapper is provided by the **umbrella** `llm_dart` package. Provider
/// subpackages do not depend on `llm_dart_builder`.
class OpenAIBuilder {
  final LLMBuilder _baseBuilder;

  OpenAIBuilder(this._baseBuilder);

  // ========== OpenAI-specific configuration methods ==========

  OpenAIBuilder frequencyPenalty(double penalty) {
    _baseBuilder.option('frequencyPenalty', penalty);
    return this;
  }

  OpenAIBuilder presencePenalty(double penalty) {
    _baseBuilder.option('presencePenalty', penalty);
    return this;
  }

  OpenAIBuilder logitBias(Map<String, double> bias) {
    _baseBuilder.option('logitBias', bias);
    return this;
  }

  OpenAIBuilder seed(int seedValue) {
    _baseBuilder.option('seed', seedValue);
    return this;
  }

  OpenAIBuilder parallelToolCalls(bool enabled) {
    _baseBuilder.option('parallelToolCalls', enabled);
    return this;
  }

  OpenAIBuilder logprobs(bool enabled) {
    _baseBuilder.option('logprobs', enabled);
    return this;
  }

  OpenAIBuilder topLogprobs(int count) {
    _baseBuilder.option('topLogprobs', count);
    return this;
  }

  OpenAIBuilder verbosity(Verbosity level) {
    _baseBuilder.option('verbosity', level.value);
    return this;
  }

  // ========== OpenAI Responses API Configuration ==========

  OpenAIBuilder useResponsesAPI([bool use = true]) {
    _baseBuilder.providerOption('openai', 'useResponsesAPI', use);
    return this;
  }

  OpenAIBuilder previousResponseId(String responseId) {
    _baseBuilder.providerOption('openai', 'previousResponseId', responseId);
    return this;
  }

  OpenAIBuilder webSearchTool() {
    useResponsesAPI(true);
    _baseBuilder.providerTool(OpenAIProviderTools.webSearch());
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.webSearch());
    _baseBuilder.providerOption(
      'openai',
      'builtInTools',
      tools.map((t) => t.toJson()).toList(),
    );
    return this;
  }

  OpenAIBuilder fileSearchTool({
    List<String>? vectorStoreIds,
    Map<String, dynamic>? parameters,
  }) {
    useResponsesAPI(true);
    _baseBuilder.providerTool(
      OpenAIProviderTools.fileSearch(
        vectorStoreIds: vectorStoreIds,
        parameters: parameters,
      ),
    );
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.fileSearch(
      vectorStoreIds: vectorStoreIds,
      parameters: parameters,
    ));
    _baseBuilder.providerOption(
      'openai',
      'builtInTools',
      tools.map((t) => t.toJson()).toList(),
    );
    return this;
  }

  OpenAIBuilder computerUseTool({
    required int displayWidth,
    required int displayHeight,
    required String environment,
    Map<String, dynamic>? parameters,
  }) {
    useResponsesAPI(true);
    _baseBuilder.providerTool(
      OpenAIProviderTools.computerUse(
        displayWidth: displayWidth,
        displayHeight: displayHeight,
        environment: environment,
        parameters: parameters,
      ),
    );
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.computerUse(
      displayWidth: displayWidth,
      displayHeight: displayHeight,
      environment: environment,
      parameters: parameters,
    ));
    _baseBuilder.providerOption(
      'openai',
      'builtInTools',
      tools.map((t) => t.toJson()).toList(),
    );
    return this;
  }

  List<OpenAIBuiltInTool> _getBuiltInTools() {
    final raw = _baseBuilder.currentConfig
        .getProviderOption<dynamic>('openai', 'builtInTools');

    if (raw is List<OpenAIBuiltInTool>) {
      return List<OpenAIBuiltInTool>.from(raw);
    }

    if (raw is List) {
      final parsed = <OpenAIBuiltInTool>[];
      for (final item in raw) {
        if (item is OpenAIBuiltInTool) {
          parsed.add(item);
          continue;
        }
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);
        final type = map['type'];
        if (type is! String) continue;

        switch (type) {
          case 'web_search_preview':
            OpenAIWebSearchContextSize? contextSize;
            final rawContextSize = map['search_context_size'];
            if (rawContextSize is String) {
              contextSize = OpenAIWebSearchContextSize.tryParse(rawContextSize);
            }
            parsed.add(OpenAIBuiltInTools.webSearch(contextSize: contextSize));
            break;
          case 'file_search':
            final vectorStoreIds = (map['vector_store_ids'] as List?)
                ?.whereType<String>()
                .toList();
            final parameters = Map<String, dynamic>.from(map)
              ..remove('type')
              ..remove('vector_store_ids');
            parsed.add(
              OpenAIBuiltInTools.fileSearch(
                vectorStoreIds:
                    vectorStoreIds?.isEmpty == true ? null : vectorStoreIds,
                parameters: parameters.isEmpty ? null : parameters,
              ),
            );
            break;
          case 'computer_use_preview':
            final displayWidth = map['display_width'] as int?;
            final displayHeight = map['display_height'] as int?;
            final environment = map['environment'] as String?;
            if (displayWidth == null ||
                displayHeight == null ||
                environment == null) {
              continue;
            }
            final parameters = Map<String, dynamic>.from(map)
              ..remove('type')
              ..remove('display_width')
              ..remove('display_height')
              ..remove('environment');
            parsed.add(
              OpenAIBuiltInTools.computerUse(
                displayWidth: displayWidth,
                displayHeight: displayHeight,
                environment: environment,
                parameters: parameters.isEmpty ? null : parameters,
              ),
            );
            break;
        }
      }

      return parsed;
    }

    return <OpenAIBuiltInTool>[];
  }

  OpenAIBuilder webSearch({
    OpenAIWebSearchContextSize contextSize = OpenAIWebSearchContextSize.medium,
  }) {
    useResponsesAPI(true);
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.webSearch(contextSize: contextSize));
    _baseBuilder.providerOption(
      'openai',
      'builtInTools',
      tools.map((t) => t.toJson()).toList(),
    );
    return this;
  }

  // ========== Build methods ==========

  Future<ChatCapability> build() async => _baseBuilder.build();

  Future<TextToSpeechCapability> buildSpeech() async =>
      _baseBuilder.buildSpeech();

  Future<StreamingTextToSpeechCapability> buildStreamingSpeech() async =>
      _baseBuilder.buildStreamingSpeech();

  Future<SpeechToTextCapability> buildTranscription() async =>
      _baseBuilder.buildTranscription();

  Future<AudioTranslationCapability> buildAudioTranslation() async =>
      _baseBuilder.buildAudioTranslation();

  Future<RealtimeAudioCapability> buildRealtimeAudio() async =>
      _baseBuilder.buildRealtimeAudio();

  Future<ImageGenerationCapability> buildImageGeneration() async =>
      _baseBuilder.buildImageGeneration();

  Future<EmbeddingCapability> buildEmbedding() async =>
      _baseBuilder.buildEmbedding();

  Future<OpenAIProvider> buildOpenAIResponses() async {
    final isResponsesAPIEnabled = _baseBuilder.currentConfig
            .getProviderOption<bool>('openai', 'useResponsesAPI') ??
        false;
    if (!isResponsesAPIEnabled) {
      useResponsesAPI(true);
    }

    final provider = await build();

    if (provider is! OpenAIProvider) {
      throw StateError(
          'Expected OpenAIProvider but got ${provider.runtimeType}.');
    }

    if (provider.responses == null) {
      throw StateError('OpenAI Responses API not properly initialized.');
    }

    return provider;
  }
}
