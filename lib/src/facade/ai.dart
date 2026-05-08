import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic_pkg;
import 'package:llm_dart_google/llm_dart_google.dart' as google_pkg;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_pkg;
import 'package:llm_dart_transport/llm_dart_transport.dart';

/// Creates an OpenAI provider facade.
///
/// This is the short root-package equivalent of `AI.openai(...)`.
openai_pkg.OpenAI openai({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
  openai_pkg.OpenAIFamilyProfile? profile,
}) {
  return AI.openai(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    profile: profile,
  );
}

/// Creates an OpenRouter provider facade backed by the OpenAI-family adapter.
openai_pkg.OpenAI openRouter({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return AI.openRouter(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Creates a DeepSeek provider facade backed by the OpenAI-family adapter.
openai_pkg.OpenAI deepSeek({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return AI.deepSeek(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Creates a Groq provider facade backed by the OpenAI-family adapter.
openai_pkg.OpenAI groq({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return AI.groq(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Creates an xAI provider facade backed by the OpenAI-family adapter.
openai_pkg.OpenAI xai({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return AI.xai(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Creates a Phind provider facade backed by the OpenAI-family adapter.
openai_pkg.OpenAI phind({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return AI.phind(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Creates a Google provider facade.
///
/// This is the short root-package equivalent of `AI.google(...)`.
google_pkg.Google google({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return AI.google(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Creates an Anthropic provider facade.
///
/// This is the short root-package equivalent of `AI.anthropic(...)`.
anthropic_pkg.Anthropic anthropic({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return AI.anthropic(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Stable model-factory facade for the refactored architecture.
///
/// This is the new primary entry path for the root package.
/// The legacy builder surface remains available through
/// `package:llm_dart/legacy.dart`.
final class AI {
  const AI._();

  static openai_pkg.OpenAI openai({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
    openai_pkg.OpenAIFamilyProfile? profile,
  }) {
    return openai_pkg.OpenAI(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      profile: profile,
    );
  }

  static openai_pkg.OpenAI openRouter({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return _openaiFamily(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      profile: const openai_pkg.OpenRouterProfile(),
    );
  }

  static openai_pkg.OpenAI deepSeek({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return _openaiFamily(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      profile: const openai_pkg.DeepSeekProfile(),
    );
  }

  static openai_pkg.OpenAI groq({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return _openaiFamily(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      profile: const openai_pkg.GroqProfile(),
    );
  }

  static openai_pkg.OpenAI xai({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return _openaiFamily(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      profile: const openai_pkg.XAIProfile(),
    );
  }

  static openai_pkg.OpenAI phind({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return _openaiFamily(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      profile: const openai_pkg.PhindProfile(),
    );
  }

  static google_pkg.Google google({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return google_pkg.Google(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }

  static anthropic_pkg.Anthropic anthropic({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return anthropic_pkg.Anthropic(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }

  static openai_pkg.OpenAI _openaiFamily({
    required String apiKey,
    required openai_pkg.OpenAIFamilyProfile profile,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return openai_pkg.OpenAI(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      profile: profile,
    );
  }
}
