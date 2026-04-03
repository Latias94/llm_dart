import '../../builder/llm_builder.dart';
import '../../core/capability.dart';

/// Create a new LLM builder instance.
///
/// This is the compatibility entry point for builder-era provider creation.
LLMBuilder ai() => LLMBuilder();

/// Create a provider with the given configuration.
///
/// This convenience helper remains available for compatibility-oriented code.
Future<ChatCapability> createProvider({
  required String providerId,
  required String apiKey,
  required String model,
  String? baseUrl,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  Duration? timeout,
  bool stream = false,
  double? topP,
  int? topK,
  @Deprecated(
    'createProvider.extensions is a legacy raw compatibility escape hatch. '
    'Prefer typed builder/provider APIs or the stable AI facade instead.',
  )
  Map<String, dynamic>? extensions,
}) async {
  var builder = LLMBuilder().provider(providerId).apiKey(apiKey).model(model);

  if (baseUrl != null) builder = builder.baseUrl(baseUrl);
  if (temperature != null) builder = builder.temperature(temperature);
  if (maxTokens != null) builder = builder.maxTokens(maxTokens);
  if (systemPrompt != null) builder = builder.systemPrompt(systemPrompt);
  if (timeout != null) builder = builder.timeout(timeout);
  if (topP != null) builder = builder.topP(topP);
  if (topK != null) builder = builder.topK(topK);

  if (extensions != null) {
    for (final entry in extensions.entries) {
      builder = builder.extension(entry.key, entry.value);
    }
  }

  return await builder.build();
}
