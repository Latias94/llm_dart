import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../core/base_http_provider.dart';
import '../../core/config.dart';
import '../config/legacy_config_extensions.dart';

TransportClient createCompatTransport(LLMConfig config) {
  final customTransport = config.legacyTransportClient;
  if (customTransport != null) {
    return customTransport;
  }

  final customDio = config.legacyCustomDio;
  if (customDio != null) {
    return DioTransportClient(dio: customDio);
  }

  final dio = BaseHttpProvider.createConfiguredDio(
    baseUrl: config.baseUrl,
    headers: const {},
    config: config,
    timeout: config.timeout,
  );

  return DioTransportClient(dio: dio);
}
