import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_language_model_call_routing.dart';
import '../provider/openai_family_route_policy.dart';

final class OpenAILanguageModelPreparedRequest {
  final Object? body;
  final List<ModelWarning> warnings;

  const OpenAILanguageModelPreparedRequest({
    required this.body,
    required this.warnings,
  });
}

abstract interface class OpenAILanguageModelRouteAdapter {
  OpenAIRequestRoute get route;

  Uri resolveUri(String baseUrl);

  OpenAILanguageModelPreparedRequest encodeRequest({
    required ResolvedOpenAILanguageModelCall call,
    required GenerateTextRequest request,
    required bool stream,
  });

  GenerateTextResult decodeGenerateResponse({
    required Object? body,
    required List<ModelWarning> warnings,
  });

  Stream<LanguageModelStreamEvent> decodeStreamEvents({
    required Stream<List<int>> stream,
    required bool includeRawChunks,
    SseJsonChunkParser streamChunkParser = const SseJsonChunkParser(),
  });
}
