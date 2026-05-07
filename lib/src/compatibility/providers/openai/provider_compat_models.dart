part of 'provider_compat.dart';

mixin OpenAIProviderModelsMixin implements ModelListingCapability {
  OpenAIModels get _models;

  @override
  Future<List<AIModel>> models({TransportCancellation? cancelToken}) async {
    return _models.models(cancelToken: cancelToken);
  }
}
