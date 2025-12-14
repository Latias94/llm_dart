import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/google_config.dart';

/// Google-specific Dio strategy implementation.
class GoogleDioStrategy extends BaseProviderDioStrategy<GoogleConfig> {
  @override
  String get providerName => 'Google';

  @override
  Map<String, String> buildHeaders(GoogleConfig config) {
    return {
      'Content-Type': 'application/json',
    };
  }
}
