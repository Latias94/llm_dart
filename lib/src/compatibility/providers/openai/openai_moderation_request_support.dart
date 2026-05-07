part of 'openai_moderation_support.dart';

final class _OpenAIModerationRequestSupport {
  const _OpenAIModerationRequestSupport();

  Map<String, dynamic> buildRequestBody(ModerationRequest request) {
    return <String, dynamic>{
      'input': request.input,
      if (request.model != null) 'model': request.model,
    };
  }
}
