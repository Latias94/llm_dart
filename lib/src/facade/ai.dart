import 'package:llm_dart_anthropic/llm_dart_anthropic.dart' as anthropic_pkg;
import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart' as elevenlabs_pkg;
import 'package:llm_dart_google/llm_dart_google.dart' as google_pkg;
import 'package:llm_dart_ollama/llm_dart_ollama.dart' as ollama_pkg;
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
  return _createOpenAI(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    profile: profile,
  );
}

openai_pkg.OpenAI _createOpenAI({
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
  return _createOpenRouter(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
    appReferer: appReferer,
    appTitle: appTitle,
  );
}

openai_pkg.OpenAI _createOpenRouter({
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
  return _createDeepSeek(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

openai_pkg.OpenAI _createDeepSeek({
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
  return _createGroq(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

openai_pkg.OpenAI _createGroq({
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
  return _createXAI(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

openai_pkg.OpenAI _createXAI({
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
  return _createPhind(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

openai_pkg.OpenAI _createPhind({
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
  return _createGoogle(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

google_pkg.Google _createGoogle({
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
  return _createAnthropic(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

anthropic_pkg.Anthropic _createAnthropic({
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

/// Creates an Ollama provider facade.
///
/// Prefer this short factory in new root-package code. `AI.ollama(...)`
/// remains as an optional grouped-namespace alias.
ollama_pkg.Ollama ollama({
  String? apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return _createOllama(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

ollama_pkg.Ollama _createOllama({
  String? apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return ollama_pkg.ollama(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

/// Creates an ElevenLabs provider facade.
///
/// Prefer this short factory in new root-package code. `AI.elevenLabs(...)`
/// remains as an optional grouped-namespace alias.
elevenlabs_pkg.ElevenLabs elevenLabs({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return _createElevenLabs(
    apiKey: apiKey,
    transport: transport,
    baseUrl: baseUrl,
  );
}

elevenlabs_pkg.ElevenLabs _createElevenLabs({
  required String apiKey,
  TransportClient? transport,
  String? baseUrl,
}) {
  return elevenlabs_pkg.elevenLabs(
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
/// Builder-era root compatibility APIs have been removed from this package.
final class AI {
  const AI._();

  static openai_pkg.OpenAI openai({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
    openai_pkg.OpenAIFamilyProfile? profile,
  }) {
    return _createOpenAI(
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
    return _createOpenRouter(
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
    return _createDeepSeek(
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
    return _createGroq(
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
    return _createXAI(
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
    return _createPhind(
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
    return _createGoogle(
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
    return _createAnthropic(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }

  static ollama_pkg.Ollama ollama({
    String? apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return _createOllama(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }

  static elevenlabs_pkg.ElevenLabs elevenLabs({
    required String apiKey,
    TransportClient? transport,
    String? baseUrl,
  }) {
    return _createElevenLabs(
      apiKey: apiKey,
      transport: transport,
      baseUrl: baseUrl,
    );
  }
}
