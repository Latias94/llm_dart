import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_language_model_stream.dart';

Stream<LanguageModelStreamEvent> sendAnthropicLanguageModelStreamCall({
  required TransportClient transport,
  required TransportRequest request,
  required List<ModelWarning> warnings,
  required bool includeRawChunks,
}) async* {
  yield StartEvent(warnings: warnings);

  try {
    final response = await transport.sendStream(request);

    yield* decodeAnthropicLanguageModelStreamEvents(
      stream: response.stream,
      includeRawChunks: includeRawChunks,
    );
  } catch (error) {
    yield ErrorEvent(transportErrorToModelError(error));
  }
}
