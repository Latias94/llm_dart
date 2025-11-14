import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

/// Google-specific Dio strategy implementation.
class GoogleDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'Google';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    return {
      'Content-Type': 'application/json',
    };
  }
}
