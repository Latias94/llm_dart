import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../../core/config.dart';
import 'config/legacy_config_extensions.dart';
import 'http/http_config_utils.dart';

TransportClient createCompatTransport(LLMConfig config) {
  final customTransport = config.legacyTransportClient;
  if (customTransport != null) {
    return customTransport;
  }

  final customDio = config.legacyCustomDio;
  if (customDio != null) {
    return DioTransportClient(dio: customDio);
  }

  final dio = HttpConfigUtils.createConfiguredDio(
    baseUrl: config.baseUrl,
    defaultHeaders: const {},
    config: config,
    defaultTimeout: config.timeout,
  );

  return DioTransportClient(dio: dio);
}
