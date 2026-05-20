import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_embedding_options.dart';

Map<String, Object?> buildOpenAIEmbeddingRequestBody({
  required String modelId,
  required EmbedRequest request,
  required OpenAIEmbedOptions? options,
}) {
  return {
    'model': modelId,
    'input': request.values,
    if (request.dimensions != null) 'dimensions': request.dimensions,
    'encoding_format': options?.encodingFormat ?? 'float',
    if (options?.user case final user?) 'user': user,
  };
}
