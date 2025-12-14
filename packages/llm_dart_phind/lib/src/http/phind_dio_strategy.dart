import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/phind_config.dart';

/// Phind-specific Dio strategy implementation
///
/// Handles Phind's unique requirements:
/// - Empty User-Agent header (required by Phind API)
/// - Specific Accept headers
/// - Identity encoding
class PhindDioStrategy extends BaseProviderDioStrategy<PhindConfig> {
  @override
  String get providerName => 'Phind';

  @override
  Map<String, String> buildHeaders(PhindConfig config) {
    return {
      'Content-Type': 'application/json',
      'User-Agent': '',
      'Accept': '*/*',
      'Accept-Encoding': 'Identity',
    };
  }

  @override
  Duration? getTimeout(PhindConfig config) {
    return config.timeout ?? const Duration(seconds: 60);
  }
}
