import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_moderation_models.dart';

Future<OpenAIModerationResponse> sendOpenAIModerationRequest({
  required TransportClient transport,
  required TransportRequest request,
}) async {
  final response = await transport.send(request);
  return decodeOpenAIModerationResponse(response.body);
}
