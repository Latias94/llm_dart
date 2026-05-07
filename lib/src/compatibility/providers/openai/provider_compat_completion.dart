part of 'provider_compat.dart';

mixin OpenAIProviderCompletionMixin implements CompletionCapability {
  OpenAICompletion get _completion;

  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    return _completion.complete(request);
  }
}
