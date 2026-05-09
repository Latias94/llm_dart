import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic_pkg;
import 'package:llm_dart_google/llm_dart_google.dart' as google_pkg;
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_pkg;
import 'package:llm_dart_transport/llm_dart_transport.dart';

/// Creates an OpenAI provider facade.
///
/// Prefer this short factory in new root-package code. `AI.openai(...)`
/// remains as an optional grouped-namespace alias.
openai_pkg.OpenAI openai({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
  openai_pkg.OpenAIFamilyProfile? profile,
}) {
  return openai_pkg.openai(
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
  String? appReferer,
  String? appTitle,
}) {
  return openai_pkg.openRouter(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    appReferer: appReferer,
    appTitle: appTitle,
  );
}

/// Creates a DeepSeek provider facade backed by the OpenAI-family adapter.
openai_pkg.OpenAI deepSeek({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return openai_pkg.deepSeek(
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
  return openai_pkg.groq(
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
  return openai_pkg.xai(
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
  return openai_pkg.phind(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Creates a Google provider facade.
///
/// Prefer this short factory in new root-package code. `AI.google(...)`
/// remains as an optional grouped-namespace alias.
google_pkg.Google google({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return google_pkg.google(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Creates an Anthropic provider facade.
///
/// Prefer this short factory in new root-package code. `AI.anthropic(...)`
/// remains as an optional grouped-namespace alias.
anthropic_pkg.Anthropic anthropic({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return anthropic_pkg.anthropic(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Optional grouped namespace for root provider factories.
///
/// New examples and docs should prefer the short root factories such as
/// `openai(...)`, `google(...)`, and `anthropic(...)` because they make the
/// concrete provider choice visible without an extra namespace hop.
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
    return openai_pkg.openai(
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
    String? appReferer,
    String? appTitle,
  }) {
    return openai_pkg.openRouter(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
      appReferer: appReferer,
      appTitle: appTitle,
    );
  }

  static openai_pkg.OpenAI deepSeek({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return openai_pkg.deepSeek(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }

  static openai_pkg.OpenAI groq({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return openai_pkg.groq(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }

  static openai_pkg.OpenAI xai({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return openai_pkg.xai(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }

  static openai_pkg.OpenAI phind({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return openai_pkg.phind(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }

  static google_pkg.Google google({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return google_pkg.google(
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
    return anthropic_pkg.anthropic(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }
}
