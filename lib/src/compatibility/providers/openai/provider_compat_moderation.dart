part of 'provider_compat.dart';

mixin OpenAIProviderModerationMixin implements ModerationCapability {
  OpenAIModeration get _moderation;

  @override
  Future<ModerationResponse> moderate(ModerationRequest request) async {
    return _moderation.moderate(request);
  }
}
