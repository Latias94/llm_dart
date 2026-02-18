import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/responses.dart';

class OpenResponsesProviderSettings {
  /// Provider id used in `providerMetadata` namespaces and logs.
  ///
  /// In the upstream AI SDK, this is the `name` argument. The effective
  /// provider id for Responses models is `${name}.responses`.
  final String name;

  /// Endpoint URL to an Open Responses-compatible Responses route.
  ///
  /// Expected shapes:
  /// - `http://host/v1/responses`
  /// - `http://host/v1/` (the provider will append `responses`)
  final String url;

  /// Optional API key. Many local deployments do not require auth.
  final String? apiKey;

  /// Optional extra headers merged into request headers.
  final Map<String, String>? headers;

  /// Optional request timeout.
  final Duration? timeout;

  const OpenResponsesProviderSettings({
    required this.name,
    required this.url,
    this.apiKey,
    this.headers,
    this.timeout,
  });
}

/// Open Responses provider factory.
///
/// Usage:
/// ```dart
/// final openResponses = createOpenResponses(
///   name: 'local',
///   url: 'http://localhost:1234/v1/responses',
/// );
///
/// final result = await generateText(
///   model: openResponses('mistralai/ministral-3b'),
///   prompt: 'Hello',
/// );
/// ```
class OpenResponsesProvider with ProviderV3Defaults implements ProviderV3 {
  final OpenResponsesProviderSettings settings;

  const OpenResponsesProvider(this.settings);

  @override
  ChatCapability languageModel(String modelId) => call(modelId);

  ChatCapability call(
    String modelId, {
    String? previousResponseId,
    Map<String, dynamic>? extraBody,
    Map<String, String>? extraHeaders,
  }) {
    final name = settings.name.trim();
    if (name.isEmpty) {
      throw const InvalidArgumentError(
        argument: 'name',
        message: 'Open Responses provider name must not be empty.',
      );
    }

    final providerId = '$name.responses';
    final baseUrl = _normalizeBaseUrl(settings.url);

    final config = _OpenResponsesConfig(
      providerId: providerId,
      providerName: 'Open Responses ($name)',
      apiKey: settings.apiKey,
      baseUrl: baseUrl,
      model: modelId,
      timeout: settings.timeout,
      extraBody: extraBody,
      extraHeaders: {
        ...?settings.headers,
        ...?extraHeaders,
      },
      previousResponseId: previousResponseId,
    );

    final client = OpenAIClient(config);
    return OpenAIResponses(client, config);
  }
}

String _normalizeBaseUrl(String url) {
  final raw = url.trim();
  if (raw.isEmpty) {
    throw const InvalidArgumentError(
      argument: 'url',
      message: 'Open Responses provider url must not be empty.',
    );
  }

  Uri uri;
  try {
    uri = Uri.parse(raw);
  } catch (_) {
    throw InvalidArgumentError(
      argument: 'url',
      value: raw,
      message: 'Invalid URL.',
    );
  }

  if (!uri.hasScheme || uri.host.isEmpty) {
    throw InvalidArgumentError(
      argument: 'url',
      value: raw,
      message: 'URL must include a scheme and host.',
    );
  }

  // If users pass `.../v1/responses`, strip the final `responses`.
  final segments = uri.pathSegments.toList();
  if (segments.isNotEmpty && segments.last == 'responses') {
    segments.removeLast();
  }

  // Preserve `v1` if present, and ensure the baseUrl ends with a slash so that
  // `dio` relative paths behave consistently across platforms.
  final normalized = uri.replace(
    pathSegments: segments,
    query: '',
    fragment: '',
  );

  var out = normalized.toString();
  if (!out.endsWith('/')) out = '$out/';
  return out;
}

class _OpenResponsesConfig implements OpenAIResponsesConfig {
  @override
  final String providerId;

  @override
  final String providerName;

  @override
  final String? apiKey;

  @override
  final String baseUrl;

  @override
  final String model;

  @override
  final String? endpointPrefix;

  @override
  final Map<String, dynamic>? extraBody;

  @override
  final Map<String, String>? extraHeaders;

  @override
  final int? maxTokens;

  @override
  final double? temperature;

  @override
  final String? systemPrompt;

  @override
  final Duration? timeout;

  @override
  final double? topP;

  @override
  final int? topK;

  @override
  final List<Tool>? tools;

  @override
  final ToolChoice? toolChoice;

  @override
  final ReasoningEffort? reasoningEffort;

  @override
  final StructuredOutputFormat? jsonSchema;

  @override
  final String? voice;

  @override
  final String? embeddingEncodingFormat;

  @override
  final int? embeddingDimensions;

  @override
  final List<String>? stopSequences;

  @override
  final String? user;

  @override
  final ServiceTier? serviceTier;

  @override
  final String? previousResponseId;

  @override
  final List<OpenAIBuiltInTool>? builtInTools;

  const _OpenResponsesConfig({
    required this.providerId,
    required this.providerName,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    required this.timeout,
    this.endpointPrefix,
    this.extraBody,
    this.extraHeaders,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.reasoningEffort,
    this.jsonSchema,
    this.voice,
    this.embeddingEncodingFormat,
    this.embeddingDimensions,
    this.stopSequences,
    this.user,
    this.serviceTier,
    this.previousResponseId,
    this.builtInTools,
  });

  @override
  LLMConfig? get originalConfig => null;

  @override
  T? getProviderOption<T>(String key) => null;
}
