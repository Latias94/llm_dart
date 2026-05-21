import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_moderation_models.dart';

Future<OpenAIModerationResponse> sendOpenAIModerationRequest({
  required TransportClient transport,
  required TransportRequest request,
}) async {
  return sendProviderModelRequest(
    transport: transport,
    request: request,
    decode: (body, _) => decodeOpenAIModerationResponse(body),
  );
}
